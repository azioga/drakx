package interactive;

use diagnostics;
use strict;

#-######################################################################################
#- misc imports
#-######################################################################################
use common qw(:common :functional);

#- heritate from this class and you'll get all made interactivity for same steps.
#- for this you need to provide
#- - ask_from_listW(o, title, messages, arrayref, default) returns one string of arrayref
#- - ask_many_from_listW(o, title, messages, arrayref, arrayref2) returns many strings of arrayref
#-
#- where
#- - o is the object
#- - title is a string
#- - messages is an refarray of strings
#- - default is an optional string (default is in arrayref)
#- - arrayref is an arrayref of strings
#- - arrayref2 contains booleans telling the default state,
#-
#- ask_from_list and ask_from_list_ are wrappers around ask_from_biglist and ask_from_smalllist
#-
#- ask_from_list_ just translate arrayref before calling ask_from_list and untranslate the result
#-
#- ask_from_listW should handle differently small lists and big ones.



#-######################################################################################
#- OO Stuff
#-######################################################################################
sub new($) {
    my ($type) = @_;

    bless {}, ref $type || $type;
}

sub vnew {
    my ($type, $su) = @_;
    $su = $su eq "su";
    require c;
    if (c::Xtest($ENV{DISPLAY} ||= ":0")) {
	if ($su && $>) {
	    $ENV{PATH} = "/sbin:/usr/sbin:$ENV{PATH}";
	    exec "kdesu", "-c", "$0 @ARGV";	    
	}
	require interactive_gtk;
	interactive_gtk->new;
    } else {
	if ($su && $>) {
	    die "you must be root to run this program";
	}
	require 'log.pm';
	undef *log::l;
	*log::l = sub {}; # otherwise, it will bother us :(
	require interactive_newt;
	interactive_newt->new;
    }
}

sub end {}
sub exit { exit($_[0]) }

#-######################################################################################
#- Interactive functions
#-######################################################################################
sub ask_warn($$$) {
    my ($o, $title, $message) = @_;
    ask_from_list2($o, $title, $message, [ _("Ok") ]);
}

sub ask_yesorno($$$;$) {
    my ($o, $title, $message, $def) = @_;
    ask_from_list2_($o, $title, $message, [ __("Yes"), __("No") ], $def ? "Yes" : "No") eq "Yes";
}

sub ask_okcancel($$$;$) {
    my ($o, $title, $message, $def) = @_;
    ask_from_list2_($o, $title, $message, [ __("Ok"), __("Cancel") ], $def ? "Ok" : "Cancel") eq "Ok";
}

sub ask_from_list_ {
    my ($o, $title, $message, $l, $def) = @_;
    @$l == 0 and die '';
    @$l == 1 and return $l->[0];
    goto &ask_from_list2_;
}

sub ask_from_list {
    my ($o, $title, $message, $l, $def) = @_;
    @$l == 0 and die '';
    @$l == 1 and return $l->[0];
    goto &ask_from_list2;
}

sub ask_from_list2_($$$$;$) {
    my ($o, $title, $message, $l, $def) = @_;
    untranslate(
       ask_from_list($o, $title, $message, [ map { translate($_) } @$l ], translate($def)),
       @$l);
}

sub ask_from_list2($$$$;$) {
    my ($o, $title, $message, $l, $def) = @_;

    @$l > 10 and $l = [ sort @$l ];

    $o->ask_from_listW($title, [ deref($message) ], $l, $def || $l->[0]);
}
sub ask_many_from_list_ref($$$$;$) {
    my ($o, $title, $message, $l, $val) = @_;
    $o->ask_many_from_list_refW($title, [ deref($message) ], $l, $val);
}
sub ask_many_from_list($$$$;$) {
    my ($o, $title, $message, $l, $def) = @_;

    my $val = [ map { my $i = $_; \$i } @$def ];

    $o->ask_many_from_list_ref($title, $message, $l, $val) ?
      [ map { $$_ } @$val ] : undef;
}

sub ask_from_entry {
    my ($o, $title, $message, $label, $def, %callback) = @_;

    first ($o->ask_from_entries($title, [ deref($message) ], [ $label ], [ $def ], %callback));
}

sub ask_from_entries($$$$;$%) {
    my ($o, $title, $message, $l, $def, %callback) = @_;

    my $val = [ map { my $i = $_; \$i } @{$def || [('') x @$l]} ];

    $o->ask_from_entries_ref($title, $message, $l, $val, %callback) ?
      map { $$_ } @$val :
      undef;
}

sub ask_from_entries_refH($$$;$%) {
    my ($o, $title, $message, $h, %callback) = @_;

    ask_from_entries_ref($o, $title, $message, 
			 [ grep_index { even($::i) } @$h ],
			 [ grep_index {  odd($::i) } @$h ], 
			 %callback);    
}

#- can get a hash of callback: focus_out changed and complete
#- moreove if you pass a hash with a field list -> combo
#- if you pass a hash with a field hidden -> emulate stty -echo
sub ask_from_entries_ref($$$$;$%) {
    my ($o, $title, $message, $l, $val, %callback) = @_;

    return unless @$l;

    $title = [ deref($title) ];
    $title->[2] ||= _("Cancel") unless $title->[1];
    $title->[1] ||= _("Ok");

    my $val_hash = [ map {
	if ((ref $_) eq "SCALAR") {
	    { val => $_ }
	} else {
	    ($_->{list} && (@{$_->{list}} > 1)) ?
	      { %$_, type => "list"} : $_;
	}
    } @$val ];

    $o->ask_from_entries_refW($title, [ deref($message) ], $l, $val_hash, %callback)

}
sub wait_message($$$;$) {
    my ($o, $title, $message, $temp) = @_;

    my $w = $o->wait_messageW($title, [ _("Please wait"), deref($message) ]);
    push @tempory::objects, $w if $temp;
    my $b = before_leaving { $o->wait_message_endW($w) };

    #- enable access through set
    common::add_f4before_leaving(sub { $o->wait_message_nextW([ deref($_[1]) ], $w) }, $b, 'set');
    $b;
}

sub kill {}

#-######################################################################################
#- Wonderful perl :(
#-######################################################################################
1;
