package Xconfig::default; # $Id$

use diagnostics;
use strict;

use Xconfig::xfree;
use keyboard;
use common;
use mouse;


sub configure {
    my ($keyboard, $mouse) = @_;

    $keyboard ||= keyboard::read();
    $mouse ||= do {
	my $mouse = mouse::read(); 
	add2hash($mouse, mouse::detect()) if !$::noauto;
	$mouse;
    };


    my $raw_X = Xconfig::xfree->empty_config;

    $raw_X->{xfree4}->add_load_module($_) foreach qw(dbe v4l extmod type1 freetype);

    config_keyboard($raw_X, $keyboard);
    config_mouse($raw_X, $mouse);

    $raw_X;
}

sub config_mouse {
    my ($raw_X, $mouse) = @_;
    mouse::set_xfree_conf($mouse, $raw_X);
}

sub config_keyboard {
    my ($raw_X, $keyboard) = @_;

    my $XkbLayout = keyboard::keyboard2xkb($keyboard);

    my $XkbModel = 
      arch() =~ /sparc/ ? 'sun' :
	$XkbLayout eq 'jp' ? 'jp106' : 
	$XkbLayout eq 'br' ? 'abnt2' : 'pc105';

    my $xkb = { $XkbLayout ? (
			      XkbLayout => $XkbLayout, 
			      XkbModel => $XkbModel,
			      if_($keyboard->{GRP_TOGGLE}, XkbOptions => "grp:$keyboard->{GRP_TOGGLE}"),
			     ) : (XkbDisable => undef) };
    $raw_X->set_keyboard($xkb);
}

1;

