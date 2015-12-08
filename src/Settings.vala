/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */
 
namespace NeteaseMusic {

    public class Settings : Granite.Services.Settings {

        public string username { get; set; }
        public string password { get; set; }
        public bool remeber_me {get; set; }

        public Settings () {
            base ("edu.sysu.neteasemusic");
        }
    }
}
