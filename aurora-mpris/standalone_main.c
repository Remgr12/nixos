#include <adwaita.h>
#include <gtk4-layer-shell/gtk4-layer-shell.h>
#include <gtk/gtk.h>

/* Defined in mpris_player/src/main.c, compiled alongside this file */
GtkWidget *create_widget(const char *config_string);

static GtkWindow *g_win = NULL;

static GdkMonitor *find_monitor(const char *connector)
{
    GdkDisplay  *display  = gdk_display_get_default();
    GListModel  *monitors = gdk_display_get_monitors(display);
    guint        n        = g_list_model_get_n_items(monitors);

    for (guint i = 0; i < n; i++) {
        GdkMonitor *mon = GDK_MONITOR(g_list_model_get_item(monitors, i));
        if (g_strcmp0(gdk_monitor_get_connector(mon), connector) == 0)
            return mon; /* caller owns the ref */
        g_object_unref(mon);
    }
    return NULL;
}

static gboolean on_key_pressed(GtkEventControllerKey *ctrl, guint keyval,
                                guint keycode, GdkModifierType state,
                                gpointer data)
{
    (void)ctrl; (void)keycode; (void)state;
    if (keyval == GDK_KEY_Escape) {
        gtk_widget_set_visible(GTK_WIDGET(data), FALSE);
        return TRUE;
    }
    return FALSE;
}

static void on_activate(GtkApplication *app, gpointer data)
{
    (void)data;

    if (g_win) {
        if (gtk_widget_get_visible(GTK_WIDGET(g_win)))
            gtk_widget_set_visible(GTK_WIDGET(g_win), FALSE);
        else
            gtk_window_present(g_win);
        return;
    }

    g_win = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(app)));

    gtk_layer_init_for_window(g_win);
    gtk_layer_set_layer(g_win, GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(g_win, GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
    gtk_layer_set_margin(g_win, GTK_LAYER_SHELL_EDGE_LEFT, 5);
    gtk_layer_set_keyboard_mode(g_win, GTK_LAYER_SHELL_KEYBOARD_MODE_ON_DEMAND);
    /* No exclusive zone: float as an overlay *over* other windows instead of
     * reserving a strip that pushes tiled windows aside. */
    gtk_window_set_resizable(g_win, FALSE);
    gtk_window_set_decorated(g_win, FALSE);

    /* Opaque backdrop with rounded corners + border so the player stands out
     * instead of blending into whatever window sits behind it. */
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css,
        "window.aurora-mpris {"
        "  background-color: rgba(36, 40, 48, 0.98);"
        "  border-radius: 14px;"
        "  border: 1px solid rgba(76, 86, 106, 0.9);"
        "}");
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(), GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(css);
    gtk_widget_add_css_class(GTK_WIDGET(g_win), "aurora-mpris");

    /* Pin to the internal display */
    GdkMonitor *mon = find_monitor("eDP-1");
    if (mon) {
        gtk_layer_set_monitor(g_win, mon);
        g_object_unref(mon);
    }

    GtkEventController *key = gtk_event_controller_key_new();
    g_signal_connect(key, "key-pressed", G_CALLBACK(on_key_pressed), g_win);
    gtk_widget_add_controller(GTK_WIDGET(g_win), key);

    GtkWidget *widget = create_widget("{\"size\":{\"width\":275,\"height\":450}}");
    gtk_window_set_child(g_win, widget);
    gtk_window_present(g_win);
}

int main(int argc, char *argv[])
{
    AdwApplication *app = adw_application_new(
        "com.meismeric.aurora.MprisPlayerStandalone",
        G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(on_activate), NULL);
    int ret = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return ret;
}
