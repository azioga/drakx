package standalone; # $Id$

use c;
use strict;
use common qw(N N_ if_);
use Config;

#- for sanity (if a use standalone is made during install, MANY problems will happen)
require 'log.pm'; #- "require log" causes some pb, perl thinking that "log" is the log() function
if ($::isInstall) {
    log::l('ERROR: use standalone made during install :-(');
    log::l('backtrace: ' . backtrace());
}
$::isStandalone = 1;

$ENV{SHARE_PATH} ||= "/usr/share";

c::setlocale();
c::bindtextdomain('libDrakX', "/usr/share/locale");

$::license = N_("This program is free software; you can redistribute it and/or modify
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
");

my $progname = common::basename($0);

my %usages = (
           'diskdrake' => "[--{" . join(",", qw(hd nfs smb dav removable fileshare)) . "}]",
           'drakbackup' => N_("[--config-info] [--daemon] [--debug] [--default] [--show-conf]
Backup and Restore application

--default             : save default directories.
--debug               : show all debug messages.
--show-conf           : list of files or directories to backup.
--config-info         : explain configuration file options (for non-X users).
--daemon              : use daemon configuration. 
--help                : show this message.
--version             : show version number.
"),
           'drakbug' => N_("[OPTIONS] [PROGRAM_NAME]

OPTIONS:
  --help            - print this help message.
  --report          - program should be one of mandrake tools
  --incident        - program should be one of mandrake tools"),
           'drakfont' => N_("Font Importation and monitoring application                                     
--windows_import : import from all available windows partitions.
--xls_fonts      : show all fonts that already exist from xls
--strong         : strong verification of font.
--install        : accept any font file and any directry.
--uninstall      : uninstall any font or any directory of font.
--replace        : replace all font if already exist
--application    : 0 none application.
                 : 1 all application available supported.
                 : name_of_application like  so for staroffice 
                 : and gs for ghostscript for only this one."),
           'draksec' => "[--debug]
--debug: print debugging information",
           'drakTermServ' => N_("[OPTIONS]...
Mandrake Terminal Server Configurator
--enable         : enable MTS
--disable        : disable MTS
--start          : start MTS
--stop           : stop MTS
--adduser        : add an existing system user to MTS (requires username)
--deluser        : delete an existing system user from MTS (requires username)
--addclient      : add a client machine to MTS (requires MAC address, IP, nbi image name)
--delclient      : delete a client machine from MTS (requires MAC address, IP, nbi image name)"),
	      'drakxtv' => "[--no-guess]",
	      'drakupdate_fstab' => " [--add | --del] <device>\n",
	      'keyboardrake' => N_("[keyboard]"),
           'logdrake' => N_("[--file=myfile] [--word=myword] [--explain=regexp] [--alert]"),
           'net_monitor' => N_("[OPTIONS]
Network & Internet connection and monitoring application

--defaultintf interface : show this interface by default
--connect : connect to internet if not already connected
--disconnect : disconnect to internet if already connected
--force : used with (dis)connect : force (dis)connection.
--status : returns 1 if connected 0 otherwise, then exit.
--quiet : don't be interactive. To be used with (dis)connect."),
	      'printerdrake' => N_(" [--skiptest] [--cups] [--lprng] [--lpd] [--pdq]"),
	      'rpmdrake' => N_("[OPTION]...
  --no-confirmation      don't ask first confirmation question in MandrakeUpdate mode
  --no-verify-rpm        don't verify packages signatures
  --changelog-first      display changelog before filelist in the description window
  --merge-all-rpmnew     propose to merge all .rpmnew/.rpmsave files found"),
           'scannerdrake' => N_("[--manual] [--device=dev] [--update-sane=sane_source_dir] [--update-usbtable] [--dynamic=dev]"),
	      'XFdrake' => N_(" [everything]
       XFdrake [--noauto] monitor
       XFdrake resolution"),
	      );

$usages{$_} = $usages{rpmdrake} foreach qw(rpmdrake-remove MandrakeUpdate);
$usages{Xdrakres} = $usages{XFdrake};


my ($i, @new_ARGV);
foreach (@ARGV) {
    $i++;
    if (/^-(-help|h)$/) {
	version();
	print STDERR N("\nUsage: %s  [--auto] [--beginner] [--expert] [-h|--help] [--noauto] [--testing] [-v|--version] ", $progname),  if_($usages{$progname}, $usages{$progname}), "\n";
#    print N("\nUsage: "), $::usage, "\n" if $::usage;
	exit(0);
    } elsif (/^-(-version|v)$/) {
	version();
	exit(0);
    } elsif (/^--embedded$/) {
	$::XID = splice @ARGV, $i, 1;
	$::isEmbedded = 1;
    } elsif (/^--expert$/) {
	$::expert = 1;
    } elsif (/^--noauto$/) {
	$::noauto = /-noauto/;
    } elsif (/^--auto$/) {
	$::auto = 1;
    } elsif (/^--testing$/) {
	$::testing = 1;
    } elsif (/^--beginner$/) {
	$::expert = 0;
    } else {
	push @new_ARGV, $_;
    }
}

@ARGV = @new_ARGV;


sub version {
    print STDERR "Drakxtools version 9.1.0
Copyright (C) 1999-2002 MandrakeSoft by <install\@mandrakesoft.com>
",  $::license, "\n";
}

################################################################################
package pkgs_interactive;

use run_program;
use common;
require 'log.pm';

our @ISA = qw(); #- tell perl_checker this is a class

sub interactive::do_pkgs {
    my ($in) = @_;
    bless { in => $in }, 'pkgs_interactive';
}

sub install {
    my ($o, @l) = @_;

    return 1 if is_installed($o, @l);

    my $wait;
    if ($o->{in}->isa('interactive::newt')) {
	$o->{in}->suspend;
    } else {
	$wait = $o->{in}->wait_message('', N("Installing packages..."));
    }
    log::explanations("installed packages @l");
    my $ret = system('urpmi', '--allow-medium-change', '--auto', '--best-output', @l) == 0;

    if ($o->{in}->isa('interactive::newt')) {
	$o->{in}->resume;
    } else {
	undef $wait;
    }
    $ret;
}

sub ensure_is_installed {
    my ($o, $pkg, $file, $auto) = @_;

    if (! -e $file) {
	$o->{in}->ask_okcancel('', N("The package %s needs to be installed. Do you want to install it?", $pkg), 1) 
	  or return if !$auto;
	$o->{in}->do_pkgs->install($pkg);
    }
    if (! -e $file) {
	$o->{in}->ask_warn('', N("Mandatory package %s is missing", $pkg));
	return;
    }
    1;
}

sub check_kernel_module_packages {
    my ($do, $base_name, $ext_name) = @_;
    my $result;
    my (%list, %select);

    eval {
	local *_;
	require urpm;
	my $urpm = new urpm;
	$urpm->read_config(nocheck_access => 1);
	foreach (grep { !$_->{ignore} } @{$urpm->{media} || []}) {
	    $urpm->parse_synthesis("$urpm->{statedir}/synthesis.$_->{hdlist}");
	}
	foreach (@{$urpm->{depslist} || []}) {
	    $_->name eq $ext_name and $list{$_->name} = 1;
	    $_->name =~ /$base_name/ and $list{$_->name} = 1;
	}
	foreach (`rpm --qf '\%{NAME}\n' -qa`) {
	    chomp;
	    $_ eq $ext_name and $list{$_} = 0;
	    /$base_name/ and $list{$_} = 0;
	}
    };
    if (!$ext_name || exists $list{$ext_name}) {
	eval {
	    my ($version_release, $ext);
	    if (c::kernel_version() =~ /([^-]*)-([^-]*mdk)(\S*)/) {
		$version_release = "$1.$2";
		$ext = $3 ? "-$3" : "";
		exists $list{"$base_name$ext-$version_release"} or die "no $base_name for current kernel";
		$list{"$base_name$ext-$version_release"} and $select{"$base_name$ext-$version_release"} = 1;
	    } else {
		#- kernel version is not recognized, what to do ?
	    }
	    foreach (`rpm -qa`) {
		($ext, $version_release) = /kernel[^\-]*(-smp|-enterprise|-secure)?(?:-([^\-]+))$/;
		$list{"$base_name$ext-$version_release"} and $select{"$base_name$ext-$version_release"} = 1;
	    }
	    $result = [ keys(%select), if_($ext_name, $ext_name) ];
	}
    }
    return $result;
}

sub what_provides {
    my ($_o, $name) = @_;
    my ($what) = split '\n', `urpmq '$name' 2>/dev/null`;
    split '\|', $what;
}

sub is_installed {
    my ($_o, @l) = @_;
    run_program::run('/bin/rpm', '>', '/dev/null', '-q', @l);
}

sub are_installed {
    my ($_o, @l) = @_;
    my @l2;
    run_program::run('/bin/rpm', '>', \@l2, '-q', '--qf', "%{name}\n", @l);
    intersection(\@l, [ map { chomp_($_) } @l2 ]);
}

sub remove {
    my ($o, @l) = @_;
    $o->{in}->suspend;
    log::explanations("removed packages @l");
    my $ret = system('rpm', '-e', @l) == 0;
    $o->{in}->resume;
    $ret;
}

sub remove_nodeps {
    my ($o, @l) = @_;
    $o->{in}->suspend;
    log::explanations("removed (with --nodeps) packages @l");
    my $ret = system('rpm', '-e', '--nodeps', @l) == 0;
    $o->{in}->resume;
    $ret;
}

################################################################################


package standalone;

#- stuff will go to special /var/log/explanations file
my $standalone_name;
sub explanations { log::explanations("@_") }

our @common_functs = qw(renamef linkf symlinkf output substInFile mkdir_p rm_rf cp_af touch setVarsInSh setExportedVarsInSh setExportedVarsInCsh update_gnomekderc);
our @builtin_functs = qw(chmod chown unlink link symlink rename system);
our @drakx_modules = qw(Xconfig::card Xconfig::default Xconfig::main Xconfig::monitor Xconfig::parse Xconfig::proprietary Xconfig::resolution_and_depth Xconfig::screen Xconfig::test Xconfig::various Xconfig::xfree Xconfig::xfree3 Xconfig::xfree4 Xconfig::xfreeX any bootloader bootlook c class_discard commands crypto detect_devices devices diskdrake diskdrake::hd_gtk diskdrake::interactive diskdrake::removable diskdrake::removable_gtk diskdrake::smbnfs_gtk fs fsedit http keyboard lang log loopback lvm modules::parameters modules mouse my_gtk network network::adsl network::ethernet network::isdn_consts network::isdn network::modem network::netconnect network::network network::nfs network::smb network::tools partition_table partition_table_bsd partition_table::dos partition_table::empty partition_table::gpt partition_table::mac partition_table::raw partition_table::sun printer printerdrake proxy raid run_program scanner services steps swap timezone network::drakfirewall network::shorewall);

$SIG{SEGV} = sub { my $progname = $0; $progname =~ s|.*/||; exec("drakbug --incident $progname") };

sub import {
    ($standalone_name = $0) =~ s|.*/||;
    c::openlog($standalone_name."[$$]");
    explanations('### Program is starting ###');

    eval "*MDK::Common::$_ = *$_" foreach @common_functs;

    foreach my $f (@builtin_functs) {
	eval "*$_"."::$f = *$f" foreach @drakx_modules;
	eval "*".caller()."::$f = *$f";
    }
}


sub renamef {
    explanations "moved file $_[0] to $_[1]";
    goto &MDK::Common::File::renamef;
}

sub linkf {
    explanations "hard linked file $_[0] to $_[1]";
    goto &MDK::Common::File::linkf;
}

sub symlinkf {
    explanations "symlinked file $_[0] to $_[1]";
    goto &MDK::Common::File::symlinkf;
}

sub output {
    explanations "created file $_[0]";
    goto &MDK::Common::File::output;
}

sub substInFile(&@) {
    explanations "modified file $_[1]";
    goto &MDK::Common::File::substInFile;
}

sub mkdir_p {
    explanations "created directory $_[0] (and parents if necessary)";
    goto &MDK::Common::File::mkdir_p;
}

sub rm_rf {
    explanations "removed files/directories (recursively) @_";
    goto &MDK::Common::File::rm_rf;
}

sub cp_af {
    my $retval = MDK::Common::File::cp_af(@_);
    my $dest = pop @_;
    explanations "copied recursively @_ to $dest";
    return $retval;
}

sub touch {
    explanations "touched file @_";
    goto &MDK::Common::File::touch;
}

sub setVarsInSh {
    explanations "modified file $_[0]";
    goto &MDK::Common::System::setVarsInSh;
}

sub setExportedVarsInSh {
    explanations "modified file $_[0]";
    goto &MDK::Common::System::setExportedVarsInSh;
}

sub setExportedVarsInCsh {
    explanations "modified file $_[0]";
    goto &MDK::Common::System::setExportedVarsInCsh;
}

sub update_gnomekderc {
    explanations "modified file $_[0]";
    goto &MDK::Common::System::update_gnomekderc;
}


sub chmod {
    my $retval = CORE::chmod(@_);
    my $mode = shift @_;
    explanations sprintf("changed mode of %s to %o", $_, $mode) foreach @_;
    return $retval;
}

sub chown {
    my $retval = CORE::chown(@_);
    my $uid = shift @_;
    my $gid = shift @_;
    explanations sprintf("changed owner of $_ to $uid.$gid") foreach @_;
    return $retval;
}

sub unlink {
    explanations "removed files/directories @_";
    CORE::unlink(@_);
}

sub link {
    explanations "hard linked file $_[0] to $_[1]";
    CORE::link($_[0], $_[1]);
}

sub symlink {
    explanations "symlinked file $_[0] to $_[1]";
    CORE::symlink($_[0], $_[1]);
}

sub rename {
    explanations "renamed file $_[0] to $_[1]";
    CORE::rename($_[0], $_[1]);
}

sub system {
    explanations "launched command: @_";
    CORE::system(@_);
}

1;
