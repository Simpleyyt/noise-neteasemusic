/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

 public class Noise.Plugins.NeteaseApi: Object {

    public signal void new_playlist_added(StaticPlaylist p);
    private NeteaseCoreApi api;
    public signal void new_media_searched(Media media);

    public NeteaseApi() {
        api = new NeteaseCoreApi();
    }

    private void parseArtists(ref Media media, ref Json.Reader reader) {
        var count = reader.count_elements();
        for (int i = 0; i < count; i++) {
            reader.read_element(i);

            reader.read_member("name");
            if (media.artist != "") {
                media.artist += ",";
            }
            media.artist += String.locale_to_utf8(reader.get_string_value());
            reader.end_member();    // name

            reader.end_element();   //i
        }
    }

    private void parseAlbum(ref Media media, ref Json.Reader reader) {
        reader.read_member("name");
        media.album = String.locale_to_utf8(reader.get_string_value());
        reader.end_member();    //name

        reader.read_member("picUrl");
        var uri = reader.get_string_value();
        //get_cover(media, uri);
        reader.end_member();    //picUrl
    }

    private void get_cover(Media media, string uri) {
        debug("Album pic: %s".printf(uri));
        PixbufUtils.get_pixbuf_from_file_async.begin(File.new_for_uri(uri), null, (obj, res) => {
            var cover = PixbufUtils.get_pixbuf_from_file_async.end(res);
            CoverartCache.instance.cache_image_async(media, cover);
        });

    }

    private Json.Reader get_json_reader(string dump) throws Error {
        var parser = new Json.Parser();
        parser.load_from_data(dump);
        var node = parser.get_root();
        var reader = new Json.Reader(node);

        reader.read_member("code");
        int code = (int)reader.get_int_value();
        debug("Response code: %d".printf(code));
        reader.end_member();    // code

        if (code != 200) {
            debug(dump);
            reader.read_member("message");
            var message = reader.get_string_value();
            debug("Error message: %s".printf(message));
            throw new NeteaseError.HTTP(message);
            reader.end_member();
        }

        return reader;
    }

    public async StaticPlaylist playlist_detail(int playlist_id) throws Error {
        var playlist = new StaticPlaylist();
        var result = yield api.playlist_detail(playlist_id);
        var reader = get_json_reader(result);

        reader.read_member("result");

        reader.read_member("name");
        var name = reader.get_string_value();
        playlist.name = String.locale_to_utf8(name);
        reader.end_member();    // name

        reader.read_member("id");
        var id = reader.get_int_value();
        playlist.rowid = (int)id;
        reader.end_member();    // id

        playlist.allow_duplicate = true;

        debug("Playlist name: %s".printf(name));

        reader.read_member("tracks");
        var count = reader.count_elements();
        debug("Medias count: %d".printf(count));

        for (int i = 0; i < count; i++) {
            reader.read_element(i);
            var media = parseSong(ref reader);
            CoverartCache.instance.get_original_cover(media);
            playlist.medias.add(media);
            reader.end_element();   //i
        }

        reader.end_member();    //tracks
        reader.end_member();    //result

        new_playlist_added(playlist);
        return playlist;
    }

    public async Gee.LinkedList<StaticPlaylist> user_playlist(int uid, int offset = 0, int limit = 100) throws Error {
        var result = yield api.user_playlist(uid, offset, limit);
        var reader = get_json_reader(result);
        var playlists = new Gee.LinkedList<StaticPlaylist>();

        // Parse result
        reader.read_member("playlist");
        var count = reader.count_elements();
        for (int i = 0; i < count; i++) {
            reader.read_element(i);

            reader.read_member("id");
            playlists.add(yield playlist_detail((int)reader.get_int_value()));
            reader.end_member();    // id

            reader.end_element();   // i
        }

        reader.end_member(); //playlist

        return playlists;
    }

    public async int login(string username, string password) throws Error {
        var password_md5 = Checksum.compute_for_string (ChecksumType.MD5, password);
        var result = yield api.login(username, password_md5);
        var reader = get_json_reader(result);

        // Parse result
        reader.read_member("account");
        reader.read_member("id");

        return (int)reader.get_int_value();
    }

    private Media parseSong(ref Json.Reader reader) {
        reader.read_member("mp3Url");
        var uri = reader.get_string_value();
        Media media = new Media(uri);
        media.isTemporary = true;
        reader.end_member();    // mp3Url

        reader.read_member("name");
        media.title = reader.get_string_value();
        reader.end_member();    // name

        reader.read_member("duration");
        media.length = (int)reader.get_int_value();
        reader.end_member();    // duration

        reader.read_member("id");
        media.rowid = (int)reader.get_int_value();
        reader.end_member();    // id

        reader.read_member("artists");
        parseArtists(ref media, ref reader);
        reader.end_member();    // aritsts

        reader.read_member("album");
        parseAlbum(ref media, ref reader);
        reader.end_member(); //album

        return media;
    }

    public async Media getSongDetail(int id) throws Error {
        // Get song detail
        string result = yield api.getSongDetail(id);
        var reader = get_json_reader(result);

        // Parse result
        reader.read_member("songs");
        reader.read_element(0);

        var media = parseSong(ref reader);

        reader.end_element(); // all

        return media;
    }

    public async Gee.LinkedList<Noise.Media> search(string s, int type = 1, int offset = 0, string total = "true", int limit = 20) throws Error {
        // Get search result
        string result = yield api.  search(s, type, offset, total, limit);
        Gee.LinkedList<Noise.Media> medias = new Gee.LinkedList<Noise.Media>();
        var reader = get_json_reader(result);

        // Parse the result
        reader.read_member("result");
        reader.read_member("songs");
        var count = reader.count_elements();

        for (int i = 0; i < count; i++) {
            reader.read_element(i);

            reader.read_member("id");
            var m = yield getSongDetail((int)reader.get_int_value());
            new_media_searched(m);
            medias.add(m);
            reader.end_member();    // id

            reader.end_element();
        }
        return medias;
    }
 }
