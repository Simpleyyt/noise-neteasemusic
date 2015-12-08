/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

public class Noise.Plugins.NeteaseViewWrapper : ViewWrapper {

    public NeteaseViewWrapper (TreeViewSetup? tvs = null, Library library, TopDisplay topDisplay) {
        base (Hint.MUSIC, library);
        build_async.begin (tvs, topDisplay);
    }

    private Gee.HashMap<unowned Device, int> _devices;

    private async void build_async (TreeViewSetup? tvs = null, TopDisplay topDisplay) {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;
        // Add grid view
        grid_view = new GridView (this);

        // Add list view and column browser
        TreeViewSetup music_setup;
        if (tvs == null)
            music_setup = new TreeViewSetup (ListColumn.ARTIST,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.MUSIC);
        else
            music_setup = tvs;
        list_view = new ListView (this, music_setup, true);
        topDisplay.set_list_view(list_view.list_view);

        // Welcome screen
        welcome_screen = new Granite.Widgets.Welcome (_("网易云音乐"),
            _("从网易云音乐库搜索音乐。"/*" with one of the methods below."*/));
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Drag n drop in welcome widget
        Gtk.TargetEntry uris = {"text/uri-list", 0, 0};

        // Refresh view layout
        pack_views ();

        yield set_media_async (library.get_medias ());
    }
}
