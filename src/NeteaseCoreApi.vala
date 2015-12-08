/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

 errordomain NeteaseError {
     HTTP
 }

public class Noise.Plugins.NeteaseCoreApi: Object {


    private SList<Soup.Cookie> cookies;
    private Soup.SessionAsync session;
    private static string modulus = "00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7";
    private static string nonce = "0CoJUm6Qyw8W8jud";
    private static string pubKey = "010001";

    public NeteaseCoreApi() {
        session = new Soup.SessionAsync ();
        session.timeout = 10;
        cookies = new SList<Soup.Cookie> ();
        cookies.append(new Soup.Cookie("music.163.com", "appver", "1.5.2", "/", -1));

    }

    private string array2str(uint8[] array) {
        string result = "";
        for (int i = 0; i < array.length; i++) {
            result += "%c".printf(array[i]);
        }
        return result;
    }

    private string str_hex(string text) {
        string result = "";
        for (int i = 0; i < text.length; i++) {
            result += "%02x".printf(text.data[i]);
        }
        return result;
    }

    private string rsaEncrypt(string text, string pubKey, string modulus) {
        var b = new Gmp.Mpz();
        b.set_str(str_hex(text.reverse()), 16);
        var e = new Gmp.Mpz();
        e.set_str(pubKey, 16);
        var m = new Gmp.Mpz();
        m.set_str(modulus, 16);
        var result = new Gmp.Mpz();
        result.powm(b, e, m);
        char[] buf = {};
        buf.resize(result.sizeinbase(16));
        var str = (string)result.get_str(buf, 16);
        while (str.length < 256) {
            str = "0" + str;
        }
        return str;
    }

    private string aesEncrypt(string text, string secKey) {
        char pad = 16 - text.length % 16;
        var data = text + string.nfill(pad, pad);
        uint8[] iv = "0102030405060708".data;
        var encrypt_part = data.length / Nettle.AES_BLOCK_SIZE;
		encrypt_part *= Nettle.AES_BLOCK_SIZE;

        var aes = Nettle.AES();
		aes.set_encrypt_key(secKey.length, secKey);
		uint8[] cbc = {};
		cbc.resize(data.length);

		Nettle.cbc_encrypt(&aes, aes.encrypt, Nettle.AES_BLOCK_SIZE, iv, encrypt_part, cbc, data.data);
		uint8[] result = {};
		result.resize((int)(Nettle.BASE64_ENCODE_LENGTH(cbc.length) + Nettle.BASE64_ENCODE_FINAL_LENGTH + 1));
		var base64 = new Nettle.Base64();
		var s = base64.encode_update(result, cbc.length, cbc);
		base64.encode_final(&result[s]);
		return array2str(result);
    }

    private string createSecretKey(int size) {
        string key = "";

        for (int i = 0; i < size / 2; i++) {
            key += Random.int_range(0, 0xff).to_string("%02x");
        }
        return key;
    }

    private async string httpRequest(string uri, string action) throws Error {
        lock (session) {

            Soup.Message message = new Soup.Message (action, uri);

            Soup.MessageHeaders headers = message.request_headers;
            headers.append("Host", "music.163.com");
            headers.append("Connection", "keep-alive");
            headers.append("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
            headers.append("Referer", "http://music.163.com/search/");
            headers.append("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36");

            Soup.cookies_to_request (cookies, message);
            session.queue_message(message, (session, message) => {
                httpRequest.callback();
            });
            yield;
            if (message.status_code != 200) {
                throw new NeteaseError.HTTP("请求错误");
            }
            cookies = Soup.cookies_from_response (message);
            debug("http status code: %u".printf(message.status_code));
            return (string)message.response_body.data;
        }
    }

    private string encrypted_login(string username, string password) throws Error {
        string text = "{\"username\": \"%s\", \"password\": \"%s\", \"rememberLogin\": \"true\"}".
            printf(username, password);
        var secKey = createSecretKey(16);
        var encText = aesEncrypt(aesEncrypt(text, nonce), secKey);
        var encSecKey = rsaEncrypt(secKey, pubKey, modulus);
        string data = "?params=%s&encSecKey=%s".
            printf(GLib.Uri.escape_string(encText), GLib.Uri.escape_string(encSecKey));
        return data;
    }

    private string encrypted_phonelogin(string username, string password) throws Error {
        string text = "{\"phone\": \"%s\", \"password\": \"%s\", \"rememberLogin\": \"true\"}".
            printf(username, password);
        var secKey = createSecretKey(16);
        var encText = aesEncrypt(aesEncrypt(text, nonce), secKey);
        var encSecKey = rsaEncrypt(secKey, pubKey, modulus);
        string data = "?params=%s&encSecKey=%s".
            printf(GLib.Uri.escape_string(encText), GLib.Uri.escape_string(encSecKey));
        return data;
    }

    public async string playlist_detail(int playlist_id) throws Error {
        string uri = "http://music.163.com/api/playlist/detail?id=%d".printf(playlist_id);
        return yield httpRequest(uri, "GET");
    }

    public async string user_playlist(int uid, int offset = 0, int limit = 100) throws Error {
        string uri = "http://music.163.com/api/user/playlist/?" +
            "offset=%d".printf(offset) +
            "&limit=%d".printf(limit) +
            "&uid=%d".printf(uid);
        return yield httpRequest(uri, "GET");
    }

    public async string login(string username, string password) throws Error {
        string str = username;
        str.canon("0123456789", ' ');
        if (str == username) {
            return yield phone_login(username, password);
        }
        return yield mail_login(username, password);
    }

    public async string mail_login(string username, string password) throws Error {
        string uri = "https://music.163.com/weapi/login/";
        uri += encrypted_login(username, password);
        return yield httpRequest(uri, "POST");
    }

    public async string phone_login(string username, string password) throws Error {
        string uri = "https://music.163.com/weapi/login/cellphone";
        uri += encrypted_phonelogin(username, password);
        return yield httpRequest(uri, "POST");
    }


    public async string search(string s, int type = 1, int offset = 0, string total = "true", int limit = 20) throws Error {
        string uri = "http://music.163.com/api/search/get/web";
        uri = uri + "?s=" + GLib.Uri.escape_string (s) +
                "&type=" + "%d".printf(type) +
                "&offset=" + "%d".printf(offset) +
                "&total=" + total +
                "&limit=" + "%d".printf(limit);
        return yield httpRequest(uri, "POST");
    }

    public async string getSongDetail(int id) throws Error {
        string uri = "http://music.163.com/api/song/detail/?id=" +
            "%d".printf(id) + "&ids=[" + "%d".printf(id) + "]";
        return yield httpRequest(uri, "GET");
    }
}
