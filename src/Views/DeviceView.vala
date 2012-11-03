/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gee;

public class Noise.DeviceView : Gtk.Grid {
    LibraryManager lm;
    LibraryWindow lw;
    Device d;
    DeviceSummaryWidget summary;
    
    Gtk.InfoBar infobar;
    Gtk.Label infobar_label;
    
    public DeviceView(LibraryManager lm, Device d) {
        this.orientation = Gtk.Orientation.VERTICAL;

        this.lm = lm;
        this.lw = lm.lw;
        this.d = d;

        buildUI();
        
        ulong connector = lm.progress_cancel_clicked.connect( () => {
            if(d.is_syncing()) {
                lw.doAlert(_("Cancelling Sync"), _("Device Sync has been cancelled. Operation will stop after this media."));
                d.cancel_sync();
            }
            if(d.is_transferring()) {
                lw.doAlert(_("Cancelling Import"), _("Import from device has been cancelled. Operation will stop after this media."));
                d.cancel_transfer();
            }
        });
        d.device_unmounted.connect( () => {
            message ("device unmounted\n");
            d.disconnect(connector);
        });
        
        if(d.get_preferences().sync_when_mounted)
            syncClicked();
    }
    
    void buildUI() {
        
        /* create infobar */
        
        infobar = new Gtk.InfoBar();
        infobar.get_style_context ().add_class (Gtk.STYLE_CLASS_INFO);
        infobar.set_hexpand (true);
        infobar_label = new Gtk.Label("");
        (infobar.get_content_area() as Gtk.Container).add(infobar_label);
        infobar.add_button(Gtk.Stock.OK, 0);
        infobar.response.connect( (self, response) => {
            infobar.hide ();
        });
        summary = new DeviceSummaryWidget(lm, lw, d);
        attach (infobar, 0, 0, 1, 1);
        attach (summary, 0, 1, 1, 1);
        
        show_all();
        infobar.hide ();
        d.progress_notification.connect(deviceProgress);
        d.infobar_message.connect (infobar_message_sended);
    }
    
    
    public void set_as_current_view() {
        summary.refresh_lists();
    }
    
    void infobar_message_sended (string message, Gtk.MessageType type) {
        infobar_label.set_label (message);
        infobar.set_message_type(type);
        infobar.show_all();
    }
    
    public void showImportDialog() {
        // ask the user if they want to import medias from device that they don't have in their library (if any)
        // this should be same as MusicViewWrapper
        if(!lm.doing_file_operations() && Settings.Main.instance.music_folder != "") {
            var found = new LinkedList<int>();
            var not_found = new LinkedList<Media>();
            lm.media_from_name(d.get_medias(), ref found, ref not_found);
            
            if(not_found.size > 0) {
                TransferFromDeviceDialog tfdd = new TransferFromDeviceDialog(lw, d, not_found);
                tfdd.show();
            }
            else {
                lw.doAlert(_("No External Songs"), _("There were no songs found on this device that are not in your library."));
            }
        }
    }
    
    public void syncClicked() {
        summary.sync_clicked();
    }
    
    void deviceProgress(string? message, double progress) {
        lw.progressNotification(message, progress);
    }
}

