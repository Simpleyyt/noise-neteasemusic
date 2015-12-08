/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */


public class Noise.Plugins.NeteaseMusicLibrary: Noise.Library {

    Gee.LinkedList<Noise.Media> medias;
    Gee.LinkedList<Noise.Media> searched_medias;
    Gee.LinkedList<Noise.StaticPlaylist> playlists;
    bool operation_cancelled = false;
    bool is_doing_file_operations = false;
    public int medias_rowid = 0;
    public int playlists_rowid = 0;
    public int smartplaylists_rowid = 0;
    private Cancellable cancellable;
    private NeteaseApi netease;

    public signal void new_media_searched(Gee.LinkedList<Noise.Media> medias);

    public NeteaseMusicLibrary (NeteaseApi netease) {
        this.netease = netease;
        medias = new Gee.LinkedList<Noise.Media> ();
        searched_medias = new Gee.LinkedList<Noise.Media> ();
        playlists = new Gee.LinkedList<Noise.StaticPlaylist> ();
        connectSignal();
    }

    private void connectSignal() {
        netease.new_media_searched.connect((media) => {
            medias.add(media);
            search_medias("");
            new_media_searched(medias);
        });

        netease.new_playlist_added.connect((p) => {
            playlists.add(p);
            debug("New playlist name: %s".printf(p.name));
            playlist_added(p);
        });
    }

    public async void fetch_playlists(int id) {
        playlists.clear();
        yield netease.user_playlist(id);
    }

    public override void initialize_library () {
    }

    public override void add_files_to_library (Gee.Collection<string> files) {
        //do nothing
    }

    public override Gee.Collection<Media> get_medias () {
        message ("Getting medias");
        return medias;
    }
    public override Gee.Collection<StaticPlaylist> get_playlists () {
        message ("Getting playlists");
        return playlists;
    }
    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        return new Gee.LinkedList<SmartPlaylist> ();
    }

    public void search_reset() {
        medias.clear();
        search_medias("");
    }

    public async Gee.LinkedList<Noise.Media> search(string word, NeteaseViewWrapper wrapper) {

        return yield netease.search(word);
    }
    public override void search_medias (string search) {
        message ("Searching medias");
        lock (searched_medias) {
            searched_medias.clear ();
            if (search == "" || search == null) {
                searched_medias.add_all (medias);
                search_finished ();
                return;
            }

            int parsed_rating;
            string parsed_search_string;
            String.base_search_method (search, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;

            lock (medias) {
                foreach (var m in medias) {
                    if (rating_search) {
                        if (m.rating == (uint) parsed_rating)
                            searched_medias.add (m);
                    } else if (Search.match_string_to_media (m, parsed_search_string)) {
                        searched_medias.add (m);
                    }
                }
            }
        }
    }

    public override Gee.Collection<Media> get_search_result () {
        message("Getting search result");
        return searched_medias;
    }

    public override void add_media (Media m) {
    }

    public override void add_medias (Gee.Collection<Media> list) {
        message("add medias");
    }


    public override Media? media_from_id (int id) {
        lock (medias) {
            foreach (var m in medias) {
                if (m.rowid == id) {
                    return m;
                }
            }
        }
        return null;
    }
    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int> ids) {
        var media_collection = new Gee.LinkedList<Media> ();

        lock (medias) {
            foreach (var m in medias) {
                if (ids.contains (m.rowid))
                    media_collection.add (m);
                if (media_collection.size == ids.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Gee.Collection<Media> medias_from_uris (Gee.Collection<string> uris) {
        var media_collection = new Gee.LinkedList<Media> ();

        lock (medias) {
            foreach (var m in medias) {
                if (uris.contains (m.uri))
                    media_collection.add (m);
                if (media_collection.size == uris.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Media? find_media (Media to_find) {
        Media? found = null;
        lock (medias) {
            foreach (var m in medias) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    found = m;
                    break;
                }
            }
        }
        return found;
    }
    public override Media? media_from_file (File file) {
        lock (medias) {
            foreach (var m in medias) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }
    public override Media? media_from_uri (string uri) {
        lock (medias) {
            foreach (var m in medias) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }
    public override void update_media (Media s, bool updateMeta, bool record_time) {

    }
    public override void update_medias (Gee.Collection<Media> updates, bool updateMeta, bool record_time) {

    }
    public override void remove_media (Media m, bool trash) {
    }
    public override void remove_medias (Gee.Collection<Media> list, bool trash) {
    }

    public override bool support_smart_playlists () {
        return false;
    }

    public override void add_smart_playlist (SmartPlaylist p) {

    }
    public override void remove_smart_playlist (int id) {

    }
    public override SmartPlaylist? smart_playlist_from_id (int id) {
        return null;
    }
    public override SmartPlaylist? smart_playlist_from_name (string name) {
        return null;
    }

    public override bool support_playlists () {
        return true;
    }

    public override void add_playlist (StaticPlaylist p) {
        //TODO: to finish
    }

    public override void remove_playlist (int id) {
        //TODO: to finish
    }

    public override StaticPlaylist? playlist_from_id (int id) {
        foreach (var playlist in get_playlists ()) {
            if (playlist.rowid == id) {
                return playlist;
            }
        }
        return null;
    }
    public override StaticPlaylist? playlist_from_name (string name) {
        foreach (var playlist in get_playlists ()) {
            if (playlist.name == name) {
                return playlist;
            }
        }
        return null;
    }

    public override bool start_file_operations (string? message) {
        if (doing_file_operations ()) {

            return true;
        } else
            return false;
    }
    public override bool doing_file_operations () {
        return is_doing_file_operations;
    }
    public override void finish_file_operations () {
        is_doing_file_operations = false;
    }

}
