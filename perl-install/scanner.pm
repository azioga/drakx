#!/usr/bin/perl

# scanner.pm $Id$
# Yves Duret <yduret at mandrakesoft.com>
# Copyright (C) 2001 MandrakeSoft
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
#
# pbs/TODO:
# - no scsi support
# - devfs use dev_is_devfs()
# - with 2 scanners same manufacturer -> will overwrite previous conf -> only 1 conf !!
# - lp: see printerdrake
# - install: prefix --> done

package scanner;
use lib qw(/usr/lib/libDrakX);
use standalone;
use common;
use detect_devices;


my $_sanedir = "$prefix/etc/sane.d";
my $_scannerDBdir = "$prefix$ENV{SHARE_PATH}/ldetect-lst";
$scannerDB = readScannerDB("$_scannerDBdir/ScannerDB");

sub confScanner {
    my ($model, $port) = @_;
    $port = detect_devices::dev_is_devfs() ? "$prefix/dev/usb/scanner0" : "$prefix/dev/scanner" if (!$port);
    my $a = $scannerDB->{$model}{server};
    output("$_sanedir/$a.conf", (join "\n",@{$scannerDB->{$model}{lines}}));
    substInFile {s/\$DEVICE/$port/} "$_sanedir/$a.conf";
    add2dll($a);
}

sub add2dll {
    return if member($_[0], chomp_(cat_("$_sanedir/dll.conf")));
    local *F;
    open F, ">>$_sanedir/dll.conf" or die "can't write SANE config in $_sanedir/dll.conf: $!";
    print F $_[0];
    close F;
}

sub findScannerUsbport {
    my ($i, $elem, @res) = (0, {});
    foreach (grep { $_->{driver} =~ /scanner/ } detect_devices::usb_probe()) {
	#my ($manufacturer, $model) = split '\|', $_->{description};
	#$_->{description} =~ s/Hewlett[-\s_]Packard/HP/;
	push @res, { port => "/dev/usb/scanner$i", val => { #CLASS => 'SCANNER',
							    #MODEL => $model,
							    #MANUFACTURER => $manufacturer,
							    DESCRIPTION => $_->{description},
							    #id => $_->{id},
							    #vendor => $_->{vendor},
							  }};
	++$i;
    }
    @res;
}

sub readScannerDB {
    my ($file) = @_;
    my ($card, %cards);

    my $F = common::openFileMaybeCompressed($file);

    my ($lineno, $cmd, $val) = 0;
    my $fs = {
        LINE => sub { push @{$card->{lines}}, $val },
	NAME => sub {
	    $cards{$card->{type}} = $card if $card;
	    $card = { type => $val };
	},
	SEE => sub {
	    my $c = $cards{$val} or die "Error in database, invalid reference $val at line $lineno";

	    push @{$card->{lines}}, @{$c->{lines} || []};
	    add2hash($card->{flags}, $c->{flags});
	    add2hash($card, $c);
	},
	SERVER => sub { $card->{server} = $val; },
	DRIVER => sub { $card->{driver} = $val; },
	UNSUPPORTED => sub { $card->{flags}{unsupported} = 1 },
	COMMENT => sub {},
    };

    local $_;
    while (<$F>) { $lineno++;
	s/\s+$//;
	/^#/ and next;
	/^$/ and next;
	/^END/ and do { $cards{$card->{type}} = $card if $card; last };
	($cmd, $val) = /(\S+)\s*(.*)/ or next; #log::l("bad line $lineno ($_)"), next;
	my $f = $fs->{$cmd};
	$f ? $f->() : log::l("unknown line $lineno ($_)");
    }
    \%cards;
}

sub updateScannerDBfromUsbtable {
    substInFile {s/END//} "ScannerDB";
    local *F;
    open F, ">>ScannerDB" or die "can't write ScannerDB config in ScannerDB: $!";
    print F "# generated from usbtable by scannerdrake\n";
    foreach (cat_("$ENV{SHARE_PATH}/ldetect-lst/usbtable")) {
	my ($vendor_id, $product_id, $mod, $name) = chomp_(split /\s/,$_,4);
	next unless ($mod eq "\"scanner\"");
	$name =~ s/\"(.*)\"$/$1/;
	if (member($name, keys %$scanner::scannerDB)) {
	    print "$name already in ScannerDB\n";
	    next;
	}
	print F "NAME $name\nDRIVER usb\nCOMMENT usb $vendor_id $product_id\nUNSUPPORTED\n\n";
    }
    print F "END\n";
    close F;
}

sub updateScannerDBfromSane {
    my ($_sanesrcdir) = @_;
    substInFile {s/END//} "ScannerDB";

    local *Y;
    open Y, ">>ScannerDB" or die "can't write ScannerDB config in ScannerDB: $!";
    print Y "# generated from Sane by scannerdrake\n";
    # for compat with our usbtable
    my $sane2DB = { 
		   "Acer" => "Acer Peripherals Inc.",
		   "AGFA" => "AGFA-Gevaert NV",
		   "Agfa" => "AGFA-Gevaert NV",
		   "Epson" => "Seiko Epson Corp.",
		   "Fujitsu Computer Products of America" => "Fujitsu",
		   "HP" => sub {$_[0] =~ s/HP\s/Hewlett-Packard|/; $_[0] =~ s/HP4200/Hewlett-Packard|ScanJet 4200C/; $_[0];},
		   "Hewlett-Packard" => sub {$_[0] =~ s/HP 3200 C/Hewlett-Packard|ScanJet 3200C/; $_[0];},
		   "Kodak" => "Kodak Co.",
		   "Mustek" => "Mustek Systems Inc.",
		   "NEC" => "NEC Systems",
		   "Nikon" => "Nikon Corp.",
		   "Plustek" => "Plustek, Inc.",
		   "Primax" => "Primax Electronics",
		   "Siemens" => "Siemens Information and Communication Products",
		   "Trust" => "Trust Technologies",
		   "UMAX" => "Umax",
		   "Vobis/Highscreen" => "Vobis",
		  };
    
    opendir YREP, $_sanesrcdir or die "can't open $_sanesrcdir: $!";
    @files = grep /.*desc$/, readdir YREP;
    closedir YREP;
    foreach $i (@files) {
	my $F = common::openFileMaybeCompressed("$_sanesrcdir/$i");
	print Y "\n# from $i";
	my ($lineno, $cmd, $val) = 0;
	my ($name, $intf, $comment,$mfg);
	my $fs = {
		  backend => sub {$backend = $val;},
		  mfg => sub {$mfg = $val; $name=undef;},#bug when a new mfg comes. should called $fs->{$name}(); but ??
		  model => sub {
		      unless ($name) {$name = $val; next;}
		      $name = (member($mfg, keys %$sane2DB))
			? (ref $sane2DB->{$mfg}) ? $sane2DB->{$mfg}($name) : "$sane2DB->{$mfg}|$name" : "$mfg|$name";
		      if (member($name, keys %$scanner::scannerDB)) {
			  print "#![$name] already in ScannerDB !\n";
		      } else {
			  print Y "\nNAME $name\nSERVER $backend\nDRIVER $intf\n";
			  print Y "COMMENT $comment\n" if ($comment);
			  $comment = undef; 
		      }
		      #print "#-----------------------------------------------------------------------------\n";
		      $name = $val;
		  },
		  interface => sub {$intf = $val;},
		  comment => sub {$comment = $val;},
		 };
	local $_;
	while (<$F>) { $lineno++;
		       s/\s+$//;
		       /^\;/ and next;
		       ($cmd, $val) = /:(\S+)\s*\"([^\;]*)\"/ or next; #log::l("bad line $lineno ($_)"), next;
		       my $f = $fs->{$cmd};
		       $f ? $f->() : log::l("unknown line $lineno ($_)");
		   }
	$fs->{model}(); # the last one
    }
    print Y "\nEND\n";
    close Y;
}

#-######################################################################################
#- Wonderful perl :(
#-######################################################################################
1; #

#-----------------------------------------------
# $Log$
# Revision 1.3  2001/11/12 15:18:02  yduret
# update, sync with cvs
#
