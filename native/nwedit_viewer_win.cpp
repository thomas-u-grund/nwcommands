// nwedit_viewer (Windows): a minimal, chromeless native window hosting
// WebView2 (the Edge/Chromium engine already installed as part of Windows
// 10/11), pointed at a local HTML file given as argv[1]. Same role as
// nwedit_viewer.mm on macOS -- see that file's own header comment for the
// full rationale (no third-party dependency beyond what CI needs to fetch
// the WebView2 SDK headers themselves, which is unavoidable regardless of
// implementation approach since it's Microsoft's own API surface).
//
// WebView2's environment/controller creation is asynchronous (COM
// completion-handler callbacks), so this is necessarily more involved than
// the macOS version's synchronous WKWebView construction -- this follows
// the standard WebView2 "Get Started" sample structure, trimmed to exactly
// what nwedit_viewer needs (one fixed-size window, one URL, no navigation
// UI, no scripting bridge).

#include <windows.h>
#include <shlwapi.h>
#include <wrl.h>
#include <wil/com.h>
#include "WebView2.h"
#include <string>

#pragma comment(lib, "shlwapi.lib")

using namespace Microsoft::WRL;

static wil::com_ptr<ICoreWebView2Controller> g_controller;
static wil::com_ptr<ICoreWebView2> g_webview;
static std::wstring g_targetUrl;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	switch (msg) {
	case WM_SIZE:
		if (g_controller) {
			RECT bounds;
			GetClientRect(hwnd, &bounds);
			g_controller->put_Bounds(bounds);
		}
		return 0;
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	}
	return DefWindowProc(hwnd, msg, wParam, lParam);
}

int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR lpCmdLine, int nCmdShow) {
	// argv[1] (the HTML file path) arrives via the normal command line, not
	// lpCmdLine's own quoting quirks -- use CommandLineToArgvW for a clean parse.
	int argc = 0;
	LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	if (argc < 2) {
		MessageBoxW(nullptr, L"usage: nwedit_viewer.exe <path-to-html-file>", L"nwedit_viewer", MB_OK);
		return 1;
	}
	// file:// URL, not a bare path -- WebView2's Navigate() expects a URL.
	wchar_t urlBuf[MAX_PATH * 2];
	DWORD urlLen = ARRAYSIZE(urlBuf);
	UrlCreateFromPathW(argv[1], urlBuf, &urlLen, 0);
	g_targetUrl = urlBuf;

	const wchar_t CLASS_NAME[] = L"NweditViewerWindow";
	WNDCLASS wc = {};
	wc.lpfnWndProc = WndProc;
	wc.hInstance = hInstance;
	wc.lpszClassName = CLASS_NAME;
	RegisterClass(&wc);

	HWND hwnd = CreateWindowExW(
		0, CLASS_NAME, L"nwplot interactive", WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, CW_USEDEFAULT, 1280, 860,
		nullptr, nullptr, hInstance, nullptr);
	if (!hwnd) return 1;

	ShowWindow(hwnd, nCmdShow);
	UpdateWindow(hwnd);

	// CreateCoreWebView2EnvironmentWithOptions -> environment completion
	// handler -> CreateCoreWebView2Controller -> controller completion
	// handler -> navigate. Both completion handlers are small inline
	// lambdas via Callback<>, the standard WebView2 sample pattern.
	CreateCoreWebView2EnvironmentWithOptions(nullptr, nullptr, nullptr,
		Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
			[hwnd](HRESULT result, ICoreWebView2Environment *env) -> HRESULT {
				if (FAILED(result) || !env) {
					MessageBoxW(hwnd, L"Failed to create WebView2 environment.", L"nwedit_viewer", MB_OK);
					PostQuitMessage(1);
					return result;
				}
				env->CreateCoreWebView2Controller(hwnd,
					Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
						[hwnd](HRESULT result, ICoreWebView2Controller *controller) -> HRESULT {
							if (FAILED(result) || !controller) {
								MessageBoxW(hwnd, L"Failed to create WebView2 controller.", L"nwedit_viewer", MB_OK);
								PostQuitMessage(1);
								return result;
							}
							g_controller = controller;
							g_controller->get_CoreWebView2(&g_webview);

							RECT bounds;
							GetClientRect(hwnd, &bounds);
							g_controller->put_Bounds(bounds);

							g_webview->Navigate(g_targetUrl.c_str());
							return S_OK;
						}).Get());
				return S_OK;
			}).Get());

	MSG msg;
	while (GetMessage(&msg, nullptr, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return 0;
}
