package harddrake::ui;

use strict;

require harddrake::data;
use common;
use my_gtk qw(:helpers :wrappers :various);
use interactive;


# { field => [ short_translation, full_description] }
my %fields = 
    (
     "alternative_drivers" => [ _("Alternative drivers"),
                                _("the list of alternative drivers for this sound card")],
     "bus" => 
     [ _("Bus"), 
       _("this is the physical bus on which the device is plugged (eg: PCI, USB, ...)")],
     "channel" => [_("Channel"), _("EIDE/SCSI channel")],
     "bus_id" => 
     [ _("Bus identification"), 
       _("- PCI and USB devices: this list the vendor, device, subvendor and subdevice PCI/USB ids")],
     "bus_location" => 
     [ _("Location on the bus"), 
       _("- pci devices: this gives the PCI slot, device and function of this card
- eide devices: the device is either a slave or a master device
- scsi devices: the scsi bus and the scsi device ids")],
     "description" => [ _("Description"), _("this field describe the device")],
     "device" => [ _("Old device file"),
                   _("old static device name used in dev package")],
     "devfs_device" => [ _("New devfs device"),  
                         _("new dinamic device name generated by incore kernel devfs")],
     "driver" => [ _("Module"), _("the module of the GNU/Linux kernel that handle that device")],
     "media_type" => [ _("Media class"), _("class of hardware device")],
     "Model" => [_("Model"), _("hard disk model")],
     "nbuttons" => [ _("Number of buttons"), "the number of buttons the mouse have"],
     "name" => [ _("Name"), "the name of the cpu"],
     "processor" => [ _("Processor ID"), _("the number of the processor")],
     "Vendor" => [ _("Vendor"), _("the vendor name of the device")],
     "vendor_id" => [ _("Vendor"), _("the vendor name of the processor")]
     );


our $license = 'Copyright (C) 1999-2002 MandrakeSoft by tvignaud@mandrakesoft.com

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
';

my ($in, %IDs, $pid, $w);

my %options;
my $conffile = "/etc/sysconfig/harddrake2/ui.conf";

my ($modem_check_box, $printer_check_box);

my @menu_items = 
    (
     {   path => _("/_File"), type => '<Branch>' },
     {   path => _("/_File")._("/_Quit"), accelerator => _("<control>Q"), callback => \&quit_global    },
#     {   path => _("/_Options")._("/Autodetect _printers"), type => '<CheckItem>',
#         callback => sub { $options{PRINTERS_DETECTION} ^= 1 } },
#     {   path => _("/_Options")._("/Autodetect _modems"), type => '<CheckItem>',
#         callback => sub { $options{MODEMS_DETECTION} ^= 1 } },
     {   path => _("/_Help"), type => '<Branch>' },
     {
         path => _("/_Help")._("/_Help..."), 
         callback => sub {
             $in->ask_warn(_("Harddrake help"), 
                           _("Description of the fields:\n\n")
                           . join("\n\n", map { if_($fields{$_}[0], "$fields{$_}[0]: $fields{$_}[1]")} keys %fields));
         }
     },
     {   path => _("/_Help")._("/_Report Bug"),
         callback => sub { unless (fork) { exec("drakbug --report harddrake2 &") } } },
     {   path => _("/_Help")._("/_About..."), 
         callback => sub {
             $in->ask_warn(_("About Harddrake"), 
                           join ("", _("This is HardDrake, a Mandrake hardware configuration tool.\nVersion:"), " $harddrake::data::version\n", 
                                 _("Author:"), " Thierry Vignaud <tvignaud\@mandrakesoft.com> \n\n" ,
                                 formatAlaTeX($license)));
         }
     }
     );

# fill the devices tree
sub detect {
    my @class_tree;
    foreach (@harddrake::data::tree) {
        my ($Ident, $title, $icon, $configurator, $detector) = @$_;
        next if (ref($detector) ne "CODE"); #skip class witouth detector
        next if $Ident =~ /(MODEM|PRINTER)/ && "@ARGV" =~ /test/;
        next if $Ident =~ /MODEM/ && !$options{MODEMS_DETECTION};
        next if $Ident =~ /PRINTER/ && !$options{PRINTERS_DETECTION};
#    print _("Probing %s class\n", $Ident);
#    standalone::explanations("Probing %s class\n", $Ident);

        my @devices = &$detector;
        next if (!listlength(@devices)); # Skip empty class (no devices)
        my $devices_list;
        foreach (@devices) {
            $_->{custom_id} = harddrake::data::custom_id($_, $title);
            if (exists $_->{bus} && $_->{bus} eq "PCI") {
                my $i = $_;
                $_->{bus_id} = join ':', map { if_($i->{$_} ne "65535",  sprintf("%lx", $i->{$_})) } qw(vendor id subvendor subid);
                $_->{bus_location} = join ':', map { sprintf("%lx", $i->{$_} ) } qw(pci_bus pci_device pci_function);
            }
            # split description into manufacturer/description
            ($_->{Vendor}, $_->{description}) = split(/\|/,$_->{description}) if exists $_->{description};
            
            if (exists $_->{val}) { # Scanner ?
                my $val = $_->{val};
                ($_->{Vendor},$_->{description}) = split(/\|/, $val->{DESCRIPTION});
            }
            # EIDE detection incoherency:
            if (exists $_->{bus} && $_->{bus} eq 'ide') {
                $_->{channel} = _($_->{channel} ? "secondary" : "primary");
                delete $_->{info};
            } elsif ((exists $_->{id}) && ($_->{bus} ne 'PCI')) {
                # SCSI detection incoherency:
                my $i = $_;
                $_->{bus_location} = join ':', map { sprintf("%lx", $i->{$_} ) } qw(bus id);
            }
            if ($Ident eq "AUDIO") {
                require harddrake::sound;
                my $alter = harddrake::sound::get_alternative($_->{driver});
                $_->{alternative_drivers} = join(':', @$alter) if $alter->[0] ne 'unknown';
            }
            foreach my $i (qw(vendor id subvendor subid pci_bus pci_device pci_function MOUSETYPE XMOUSETYPE unsafe val devfs_prefix wacom auxmouse)) { delete $_->{$i} }
            $_->{device} = '/dev/'.$_->{device} if exists $_->{device};
            push @$devices_list, $_;
        }
        push @class_tree, [ $devices_list, [ [$title], 5], $icon, [ 0, ($title =~ /Unknown/ ? 0 : 1) ], $title, $configurator ];
    }
    @class_tree;
}

sub new {
    my ($sig_id, $wait);
    unless ($::isEmbedded) {
        $in = 'interactive'->vnew('su', 'default');
        $wait = $in->wait_message(_("Please wait"), _("Detection in progress"));
        my_gtk::flush;
    }
    %options = getVarsFromSh($conffile);
    my @class_tree = &detect;

    # Build the gui
    add_icon_path('/usr/share/pixmaps/harddrake2/');
    $w = my_gtk->new((_("Harddrake2 version ") . $harddrake::data::version));
    $w->{window}->set_usize(760, 550) unless $::isEmbedded;
    $options{MODEMS_DETECTION} = 1 unless defined $options{MODEMS_DETECTION};
    $options{PRINTERS_DETECTION} = 1 unless defined $options{PRINTERS_DETECTION};

    $w->{window}->add(my $main_vbox = gtkadd(gtkadd($::isEmbedded ? new Gtk::VBox(0, 0) :
                                                    gtkadd(new Gtk::VBox(0, 0),
                                                           my $menubar = ugtk::create_factory_menu($w->{rwindow}, @menu_items)),
                                                    my $hpaned = new Gtk::HPaned),
                                             my $statusbar = new Gtk::Statusbar));
    $main_vbox->set_child_packing($statusbar, 0, 0, 0, 'start');
    if ($::isEmbedded) {
        $main_vbox->add(gtksignal_connect(my $but = new Gtk::Button(_("Quit")),
                                          'clicked' => \&quit_global));
        $main_vbox->set_child_packing($but, 0, 0, 0, 'start');
    } else { $main_vbox->set_child_packing($menubar, 0, 0, 0, 'start') }

    $hpaned->pack1(gtkadd(new Gtk::Frame(_("Detected hardware")), createScrolledWindow(my $tree = new Gtk::CTree(1, 0))), 1, 1);
    $hpaned->pack2(my $vbox = gtkadd(gtkadd(gtkadd(new Gtk::VBox,
                                                   gtkadd(new Gtk::Frame(_("Information")),
                                                          gtkadd(new Gtk::HBox, 
                                                                 createScrolledWindow(my $text = new Gtk::Text)))), 
                                            my $module_cfg_button = new Gtk::Button(_("Configure module"))),
                                     my $config_button = new Gtk::Button(_("Run config tool"))), 1, 1);
    $vbox->set_child_packing($config_button, 0, 0, 0, 'start');
    $vbox->set_child_packing($module_cfg_button, 0, 0, 0, 'start');

    my $cmap = Gtk::Gdk::Colormap->get_system;
    my $color = { 'red' => 0x3100, 'green' => 0x6400, 'blue' => 0xbc00 };
    $cmap->color_alloc($color);
    my $wcolor = { 'red' => 0xFFFF, 'green' => 0x6400, 'blue' => 0x6400 };
    $cmap->color_alloc($wcolor);
    $tree->set_column_auto_resize(0, 1);
    my $curr = $tree->node_nth(0); #- default value

    $tree->signal_connect( 'select_row', sub {
        my ( $ctree, $row, $column, $event ) = @_;
        my $node = $ctree->node_nth( $row );
        my ($name, undef) = $tree->node_get_pixtext($node,0);
        my $data = $tree->{data}{$name};

        if ($data) {
            $text->hide;
            $text->backward_delete($text->get_point);
            foreach my $i (sort keys %$data) {
                $text->insert("", $text->style->black, "", ($fields{$i}[0] ? $fields{$i}[0] : $i) . ": ");
                if ($i eq 'driver' && $data->{$i} eq 'unknown') {
                    $text->insert("", $wcolor, "", "$data->{$i}\n\n");
                } else { $text->insert("", $color, "", "$data->{$i}\n\n") }
            }
            disconnect($module_cfg_button, 'module');

            # we've valid driver, let's offer to configure it
            if (exists $data->{driver} &&  $data->{driver} !~ /(unknown|.*\|.*)/ &&  $data->{driver} !~ /^Card:/) {
                $module_cfg_button->show;
                $IDs{module} = $module_cfg_button->signal_connect(clicked => sub {
                    require modules::interactive;
                    modules::interactive::config_window($in, $data);
                    gtkset_mousecursor_normal();
                });
            }
            disconnect($config_button, 'tool');
            $text->show;
            my $configurator = $tree->{configurator}{$name};

            return unless -x $configurator;
            
            # we've a configurator, let's add a button for it and show it
            $IDs{tool} = $config_button->signal_connect(clicked => sub {
                return if defined $pid;
                if ($pid = fork()) {
                    $sig_id = $statusbar->push($statusbar->get_context_id("id"), _("Running \"%s\" ...", $configurator));
                } else { exec($configurator) or die "$configurator missing\n" }
            }) ;
            $config_button->show;
        } else {
            $text->backward_delete($text->get_point); # erase all previous text
            $config_button->hide;
            $module_cfg_button->hide;
        }
    });

    # Fill the graphic tree with a "tree branch" widget per device category
    foreach (@class_tree) {
        my ($devices_list, $arg, $icon, $arg2, $title, $configurator ) = @$_;
        my $hw_class_tree = $tree->insert_node(undef, undef, @$arg, (gtkcreate_png($icon)) x 2, @$arg2);
        # Fill the graphic tree with a "tree leaf" widget per device
        foreach (@$devices_list) {
            my $custom_id = $_->{custom_id};
            delete $_->{custom_id};
            $custom_id .= ' ' while exists($tree->{data}{$custom_id});
            my $hw_item = $tree->insert_node($hw_class_tree, undef, [$custom_id ], 5, (undef) x 4, 1, 0);
            $tree->{data}{$custom_id} = $_;
            $tree->{configurator}{$custom_id} = $configurator;
        }
    }

    $SIG{CHLD} = sub { undef $pid; $statusbar->pop($sig_id) };
    $w->{rwindow}->signal_connect (delete_event => \&quit_global);
    undef $wait;
    gtkset_mousecursor_normal();
    $w->{rwindow}->set_position('center') unless $::isEmbedded;
    $w->{rwindow}->show_all();
    foreach ($module_cfg_button, $config_button) { $_->hide };
    $in = 'interactive'->vnew('su', 'default') if $::isEmbedded;
    $w->main;
}


sub quit_global {
    kill(15, $pid) if ($pid);
    setVarsInSh($conffile, \%options);
    $w->{rwindow}->destroy;
    $in->exit;
}

# remove a signal handler from a button & hide it  if needed
sub disconnect {
    my ($button, $id) = @_;
    if ($IDs{$id}) {
        $button->signal_disconnect($IDs{$id});
        $button->hide;
        undef $IDs{$id};
    }
}

1;
