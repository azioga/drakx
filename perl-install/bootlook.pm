#!/usr/bin/perl -w

# Control-center

# Copyright (C) 2001 MandrakeSoft
# Yves Duret <yduret at mandrakesoft.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


use Gtk;
use Config;
init Gtk;
use POSIX;
use lib qw(/usr/lib/libDrakX);
use interactive;
use standalone;
use common qw(:common :file :functional :system);
use my_gtk qw(:helpers :wrappers);
use any;
use bootloader;
use fs;

$::isEmbedded = ($::XID, $::CCPID) = "@ARGV" =~/--embedded (\S*) (\S*)/;
if ($::isEmbedded) {
  print "EMBED\n";
  print "XID : $::XID\n";
  print "CCPID :  $::CCPID\n";
}

my $in = interactive::vnew('su');
local $_ = join '', @ARGV;

/-h/ and die _("no help implemented yet.\n");

my @winm;
my @usernames;
parse_etc_passwd();

my $x_mode = isXlaunched();
my $a_mode = (-e "/etc/aurora/Monitor") ? 1 : 0;
my $l_mode = isAutologin();
my %auto_mode = get_autologin("");
my $inmain = 0;
my $lilogrub = `detectloader -q`;
chomp $lilogrub;

my $window = $::isEmbedded ? new Gtk::Plug ($::XID) : new Gtk::Window ("toplevel");
$window->signal_connect(delete_event => sub { $::isEmbedded ? kill(USR1, $::CCPID) : Gtk->exit(0) });
$window->set_title(_("Boot Style Configuration") );
$window->border_width(2);
$window->realize;

# drakX mode
my ($t_pixmap, $t_mask) = gtkcreate_png("tradi.png");
my ($h_pixmap, $h_mask) = gtkcreate_png("hori.png");
my ($v_pixmap, $v_mask) = gtkcreate_png("verti.png");
my ($g_pixmap, $g_mask) = gtkcreate_png("gmon.png");
my ($c_pixmap, $c_mask) = gtkcreate_png("categ.png");

# a pixmap widget to contain the pixmap
my $pixmap = new Gtk::Pixmap( $h_pixmap, $h_mask );

### menus definition
# the menus are not shown
# but they provides shiny shortcut like C-q
my @menu_items = ( { path        => _("/_File"),
		     type        => '<Branch>' },
		   { path        => _("/File/_New"),
		     accelerator => _("<control>N"),
		     callback    => \&print_hello },
		   { path        => _("/File/_Open"),
		     accelerator => _("<control>O"),
		     callback    => \&print_hello },
		   { path        => _("/File/_Save"),
		     accelerator => _("<control>S"),
		     callback    => \&print_hello },
		   { path        => _("/File/Save _As") },
		   { path        => _("/File/-"),
		     type        => '<Separator>' },
		   { path        => _("/File/_Quit"),
		     accelerator => _("<control>Q"),
		     callback    => sub { $::isEmbedded ? kill(USR1, $::CCPID) : Gtk->exit(0) } },
		   { path        => _("/_Options"),
		     type        => '<Branch>' },
		   { path        => _("/Options/Test")},
		   { path        => _("/_Help"),
		     type        => '<LastBranch>' },
		   { path        => _("/Help/_About...")} );

my $menubar = get_main_menu( $window );

######### menus end

my $global_vbox = new Gtk::VBox();

########### lilo/grub
my $lilo_dedans = new Gtk::HBox(0, 0);
my $lilo_button = new Gtk::Button _("Configure");

my $lilo_label = new Gtk::Label(
_("You are currently using %s as Boot Manager.
Click on Configure to launch the setup wizard.", $lilogrub));

$lilo_dedans->pack_start($lilo_label,0,0,0);
$lilo_dedans->pack_end($lilo_button,0,0,0);
$lilo_button->signal_connect(clicked => sub { lilo_choice(); });

my $lilo_frame = new Gtk::Frame _("Lilo/grub mode");
$lilo_frame->add($lilo_dedans);
$global_vbox->pack_start ($lilo_frame, 0, 0, 0);


######## aurora part
my $a_dedans = new Gtk::VBox(0, 5);
$a_dedans->border_width(0);
my $a_box = new Gtk::VBox(0, 0);

my $a_c_button = new Gtk::RadioButton _("NewStyle Categorizing Monitor");
$a_c_button->signal_connect(clicked => sub { $pixmap->set($c_pixmap, $c_mask) });
$a_box->pack_start($a_c_button, 0, 0, 0);
my $a_h_button = new Gtk::RadioButton _("NewStyle Monitor"), $a_c_button;
$a_h_button->signal_connect(clicked => sub { $pixmap->set($h_pixmap, $h_mask) });
$a_box->pack_start($a_h_button, 0, 0, 0);
my $a_v_button = new Gtk::RadioButton _("Traditional Monitor"), $a_c_button;
$a_v_button->signal_connect(clicked => sub { $pixmap->set($v_pixmap, $v_mask) });
$a_box->pack_start($a_v_button, 0, 0, 0);
my $a_g_button = new Gtk::RadioButton _("Traditional Gtk+ Monitor"), $a_c_button;
$a_g_button->signal_connect(clicked => sub { $pixmap->set($g_pixmap, $g_mask) });
$a_box->pack_start($a_g_button, 0, 0, 0);

my $a_button = new Gtk::CheckButton(_("Launch Aurora at boot time") );
$a_button->signal_connect(clicked => sub {
			      if ($inmain) {
				  $a_box->set_sensitive(!$a_mode);
				  $a_mode = !$a_mode;
				  if ($a_mode) {
				      $pixmap->set($c_pixmap, $c_mask) if $a_c_button->get_active();
				      $pixmap->set($h_pixmap, $h_mask) if $a_h_button->get_active();
				      $pixmap->set($v_pixmap, $v_mask) if $a_v_button->get_active();
				      $pixmap->set($g_pixmap, $g_mask) if $a_g_button->get_active();
				  } else {
				      $pixmap->set($t_pixmap, $t_mask);
				  }
			      }
			   });
$a_dedans->pack_start($a_button, 0, 0, 0);
$a_dedans->pack_start ($a_box, 0, 0, 0);

my $a_main_hbox = new Gtk::HBox;
$a_main_hbox->pack_start ($a_dedans, 0, 0, 0);
my $a_pix_hbox = new Gtk::HBox;
$a_pix_hbox->border_width(0);
$a_pix_hbox->pack_start ($pixmap, 0, 0, 0);
$a_main_hbox->pack_end ($a_pix_hbox, 0, 0, 0);

my $aurora_frame = new Gtk::Frame _("Boot mode");
$aurora_frame->add($a_main_hbox);
$global_vbox->pack_start ($aurora_frame, 0, 0, 0);

### X mode
my $x_dedans = new Gtk::VBox(0, 0);
$x_dedans->border_width (0);
my $x_box = new Gtk::VBox(0, 0);
$x_box->border_width (0);

my $x_button = new Gtk::CheckButton _("Launch the X-Window system at start");
$x_button->set_active($x_mode);
$x_button->signal_connect(clicked => sub {
			       $x_box->set_sensitive(!$x_mode);
			       $x_mode = !$x_mode;
			   });
$x_dedans->pack_start ($x_button, 0, 0, 0);

my $x_no_button = new Gtk::RadioButton _("No, I don't want autologin");
$x_no_button->set_active(!$l_mode);
$x_box->pack_start($x_no_button, 0, 0, 0);

my $user_dedans = new Gtk::HBox(0, 10);
$user_dedans->border_width (0);
my $x_yes_button = new Gtk::RadioButton _("Yes, I want autologin with this (user, desktop)"), $x_no_button;
$x_yes_button->set_active($l_mode);
my $x_combo_vbox = new Gtk::VBox(0, 10);
my $user_combo = new Gtk::Combo;
$user_combo->set_popdown_strings(@usernames);
$user_combo->entry->set_text($auto_mode{autologin}) if ($auto_mode{autologin});

my $desktop_combo =new Gtk::Combo;
$desktop_combo->set_popdown_strings(get_wm());
$desktop_combo->entry->set_text($auto_mode{desktop}) if ($auto_mode{desktop});
$x_combo_vbox->pack_start($user_combo, 0, 0, 0);
$x_combo_vbox->pack_start($desktop_combo, 0, 0, 0);
$user_dedans->pack_start($x_yes_button, 0, 0, 0);
$user_dedans->pack_start($x_combo_vbox, 0, 0, 0);
$x_box->pack_start ($user_dedans, 0, 0, 0);
$x_box->set_sensitive($x_mode);
$x_dedans->pack_start ($x_box, 0, 0, 0);
my $x_main_frame = new Gtk::Frame _("System mode");
$x_main_frame->add($x_dedans);
$global_vbox->pack_start ($x_main_frame, 1, 1, 0);

#deush : hability to choose the runlevel.
my $runl_hbox = new Gtk::HBox;
my $runl_button5 = new Gtk::RadioButton _("5");
my $runl_button1 = new Gtk::RadioButton _("1"), $runl_button5;
$runl_hbox->pack_start($runl_button1, 0, 0, 0);
my $runl_button2 = new Gtk::RadioButton _("2"), $runl_button5;
$runl_hbox->pack_start($runl_button2, 0, 0, 0);
my $runl_button3 = new Gtk::RadioButton _("3"), $runl_button5;
$runl_hbox->pack_start($runl_button3, 0, 0, 0);
my $runl_button4 = new Gtk::RadioButton _("4"), $runl_button5;
$runl_hbox->pack_start($runl_button4, 0, 0, 0);

$runl_hbox->pack_start($runl_button5, 0, 0, 0);

my $runlevel_frame = new Gtk::Frame _("Default Runlevel");
$runlevel_frame->add($runl_hbox);
$global_vbox->pack_start ($runlevel_frame, 0, 0, 0);

### final buttons
my $bbox = new Gtk::HButtonBox;
$global_vbox->pack_start($bbox, 0, 0, 0);
$bbox->set_layout(-end);
my $build_button = new Gtk::Button _("OK");
$bbox->add($build_button);
my $cancel_button = new Gtk::Button $::isEmbedded ? _("Cancel") : _("Quit");
$bbox->add($cancel_button);
my $fin_hbox = new Gtk::HBox( 0, 0 );
$cancel_button->signal_connect(clicked => sub {$::isEmbedded ? kill(USR1, $::CCPID) : Gtk->exit(0)});
$build_button->signal_connect(clicked=>sub{updateInit();updateAutologin();updateAurora();runlevel_choice();$::isEmbedded ? kill(USR1,$::CCPID) : Gtk->exit(0)});

### back to window
$window->add($global_vbox);
$window->show_all();

$a_box->set_sensitive($a_mode); # box gris�e == false == "0"
$a_button->set_active($a_mode); # up == false == "0"
if ($a_mode) {
    my $a = readlink "/etc/aurora/Monitor";
    $a =~ s#/lib/aurora/Monitors/##;
    if ($a eq "NewStyle-Categorizing-WsLib") {$a_c_button->set_active(1);  $pixmap->set($c_pixmap, $c_mask);}
    if ($a eq "NewStyle-WsLib") {$a_h_button->set_active(1);  $pixmap->set($h_pixmap, $h_mask);}
    if ($a eq "Traditional-WsLib") {$a_v_button->set_active(1); $pixmap->set($v_pixmap, $v_mask);}  
    if ($a eq "Traditional-Gtk+") {$a_g_button->set_active(1); $pixmap->set($g_pixmap, $g_mask);}
} else {
    $pixmap->set($t_pixmap, $t_mask);
}

Gtk->main_iteration while Gtk->events_pending;
$::isEmbedded and kill USR2, $::CCPID;
$inmain=1;
Gtk->main;
Gtk->exit(0);

#-------------------------------------------------------------
# get user names to put in combo  
#-------------------------------------------------------------

sub parse_etc_passwd
{
    my ($uname, $uid);
    setpwent();
    do {
	@user_info = getpwent();
	($uname, $uid) = @user_info[0,2];
	if ($uid > 500) {
	    push (@usernames, $uname);
	}
    } while (@user_info);
}

sub get_wm
{
    @winm = (split (' ', `/usr/sbin/chksession -l`));
}

#-------------------------------------------------------------
# menu callback functions
#-------------------------------------------------------------

sub print_hello {
  print( "mcdtg !\n" );
}

sub get_main_menu {
  my ( $window ) = @_;

  my $accel_group = new Gtk::AccelGroup();
  my $item_factory = new Gtk::ItemFactory( 'Gtk::MenuBar', '<main>', $accel_group );
  $item_factory->create_items( @menu_items );
  $window->add_accel_group( $accel_group );
  return ( $item_factory->get_widget( '<main>' ) );
}

#-------------------------------------------------------------
# launch X functions
#-------------------------------------------------------------

sub isXlaunched
{
    my $line;
    
    open INITTAB, "/etc/inittab" or die _("can not open /etc/inittab for reading: $!");
    while (<INITTAB>) {
	if (/id:([1-6]):initdefault:/) { $line = $_; last; }
    }
    close INITTAB;
    $line =~ s/id:([1-6]):initdefault:/$1/;
    return ($line-3);
}

sub updateInit
{
    my $runlevel = ($x_mode) ? 5 : 3;
    substInFile { s/^id:\d:initdefault:\s*$/id:$runlevel:initdefault:\n/ } "/etc/inittab";
}

#-------------------------------------------------------------
# aurora functions
#-------------------------------------------------------------



sub updateAurora
{
    if ($a_mode) {
        if ($a_c_button->get_active()) {
            symlinkf("/lib/aurora/Monitors/NewStyle-Categorizing-WsLib",    "/etc/aurora/Monitor");
            $in->standalone::pkgs_install(q(Aurora-Monitor-NewStyle-Categorizing-WsLib)) if !(-e "/lib/aurora/Monitors/NewStyle-Categorizing-WsLib");
        }
        if ($a_h_button->get_active()) {
            symlinkf("/lib/aurora/Monitors/NewStyle-WsLib",    "/etc/aurora/Monitor");
            $in->standalone::pkgs_install(q(Aurora-Monitor-NewStyle-WsLib)) if !(-e "/lib/aurora/Monitors/NewStyle-WsLib");
        }
        if ($a_v_button->get_active()) {
            symlinkf("/lib/aurora/Monitors/Traditional-WsLib", "/etc/aurora/Monitor");
            $in->standalone::pkgs_install(q(Aurora-Monitor-Traditional-WsLib)) if !(-e "/lib/aurora/Monitors/Traditional-WsLib");
        }
        if ($a_g_button->get_active()) {
            symlinkf("/lib/aurora/Monitors/Traditional-Gtk+",  "/etc/aurora/Monitor");
            $in->standalone::pkgs_install(q(Aurora-Monitor-Traditional-Gtk+)) if !(-e "/lib/aurora/Monitors/Traditional-Gtk+");
	}
    } else {
	unlink "/etc/aurora/Monitor";
    }
    
}

#-------------------------------------------------------------
# launch autologin functions
#-------------------------------------------------------------

sub isAutologin
{
    my $line;
    
    open AUTOLOGIN, "/etc/sysconfig/autologin" or die _("can not open /etc/sysconfig/autologin for reading: $!");
    while (<AUTOLOGIN>) {
	if (/AUTOLOGIN=(yes|no)/) { $line = $_; last; }
    }
    close AUTOLOGIN;
    $line =~ s/AUTOLOGIN=(yes|no)/$1/;
    chomp ($line);
    $line =  ($line eq "yes");
    return ($line);
}

sub get_autologin {
    my ($prefix) = @_;
    my %o;
    my %l = getVarsFromSh("$prefix/etc/sysconfig/autologin");

    $o{autologin} = $l{USER};
    %l = getVarsFromSh("$prefix/etc/sysconfig/desktop");
    $o{desktop} = $l{DESKTOP};
    %o;
}

sub updateAutologin
{
    my ($usern,$deskt)=($user_combo->entry->get_text(), $desktop_combo->entry->get_text());

    if ($x_yes_button->get_active()) {
	$in->standalone::pkgs_install(q(autologin)) if $x_mode;
	set_autologin('',$usern,$deskt);
    } else {
	set_autologin('',undef) if ($x_no_button->get_active());
    }
}
 
sub set_autologin {
  my ($prefix, $user, $desktop) = @_;

  output "$prefix/etc/sysconfig/desktop", uc($desktop), "\n" if $user;

  setVarsInSh("$prefix/etc/sysconfig/autologin",
	      { USER => $user, AUTOLOGIN => bool2yesno($user), EXEC => "/usr/X11R6/bin/startx" });
  chmod 0600, "$prefix/etc/sysconfig/autologin";
#  log::l("cat $prefix/etc/sysconfig/autologin: ", cat_("$prefix/etc/sysconfig/autologin"));
}


#-------------------------------------------------------------
# lilo/grub functions
#-------------------------------------------------------------
sub lilo_choice
{
    my $bootloader = bootloader::read('', '/etc/lilo.conf');
    local ($_) = `detectloader`;
    $bootloader->{methods} = { lilo => 1, grub => !!/grub/i };
    
    my ($hds) = catch_cdie { fsedit::hds([ detect_devices::hds() ], {}) } sub { 1 };
    my $fstab = [ fsedit::get_fstab(@$hds) ];
    fs::get_mntpoints_from_fstab($fstab);
 
    $::expert=1;
  ask:
    local $::isEmbedded = 0;
    any::setupBootloader($in, $bootloader, $hds, $fstab, $ENV{SECURE_LEVEL}) or return;
    eval { bootloader::install('', $bootloader, $fstab, $hds) };  
    if ($@) {
	$in->ask_warn('', 
		      [ _("Installation of LILO failed. The following error occured:"),
			grep { !/^Warning:/ } cat_("/tmp/.error") ]);
	unlink "/tmp/.error";
	goto ask;
    }
}

#---------------------------------------------------------------
# Choose your runlevel: from 1 to 5
#---------------------------------------------------------------
sub runlevel_choice
{
    if ($runl_button1->get_active()) {
      any::runlevel('',1);
        }
    if ($runl_button2->get_active()) {
      any::runlevel('',2);
    }
    if ($runl_button3->get_active()) {
      any::runlevel('',3);
    }
    if ($runl_button4->get_active()) {
      any::runlevel('',4);
    }
    if ($runl_button5->get_active()) {
      any::runlevel('',5);
    }
}

