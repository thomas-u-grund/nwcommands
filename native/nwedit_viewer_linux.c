// nwedit_viewer (Linux): a minimal, chromeless native window hosting
// WebKitGTK (the same engine GNOME's own apps use), pointed at a local
// HTML file given as argv[1]. Same role as nwedit_viewer.mm on macOS -- see
// that file's own header comment for the full rationale.
//
// Save bridge: a bare WebKitWebView ignores a blob + <a download> click, so
// the page's Save/Export buttons (nwedit_template.html, nwmovie_template.html)
// post {filename, dataBase64} to the "nwedit" script message handler
// registered here (window.webkit.messageHandlers.nwedit, the same name and
// payload as the macOS viewer), and this program shows a GTK Save dialog
// and writes the file.
//
// Unattended export: with a second argument (nwmovie's export() option) the
// handler writes the posted file to that path without a dialog and quits;
// a posted {error} is written to <path>.error instead.

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

static const char *g_auto_out = NULL;

static gchar *get_string_prop(JSCValue *obj, const char *name) {
	if (!jsc_value_object_has_property(obj, name)) return NULL;
	JSCValue *v = jsc_value_object_get_property(obj, name);
	gchar *s = NULL;
	if (jsc_value_is_string(v)) s = jsc_value_to_string(v);
	g_object_unref(v);
	return s;
}

static void write_error_file(const char *msg) {
	gchar *errpath = g_strconcat(g_auto_out, ".error", NULL);
	g_file_set_contents(errpath, msg, -1, NULL);
	g_free(errpath);
}

static void on_save_message(WebKitUserContentManager *manager,
                            WebKitJavascriptResult *result,
                            gpointer user_data) {
	GtkWindow *parent = GTK_WINDOW(user_data);
	JSCValue *body = webkit_javascript_result_get_js_value(result);
	if (!jsc_value_is_object(body)) return;

	gchar *err = get_string_prop(body, "error");
	gchar *filename = get_string_prop(body, "filename");
	gchar *b64 = get_string_prop(body, "dataBase64");

	gsize len = 0;
	guchar *data = NULL;
	if (b64) data = g_base64_decode(b64, &len);

	if (g_auto_out) {
		if (err) write_error_file(err);
		else if (data) {
			GError *gerr = NULL;
			if (!g_file_set_contents(g_auto_out, (const gchar *)data, (gssize)len, &gerr)) {
				write_error_file(gerr ? gerr->message : "could not write the file");
				if (gerr) g_error_free(gerr);
			}
		}
		else write_error_file("no data received from the page");
		g_free(err); g_free(filename); g_free(b64); g_free(data);
		gtk_main_quit();
		return;
	}

	if (data && filename) {
		GtkWidget *dialog = gtk_file_chooser_dialog_new("Save file", parent,
			GTK_FILE_CHOOSER_ACTION_SAVE,
			"_Cancel", GTK_RESPONSE_CANCEL,
			"_Save", GTK_RESPONSE_ACCEPT,
			NULL);
		GtkFileChooser *chooser = GTK_FILE_CHOOSER(dialog);
		gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
		gtk_file_chooser_set_current_name(chooser, filename);
		if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
			char *path = gtk_file_chooser_get_filename(chooser);
			GError *gerr = NULL;
			if (!g_file_set_contents(path, (const gchar *)data, (gssize)len, &gerr)) {
				GtkWidget *msg = gtk_message_dialog_new(parent, GTK_DIALOG_MODAL,
					GTK_MESSAGE_ERROR, GTK_BUTTONS_OK, "Could not save file: %s",
					gerr ? gerr->message : "unknown error");
				gtk_dialog_run(GTK_DIALOG(msg));
				gtk_widget_destroy(msg);
				if (gerr) g_error_free(gerr);
			}
			g_free(path);
		}
		gtk_widget_destroy(dialog);
	}
	g_free(err); g_free(filename); g_free(b64); g_free(data);
}

int main(int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr, "usage: nwedit_viewer <path-to-html-file> [<output-file>]\n");
		return 1;
	}
	if (argc >= 3) g_auto_out = argv[2];

	gtk_init(&argc, &argv);

	GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_title(GTK_WINDOW(window), "nwplot interactive");
	gtk_window_set_default_size(GTK_WINDOW(window), 1280, 860);
	g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

	// Registered before the page loads, so window.webkit.messageHandlers.nwedit
	// exists when the page's own feature-detect runs.
	WebKitUserContentManager *ucm = webkit_user_content_manager_new();
	g_signal_connect(ucm, "script-message-received::nwedit",
		G_CALLBACK(on_save_message), window);
	webkit_user_content_manager_register_script_message_handler(ucm, "nwedit");

	GtkWidget *webview = webkit_web_view_new_with_user_content_manager(ucm);
	gtk_container_add(GTK_CONTAINER(window), webview);

	// realpath() so a relative path passed by nwplot.ado resolves the same
	// way regardless of the caller's own cwd, then a file:// URI from it.
	char resolved[PATH_MAX];
	if (realpath(argv[1], resolved) == NULL) {
		fprintf(stderr, "nwedit_viewer: could not resolve path %s\n", argv[1]);
		return 1;
	}
	gchar *uri = g_filename_to_uri(resolved, NULL, NULL);
	webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), uri);
	g_free(uri);

	// Unattended export: keep the window on top; a covered window gets no
	// animation frames, which can stall the export.
	if (g_auto_out) {
		gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
		gtk_window_set_title(GTK_WINDOW(window), "nwmovie: exporting");
	}
	gtk_widget_show_all(window);
	gtk_main();

	return 0;
}
