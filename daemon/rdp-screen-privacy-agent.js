#!/usr/bin/gjs
/* SPDX-License-Identifier: GPL-2.0-or-later */

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const STATE_FILE = '/run/rdp-screen-privacy/state';
const BUS_NAME = 'com.example.RdpScreenPrivacy';
const OBJECT_PATH = '/com/example/RdpScreenPrivacy';
const XML = `<node><interface name="com.example.RdpScreenPrivacy"><method name="GetState"><arg type="s" name="state" direction="out"/></method><method name="TurnOff"/><method name="TurnOn"/><method name="Lock"/></interface></node>`;

function readState() {
    try {
        const [ok, contents] = GLib.file_get_contents(STATE_FILE);
        return ok ? new TextDecoder().decode(contents).trim() : 'offline';
    } catch (error) {
        return 'offline';
    }
}

const connection = Gio.bus_get_sync(Gio.BusType.SESSION, null);
const exported = Gio.DBusExportedObject.wrapJSObject(XML, {
    GetState() { return [readState()]; },
    TurnOff() { runPrivileged('off'); },
    TurnOn() { runPrivileged('on'); },
    Lock() { runPrivileged('lock'); },
});
exported.export(connection, OBJECT_PATH);
Gio.bus_own_name_on_connection(connection, BUS_NAME, Gio.BusNameOwnerFlags.NONE, null, null);
new GLib.MainLoop(null, false).run();

function runPrivileged(command) {
    Gio.Subprocess.new(
        ['/usr/bin/pkexec', '/usr/local/sbin/rdp-screen-privacy', command],
        Gio.SubprocessFlags.NONE,
    );
}
