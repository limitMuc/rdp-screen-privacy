/* SPDX-License-Identifier: GPL-2.0-or-later */

import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const BUS_NAME = 'com.example.RdpScreenPrivacy';
const OBJECT_PATH = '/com/example/RdpScreenPrivacy';
const INTERFACE = 'com.example.RdpScreenPrivacy';

const PrivacyIndicator = GObject.registerClass(
class PrivacyIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'RDP Screen Privacy');
        this._label = new St.Label({text: 'RDP privacy: unknown', y_align: Clutter.ActorAlign.CENTER});
        this.add_child(this._label);

        this._item = new PopupMenu.PopupMenuItem('Status unavailable');
        this._item.setSensitive(false);
        this.menu.addMenuItem(this._item);

        this._off = new PopupMenu.PopupMenuItem('Turn monitors off');
        this._off.connect('activate', () => this._extension?._proxy?.TurnOffSync(null));
        this.menu.addMenuItem(this._off);

        this._on = new PopupMenu.PopupMenuItem('Turn monitors on');
        this._on.connect('activate', () => this._extension?._proxy?.TurnOnSync(null));
        this.menu.addMenuItem(this._on);

        this._lock = new PopupMenu.PopupMenuItem('Lock GNOME session');
        this._lock.connect('activate', () => this._extension?._proxy?.LockSync(null));
        this.menu.addMenuItem(this._lock);

        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
        this._refresh();
    }

    _refresh() {
        try {
            const result = this._extension?._proxy?.GetStateSync(null);
            const state = result?.[0] ?? 'offline';
            this._label.set_text(`RDP privacy: ${state}`);
            this._item.label.text = `Service state: ${state}`;
        } catch (error) {
            this._label.set_text('RDP privacy: offline');
            this._item.label.text = 'Service state unavailable';
        }
    }

    destroy() {
        if (this._timer)
            GLib.Source.remove(this._timer);
        super.destroy();
    }
});

export default class RdpScreenPrivacyExtension extends Extension {
    enable() {
        this._proxy = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SESSION, Gio.DBusProxyFlags.NONE, null,
            BUS_NAME, OBJECT_PATH, INTERFACE, null);
        this._indicator = new PrivacyIndicator();
        this._indicator._extension = this;
        Main.panel.addToStatusArea('rdp-screen-privacy', this._indicator);
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
