package install_gtk; # $Id$

use diagnostics;
use strict;

use ugtk2 qw(:wrappers :helpers :create);
use common;
use lang;
use devices;

#-#####################################################################################
#-INTERN CONSTANT
#-#####################################################################################

my (@background1, @background2);


#------------------------------------------------------------------------------
sub load_rc {
    my ($name) = @_;

    if (my $f = find { -r $_ } map { "$_/$name.rc" } ("share", $ENV{SHARE_PATH}, dirname(__FILE__))) {
	Gtk2::Rc->parse($f);
	foreach (cat_($f)) {
	    if (/style\s+"background"/ .. /^\s*$/) {
		@background1 = map { $_ * 256 * 257 } split ',', $1 if /NORMAL.*\{(.*)\}/;
		@background2 = map { $_ * 256 * 257 } split ',', $1 if /PRELIGHT.*\{(.*)\}/;
	    }
	}
    }
}

sub default_theme {
    my ($o) = @_;
    $o->{meta_class} eq 'desktop' ? 'blue' :
      $o->{meta_class} eq 'firewall' ? 'mdk-Firewall' : 
      $o->{simple_themes} || $o->{vga16} ? 'blue' : 'mdk';
}

#------------------------------------------------------------------------------
sub install_theme {
    my ($o, $theme) = @_;

    $o->{theme} = $theme || $o->{theme};

    load_rc($_) foreach "themes-$o->{theme}", "install", "themes";

    my %pango_font_name;
    if (my $pango_font = lang::l2pango_font($o->{locale}{lang})) {
	$pango_font_name{10} = "font_name = \"$pango_font 10\"";
	$pango_font_name{12} = "font_name = \"$pango_font 12\"";
    }
    Gtk2::Rc->parse_string(qq(
style "default-font" 
{
   $pango_font_name{12}
}
style "small-font"
{
   $pango_font_name{10}
}
widget "*" style "default-font"

));
    gtkset_background(@background1) unless $::live; #- || testing;

    create_logo_window($o);
#    create_help_window($o);
}

#------------------------------------------------------------------------------
sub create_help_window {
    my ($o) = @_;

    my $w;
    if ($w = $o->{help_window}) {
	$w->{window}->foreach(sub { $_[0]->destroy }, undef);
    } else {
	$w = $o->{help_window} = bless {}, 'ugtk2';
	$w->{rwindow} = $w->{window} = Gtk2::Window->new('toplevel');
	$w->{rwindow}->set_uposition($::rootwidth - $::helpwidth, $::rootheight - $::helpheight);
	$w->{rwindow}->set_size_request($::helpwidth, $::helpheight);
	$w->{rwindow}->set_title('skip');
    };
    gtkadd($w->{window}, create_scrolled_window($o->{help_window_text} = Gtk2::TextView->new));
    $w->show;
}

#------------------------------------------------------------------------------
sub create_steps_window {
    my ($o) = @_;

    return if $::stepswidth == 0;

    $o->{steps_window}->destroy if $o->{steps_window};

    my $w = bless {}, 'ugtk2';
    $w->{rwindow} = $w->{window} = Gtk2::Window->new('toplevel');
    $w->{rwindow}->set_uposition(0, 100);
    $w->{rwindow}->set_size_request($::stepswidth, $::stepsheight);
    $w->{rwindow}->set_name('Steps');
    $w->{rwindow}->set_title('skip');

    my @l = ('', '', N("System installation"));
    my $s;
    foreach (grep { !eval $o->{steps}{$_}{hidden} } @{$o->{orderedSteps}}) {
	if ($_ eq 'setRootPassword') {
	    push @l, $s, N("System configuration");
	    $s = '';
	}
	$s .= ($o->{steps}{$_}{done} ? '+' : '-') . ' ' . translate($o->{steps}{$_}{text}) . "\n";	
    }

    gtkadd($w->{window}, gtkpack__(Gtk2::VBox->new(0,15), @l, $s));
    $w->show;
    $o->{steps_window} = $w;
}

#------------------------------------------------------------------------------
sub create_logo_window {
    my ($o) = @_;

    return if $::logowidth == 0;

    gtkdestroy($o->{logo_window});

    my $w = bless {}, 'ugtk2';
    $w->{rwindow} = $w->{window} = Gtk2::Window->new('toplevel');
    $w->{rwindow}->set_uposition(0, 0);
    $w->{rwindow}->set_size_request($::logowidth, $::logoheight);
    $w->{rwindow}->set_name("logo");
    $w->{rwindow}->set_title('skip');
    $w->show;
    my $file = $o->{meta_class} eq 'desktop' ? "logo-mandrake-Desktop.png" : "logo-mandrake.png";
    $o->{meta_class} eq 'firewall' and $file = "logo-mandrake-Firewall.png";
    -r $file or $file = "$ENV{SHARE_PATH}/$file";
    -r $file and gtkadd($w->{window}, gtkcreate_img($file));
    $o->{logo_window} = $w;
}

#------------------------------------------------------------------------------
sub init_gtk() {
    symlink("/tmp/stage2/etc/$_", "/etc/$_") foreach qw(gtk-2.0 pango fonts);
    Gtk2->init(\@ARGV);
    Gtk2->set_locale;
}

#------------------------------------------------------------------------------
sub init_sizes() {
    ($::rootwidth,  $::rootheight)    = (Gtk2::Gdk->screen_width, Gtk2::Gdk->screen_height);
    $::live and $::rootheight -= 80;
    #- ($::rootheight,  $::rootwidth)    = (min(768, $::rootheight), min(1024, $::rootwidth));
    ($::stepswidth,  $::stepsheight)  = $::rootwidth <= 640 ? (0, 0) : (160, $::rootheight);
    ($::logowidth,   $::logoheight)   = $::rootwidth <= 640 ? (0, 0) : (500, 40);
    ($::helpwidth,   $::helpheight)   = ($::rootwidth - $::stepswidth, 0);
    ($::windowwidth, $::windowheight) = ($::rootwidth - $::stepswidth, $::rootheight - $::helpheight - $::logoheight);
}

#------------------------------------------------------------------------------
sub createXconf {
    my ($file, $mouse_type, $mouse_dev, $wacom_dev) = @_;

    $mouse_type = 'IMPS/2' if $mouse_type eq 'ExplorerPS/2';
    devices::make("/dev/kbd") if arch() =~ /^sparc/; #- used by Xsun style server.
    symlinkf(devices::make($mouse_dev), "/dev/mouse") if $mouse_dev ne 'none';

    #- needed for imlib to start on 8-bit depth visual.
    symlink("/tmp/stage2/etc/imrc", "/etc/imrc");
    symlink("/tmp/stage2/etc/im_palette.pal", "etc/im_palette.pal");

if (arch() =~ /^ia64/) {
     require Xconfig::card;
     my ($card) = Xconfig::card::probe();
     Xconfig::card::add_to_card__using_Cards($card, $card->{type}) if $card && $card->{type};
     output($file, sprintf(<<'END', $mouse_type, $card->{driver}));

Section "Files"
   FontPath   "/usr/X11R6/lib/X11/fonts:unscaled"
EndSection

Section "InputDevice"
    Identifier "Keyboard"
    Driver "Keyboard"
    Option "XkbDisable"
    Option "XkbModel" "pc105"
    Option "XkbLayout" ""
EndSection

Section "InputDevice"
    Identifier "Mouse"
    Driver "mouse"
    Option "Protocol" "%s"
    Option "Device" "/dev/mouse"
EndSection

Section "Monitor"
    Identifier "monitor"
    HorizSync 31.5-35.5
    VertRefresh 50-70
EndSection

Section "Device"
    Identifier  "device"
    Driver      "%s"
EndSection

Section "Screen"
    Identifier "screen"
    Device "device"
    Monitor "monitor"
    DefaultColorDepth 16
    Subsection "Display"
        Depth 16
        Modes "800x600" "640x480"
    EndSubsection
EndSection

Section "ServerLayout"
    Identifier "layout"
    Screen "screen"
    InputDevice "Mouse" "CorePointer"
    InputDevice "Keyboard" "CoreKeyboard"
EndSection

END


} else {

    my $wacom;
    if ($wacom_dev) {
	my $dev = devices::make($wacom_dev);
	$wacom = <<END;
Section "Module"
   Load "xf86Wacom.so"
EndSection

Section "XInput"
    SubSection "WacomStylus"
        Port "$dev"
        AlwaysCore
    EndSubSection
    SubSection "WacomCursor"
        Port "$dev"
        AlwaysCore
    EndSubSection
    SubSection "WacomEraser"
        Port "$dev"
        AlwaysCore
    EndSubSection
EndSection
END
    }

    output($file, <<END);
Section "Files"
   FontPath   "/usr/X11R6/lib/X11/fonts:unscaled"
EndSection

Section "Keyboard"
   Protocol    "Standard"
   AutoRepeat  0 0

   LeftAlt         Meta
   RightAlt        Meta
   ScrollLock      Compose
   RightCtl        Control
   XkbDisable
EndSection

Section "Pointer"
   Protocol    "$mouse_type"
   Device      "/dev/mouse"
   ZAxisMapping 4 5
EndSection

$wacom

Section "Monitor"
   Identifier  "monitor"
   HorizSync   31.5-35.5
   VertRefresh 50-70
   ModeLine "640x480"     25.175 640  664  760  800   480  491  493  525
   ModeLine "640x480"     28.3   640  664  760  800   480  491  493  525
   ModeLine "800x600"     36     800  824  896 1024   600  601  603  625
EndSection


Section "Device"
   Identifier "Generic VGA"
   Chipset "generic"
EndSection

Section "Device"
   Identifier "svga"
EndSection

Section "Screen"
    Driver      "vga16"
    Device      "Generic VGA"
    Monitor     "monitor"
    Subsection "Display"
        Modes      "640x480"
        ViewPort   0 0
    EndSubsection
EndSection

Section "Screen"
    Driver      "fbdev"
    Device      "Generic VGA"
    Monitor     "monitor"
    Subsection "Display"
        Depth      16
        Modes      "default"
        ViewPort   0 0
    EndSubsection
EndSection

Section "Screen"
    Driver      "svga"
    Device      "svga"
    Monitor     "monitor"
    Subsection "Display"
        Depth      16
        Modes      "800x600" "640x480"
        ViewPort   0 0
    EndSubsection
EndSection

Section "Screen"
    Driver      "accel"
    Device      "svga"
    Monitor     "monitor"
    Subsection "Display"
        Depth      16
        Modes      "800x600" "640x480"
        ViewPort   0 0
    EndSubsection
EndSection
END
}
}

1;
