// nwedit_viewer (Linux): a minimal, chromeless native window hosting
// WebKitGTK (the same engine GNOME's own apps use), pointed at a local
// HTML file given as argv[1]. Same role as nwedit_viewer.mm on macOS -- see
// that file's own header comment for the full rationale.

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr, "usage: nwedit_viewer <path-to-html-file>\n");
		return 1;
	}

	gtk_init(&argc, &argv);

	GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_title(GTK_WINDOW(window), "nwplot interactive");
	gtk_window_set_default_size(GTK_WINDOW(window), 1280, 860);
	g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

	GtkWidget *webview = webkit_web_view_new();
	gtk_container_add(GTK_CONTAINER(window), webview);

	// realpath() so a relative path passed by nwplot.ado resolves the same
	// way regardless of the caller's own cwd, then a file:// URI from it.
	char resolved[PATH_MAX];
	if (realpath(argv[1], resolved) == NULL) {
		fprintf(stderr, "nwedit_viewer: could not resolve path %s\n", argv[1]);
		return 1;
	}
	gchar *uri = g_strdup_printf("file://%s", resolved);
	webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), uri);
	g_free(uri);

	gtk_widget_show_all(window);
	gtk_main();

	return 0;
}
