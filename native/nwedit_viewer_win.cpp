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
// UI).
//
// Save bridge: a bare WebView2 does not give the page's Save/Export buttons
// a usable download, so the page (nwedit_template.html,
// nwmovie_template.html) posts a string "<filename>\n<base64>" through
// window.chrome.webview.postMessage; WebMessageReceived below shows a
// Save dialog and writes the file. With a second command-line argument
// (nwmovie's export() option) the file is written to that path without a
// dialog and the viewer closes; a posted "\x01error\n<message>" is written
// to <path>.error instead.

#include <windows.h>
#include <shlwapi.h>
#include <wrl.h>
#include <wil/com.h>
#include "WebView2.h"
#include <commdlg.h>
#include <wincrypt.h>
#include <string>
#include <vector>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "crypt32.lib")

using namespace Microsoft::WRL;

static wil::com_ptr<ICoreWebView2Controller> g_controller;
static wil::com_ptr<ICoreWebView2> g_webview;
static std::wstring g_targetUrl;
static std::wstring g_autoOut;
static HWND g_hwnd = nullptr;

static bool writeBytes(const std::wstring &path, const BYTE *data, DWORD len) {
	HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
		FILE_ATTRIBUTE_NORMAL, nullptr);
	if (h == INVALID_HANDLE_VALUE) return false;
	DWORD written = 0;
	BOOL ok = WriteFile(h, data, len, &written, nullptr);
	CloseHandle(h);
	return ok && written == len;
}

static void writeErrorFile(const std::wstring &msg) {
	int n = WideCharToMultiByte(CP_UTF8, 0, msg.c_str(), (int)msg.size(), nullptr, 0, nullptr, nullptr);
	std::string utf8(n, '\0');
	WideCharToMultiByte(CP_UTF8, 0, msg.c_str(), (int)msg.size(), &utf8[0], n, nullptr, nullptr);
	std::wstring part = g_autoOut + L".error.part";
	if (writeBytes(part, (const BYTE *)utf8.data(), (DWORD)utf8.size()))
		MoveFileExW(part.c_str(), (g_autoOut + L".error").c_str(), MOVEFILE_REPLACE_EXISTING);
}

static bool decodeBase64(const std::wstring &b64, std::vector<BYTE> &out) {
	DWORD len = 0;
	if (!CryptStringToBinaryW(b64.c_str(), (DWORD)b64.size(), CRYPT_STRING_BASE64, nullptr, &len, nullptr, nullptr))
		return false;
	out.resize(len);
	return CryptStringToBinaryW(b64.c_str(), (DWORD)b64.size(), CRYPT_STRING_BASE64, out.data(), &len, nullptr, nullptr) != 0;
}

static void handleSaveMessage(const std::wstring &msg) {
	size_t nl = msg.find(L'\n');
	if (nl == std::wstring::npos) return;
	std::wstring head = msg.substr(0, nl), rest = msg.substr(nl + 1);
	bool isError = (head == std::wstring(1, L'\x01') + L"error");  // not L"\x01error": the hex escape would swallow the "e"
	std::vector<BYTE> data;
	bool decoded = !isError && decodeBase64(rest, data);

	if (!g_autoOut.empty()) {
		if (isError) writeErrorFile(rest);
		else if (!decoded) writeErrorFile(L"no data received from the page");
		else {
			// write then rename, so the waiting Stata command never sees a partial file
			std::wstring part = g_autoOut + L".part";
			if (!writeBytes(part, data.data(), (DWORD)data.size()) ||
				!MoveFileExW(part.c_str(), g_autoOut.c_str(), MOVEFILE_REPLACE_EXISTING))
				writeErrorFile(L"could not write the file");
		}
		PostMessageW(g_hwnd, WM_CLOSE, 0, 0);
		return;
	}
	if (isError || !decoded) return;

	wchar_t path[MAX_PATH * 4] = {};
	wcsncpy_s(path, head.c_str(), _TRUNCATE);
	OPENFILENAMEW ofn = {};
	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = g_hwnd;
	ofn.lpstrFile = path;
	ofn.nMaxFile = ARRAYSIZE(path);
	ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_NOCHANGEDIR;
	if (GetSaveFileNameW(&ofn)) {
		if (!writeBytes(path, data.data(), (DWORD)data.size()))
			MessageBoxW(g_hwnd, L"Could not save the file.", L"nwedit_viewer", MB_OK | MB_ICONERROR);
	}
}

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
		MessageBoxW(nullptr, L"usage: nwedit_viewer.exe <path-to-html-file> [<output-file>]", L"nwedit_viewer", MB_OK);
		return 1;
	}
	if (argc >= 3) g_autoOut = argv[2];
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
	g_hwnd = hwnd;

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

							// Registered before Navigate, so the page can post from
							// its first click (or, unattended, as soon as it is done).
							EventRegistrationToken token;
							g_webview->add_WebMessageReceived(
								Callback<ICoreWebView2WebMessageReceivedEventHandler>(
									[](ICoreWebView2 *, ICoreWebView2WebMessageReceivedEventArgs *args) -> HRESULT {
										wil::unique_cotaskmem_string message;
										if (SUCCEEDED(args->TryGetWebMessageAsString(&message)) && message)
											handleSaveMessage(message.get());
										return S_OK;
									}).Get(), &token);

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
