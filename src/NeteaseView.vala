/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

public class Noise.Plugins.NeteaseView : Gtk.Grid {

    private Gtk.InfoBar searchBar;
    private NeteaseViewWrapper musicView;
    private Gtk.SearchEntry searchEntry;
    private Gtk.Button searchButton;
    private NeteaseMusicLibrary library;

    public NeteaseView (TreeViewSetup? tvs = null, NeteaseMusicLibrary library, TopDisplay topDisplay) {
        build_async.begin (tvs, library, topDisplay);
    }

    private async void build_async (TreeViewSetup? tvs = null, NeteaseMusicLibrary library, TopDisplay topDisplay) {
        Idle.add (build_async.callback);
        yield;

        this.library = library;

        searchBar = new Gtk.InfoBar();
        searchBar.get_style_context ().add_class (Gtk.STYLE_CLASS_INFO);
        searchBar.set_hexpand (true);

        searchEntry = new Gtk.SearchEntry();
        searchEntry.placeholder_text  = _("搜索网易云音乐");

        searchButton = new Gtk.Button.with_label(_("搜索"));
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        box.pack_start(searchEntry);
        box.pack_start(searchButton);
        (searchBar.get_content_area () as Gtk.Container).add (box);

        musicView = new NeteaseViewWrapper(tvs, library, topDisplay);

        attach (searchBar, 0, 0, 1, 1);
        attach (musicView, 0, 1, 1, 1);
        show_all();

        library.new_media_searched.connect((medias) => {
            musicView.set_media_async.begin(medias);
        });

        searchButton.clicked.connect(() => {
            string word = searchEntry.text;
            if (word == "") {
                library.search_reset();
                musicView.set_media_async.begin(library.get_medias());
                return;
            }
            library.search.begin(word, musicView);
        });
    }
}
