/*-
 * Copyright (c) 2015 Yitao Yao (http://simpleyyt.github.io)
 * Authored by: Yitao Yao <simpleyyt@gmail.com>
 */

private class Netease.PreferencesSection {

    public Noise.SettingsWindow.NoteBook_Page page;
    public signal void logined(int id);
    private NeteaseMusic.Settings settings;
    private  Noise.Plugins.NeteaseApi netease;
    Gtk.Button login_button;
    Gtk.Entry username_entry;
    Gtk.Entry password_entry;
    Gtk.Switch remeber_switch;

    public PreferencesSection (NeteaseMusic.Settings settings,  Noise.Plugins.NeteaseApi netease) {
        this.netease = netease;
        this.settings = settings;
        string program_name = ((Noise.App) GLib.Application.get_default ()).get_name ();
        page = new Noise.SettingsWindow.NoteBook_Page(_("网易云音乐"));

        int row = 0;
        page.add_section (new Gtk.Label(_("登录")), ref row);

        username_entry = new Gtk.Entry();
        username_entry.text = settings.username;
        username_entry.placeholder_text  = _("手机或邮箱");

        page.add_option(new Gtk.Label(_("用户名:")), username_entry, ref row);

        password_entry = new Gtk.Entry();
        password_entry.set_visibility(false);
        password_entry.text = settings.password;
        password_entry.placeholder_text  = _("密码");

        page.add_option(new Gtk.Label(_("密码:")), password_entry, ref row);

        remeber_switch = new Gtk.Switch();
        remeber_switch.state = settings.remeber_me;
        page.add_option(new Gtk.Label(_("记住我:")), remeber_switch, ref row);
        settings.schema.bind("remeber-me", remeber_switch, "active", SettingsBindFlags.DEFAULT);

        login_button = new Gtk.Button ();
        login_button.label = _("登录");

        page.add_full_option (login_button, ref row);

        login_button.clicked.connect (() => {loginClick ();});

    }

    private void loginClick () {
        login_button.label = _("登录中...");
        netease.login.begin(username_entry.text, password_entry.text, (obj, res) => {
            try {
                var id = netease.login.end(res);
                settings.username = username_entry.text;
                if (remeber_switch.state == true) {
                    settings.password = password_entry.text;
                } else {
                    settings.password = "";
                }
                login_button.label = _("登录成功！");
                logined(id);
            } catch (Error e) {
                login_button.label = _("错误: " + e.message);
            }
        });
    }
}
