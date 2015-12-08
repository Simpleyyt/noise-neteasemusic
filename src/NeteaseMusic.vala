/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

namespace Noise.Plugins {

    public class NeteaseMusicPlugin : Peas.ExtensionBase, Peas.Activatable {
        public GLib.Object object { owned get; construct; }

        private Interface plugins;
        private Noise.PreferencesWindow? preferences_window;
        private Netease.PreferencesSection prefs_section;
        private NeteaseMusicLibrary library;
        private NeteaseMusic.Settings settings;
        private SourceListExpandableItem entry;
        private NeteaseApi netease;

        public void activate () {
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();
            settings = new NeteaseMusic.Settings();
            netease = new NeteaseApi();
            library = new NeteaseMusicLibrary(netease);

            plugins.register_function(Interface.Hook.WINDOW, () => {
                message ("Activating Netease Music plugin");
                libraries_manager.add_library(library);
                var music_tvs = new TreeViewSetup (ListColumn.ARTIST,
                                                   Gtk.SortType.ASCENDING,
                                                   ViewWrapper.Hint.MUSIC);
                var music_view_wrapper = new NeteaseView (music_tvs, library, App.main_window.topDisplay);
                int view_number = App.main_window.view_container.add_view (music_view_wrapper);
                entry = (SourceListExpandableItem)App.main_window.source_list_view.add_item(view_number, _("网易云音乐"), ViewWrapper.Hint.DEVICE, Icons.NOISE.gicon);

                library.playlist_added.connect((p) => {
                    var subview = new PlaylistViewWrapper (p.rowid, ViewWrapper.Hint.PLAYLIST, null, library);
                    var subview_number = App.main_window.view_container.add_view (subview);
                    var subentry = App.main_window.source_list_view.add_item(subview_number, p.name, ViewWrapper.Hint.PLAYLIST, p.icon, null, entry);

                    App.main_window.show_playlist_view(p);
                });
                if (settings.remeber_me) {
                    netease.login.begin(settings.username, settings.password, (obj, res) => {
                        try {
                            var id = netease.login.end(res);
                            clear_playlists();
                            library.fetch_playlists(id);
                        } catch (Error e) {
                            debug(e.message);
                        }
                    });
                }
            });


            plugins.register_function_arg(Interface.Hook.SETTINGS_WINDOW, (window) => {
                preferences_window = window as Noise.PreferencesWindow;
                prefs_section = new Netease.PreferencesSection(settings, netease);
                App.main_window.add_preference_page(prefs_section.page);
                prefs_section.logined.connect((id) => {
                    clear_playlists();
                    library.fetch_playlists(id);
                });
            });
        }

        public void clear_playlists() {
            foreach (var playlist in entry.children) {
                if (playlist is SourceListItem) {
                    entry.remove (playlist);
                }
            }
        }

        public void deactivate () {
            message ("Deactivating Netease Music plugin");
        }

        public void update_state () {
            // do nothing
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Noise.Plugins.NeteaseMusicPlugin));
}
