#include <webkit/webkit.h>

/*
 * Thin helpers over GTK 4 and WebKitGTK 6. Swift imports most GTK object
 * types as opaque pointers and can't see macros (GTK_WINDOW(), the
 * g_signal_connect() and g_object_new() varargs, some GLib enum values), so
 * the Swift side deals only in untyped object pointers and these do the rest.
 */

typedef void *portal_object;

static inline portal_object portal_app_new(const char *id) {
    return gtk_application_new(id, G_APPLICATION_NON_UNIQUE);
}

/* No arguments: GTK must not try to interpret the URL. */
static inline int portal_app_run(portal_object app) {
    return g_application_run(G_APPLICATION(app), 0, NULL);
}

static inline void portal_unref(portal_object object) {
    g_object_unref(object);
}

static inline void portal_connect(portal_object instance, const char *signal,
                                  GCallback handler, void *data) {
    g_signal_connect(instance, signal, handler, data);
}

static inline portal_object portal_window_new(portal_object app) {
    GtkWidget *window = gtk_application_window_new(GTK_APPLICATION(app));
    gtk_window_set_default_size(GTK_WINDOW(window), 1000, 750);
    return window;
}

static inline void portal_window_set_title(portal_object window, const char *title) {
    gtk_window_set_title(GTK_WINDOW(window), title);
}

static inline void portal_window_show(portal_object window, portal_object child) {
    gtk_window_set_child(GTK_WINDOW(window), GTK_WIDGET(child));
    gtk_window_present(GTK_WINDOW(window));
}

static inline portal_object portal_box_new(void) {
    return gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
}

static inline void portal_box_append(portal_object box, portal_object child) {
    gtk_box_append(GTK_BOX(box), GTK_WIDGET(child));
}

static inline portal_object portal_entry_new(void) {
    return gtk_entry_new();
}

static inline const char *portal_entry_text(portal_object entry) {
    return gtk_editable_get_text(GTK_EDITABLE(entry));
}

static inline void portal_entry_set_text(portal_object entry, const char *text) {
    gtk_editable_set_text(GTK_EDITABLE(entry), text);
}

/*
 * A web view on an ephemeral network session (nothing kept on disk) that
 * sends everything through 'proxy_uri'. GLib's SOCKS5 client passes host
 * names to the proxy, so name lookups happen there as well.
 */
static inline portal_object portal_web_view_new(const char *proxy_uri) {
    WebKitNetworkSession *session = webkit_network_session_new_ephemeral();
    WebKitNetworkProxySettings *proxy = webkit_network_proxy_settings_new(proxy_uri, NULL);
    webkit_network_session_set_proxy_settings(session, WEBKIT_NETWORK_PROXY_MODE_CUSTOM, proxy);
    webkit_network_proxy_settings_free(proxy);
    GtkWidget *view = GTK_WIDGET(g_object_new(WEBKIT_TYPE_WEB_VIEW, "network-session", session, NULL));
    g_object_unref(session);
    gtk_widget_set_vexpand(view, TRUE);
    return view;
}

static inline void portal_web_view_load(portal_object view, const char *uri) {
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(view), uri);
}

static inline const char *portal_web_view_uri(portal_object view) {
    return webkit_web_view_get_uri(WEBKIT_WEB_VIEW(view));
}

static inline const char *portal_web_view_title(portal_object view) {
    return webkit_web_view_get_title(WEBKIT_WEB_VIEW(view));
}
