package network::tools;

use common;
use run_program;
use c;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use MDK::Common::Globals "network", qw($in $prefix $disconnect_file $connect_prog $connect_file);
use MDK::Common::System qw(getVarsFromSh);

@ISA = qw(Exporter);
@EXPORT = qw(write_cnx_script write_secret_backend write_initscript ask_connect_now connect_backend disconnect_backend read_providers_backend ask_info2 type2interface connected connected_bg test_connected connected2 disconnected);
@EXPORT_OK = qw($in);

sub write_cnx_script {
    my ($netc, $type, $up, $down, $type2) = @_;
    if ($type) {
	$netc->{internet_cnx}{$type}{$_->[0]} = $_->[1] foreach [$connect_file, $up], [$disconnect_file, $down];
	$netc->{internet_cnx}{$type}{type} = $type2;
    } else {
	foreach ($connect_file, $disconnect_file) {
	    output_with_perm("$prefix$_", 0755,
'#!/bin/bash
' . if_(!$netc->{at_boot}, 'if [ "x$1" == "x--boot_time" ]; then exit; fi
') . $netc->{internet_cnx}{$netc->{internet_cnx_choice}}{$_});
	}
    }
}

sub write_secret_backend {
    my ($a, $b) = @_;
    foreach my $i ("pap-secrets", "chap-secrets") {
	substInFile { s/^'$a'.*\n//; $_ .= "\n'$a' * '$b' * \n" if eof  } "$prefix/etc/ppp/$i";
    }
}

sub read_secret_backend {
    my $conf;
    foreach my $i ("pap-secrets", "chap-secrets") {
	foreach (cat_("$prefix/etc/ppp/$i")) {
	    my ($login, $server, $passwd) = split(' ');
	    my ($a, $b, $c) = $passwd =~ /"(.*)"|'(.*)'|(.*)/;
	    $passwd = $a ? $a : $b ? $b : $c;
	    push @$conf, {login => $login,
			  passwd => $passwd,
			  server => $server };
	}
    }
    $conf;
}


sub ask_connect_now {
    my ($type) = @_;
    $::Wizard_no_previous = 1;
    my $up;
    #- FIXME : code the exception to be generated by ask_yesorno, to be able to remove the $::Wizard_no_previous=1;
    if ($in->ask_yesorno(N("Internet configuration"),
			 N("Do you want to try to connect to the Internet now?")
			)) {
	{
	    my $_w = $in->wait_message('', N("Testing your connection..."), 1);
	    connect_backend();
	    my $s = 30;
	    $type =~ /modem/ and $s = 50;
	    $type =~ /adsl/ and $s = 35;
	    $type =~ /isdn/ and $s = 20;
	    sleep $s;
	    $up = connected();
	}
	my $m = $up ? N("The system is now connected to Internet.") .
		     if_($::isInstall, N("For security reason, it will be disconnected now.")) :
		       N("The system doesn't seem to be connected to internet.
Try to reconfigure your connection.");
	if ($::isWizard) {
	    $::Wizard_no_previous = 1;
	    $::Wizard_finished = 1;
	    $in->ask_okcancel(N("Network Configuration"), $m, 1);
	    undef $::Wizard_no_previous;
	    undef $::Wizard_finished;
	} else {  $in->ask_warn('', $m) }
	$::isInstall and disconnect_backend();
    }
    undef $::Wizard_no_previous;
    $up;
}

sub connect_backend { run_program::rooted($prefix, "$connect_prog &") }

sub disconnect_backend { run_program::rooted($prefix, "$disconnect_file &") }

sub read_providers_backend { my ($file) = @_; map { /(.*?)=>/ } catMaybeCompressed($file) }

sub ask_info2 {
    my ($cnx, $netc) = @_;
    $::isInstall and $in->set_help('configureNetworkDNS');
    $in->ask_from(N("Connection Configuration"),
		  N("Please fill or check the field below"),
		  [
		   if__($cnx->{irq}, { label => N("Card IRQ"), val => \$cnx->{irq} }),
		   if__($cnx->{mem}, { label => N("Card mem (DMA)"), val => \$cnx->{mem} }),
		   if__($cnx->{io}, { label => N("Card IO"), val => \$cnx->{io} }),
		   if__($cnx->{io0}, { label => N("Card IO_0"), val => \$cnx->{io0} }),
		   if__($cnx->{io1}, { label => N("Card IO_1"), val => \$cnx->{io1} }),
		   if__($cnx->{phone_in}, { label => N("Your personal phone number"), val => \$cnx->{phone_in} }),
		   if__($netc->{DOMAINNAME2}, { label => N("Provider name (ex provider.net)"), val => \$netc->{DOMAINNAME2} }),
		   if__($cnx->{phone_out}, { label => N("Provider phone number"), val => \$cnx->{phone_out} }),
		   if__($netc->{dnsServer2}, { label => N("Provider dns 1 (optional)"), val => \$netc->{dnsServer2} }),
		   if__($netc->{dnsServer3}, { label => N("Provider dns 2 (optional)"), val => \$netc->{dnsServer3} }),
		   if__($cnx->{vpivci}, { label => N("Choose your country"), val => \$netc->{vpivci}, list => detect_timezone() }),
		   if__($cnx->{dialing_mode}, { label => N("Dialing mode"), val => \$cnx->{dialing_mode},list => ["auto", "manual"] }),
		   if__($cnx->{speed}, { label => N("Connection speed"), val => \$cnx->{speed}, list => ["64 Kb/s", "128 Kb/s"] }),
		   if__($cnx->{huptimeout}, { label => N("Connection timeout (in sec)"), val => \$cnx->{huptimeout} }),
		   if__($cnx->{login}, { label => N("Account Login (user name)"), val => \$cnx->{login} }),
		   if__($cnx->{passwd}, { label => N("Account Password"),  val => \$cnx->{passwd}, hidden => 1 }),
		  ]
		 ) or return;
    if ($netc->{vpivci}) {
	foreach ([N("Netherlands"), '8_48'], [N("France"), '8_35'], [N("Belgium"), '8_35'], [N("Italy"), '8_35'], [N("United Kingdom"), '0_38'], [N("United States"), '8_35']) {
	    $netc->{vpivci} eq $_->[0] and $netc->{vpivci} = $_->[1];
	}
    }
    1;
}

sub detect_timezone {
    my %tmz2country = ( 
		       'Europe/Paris' => N("France"),
		       'Europe/Amsterdam' => N("Netherlands"),
		       'Europe/Rome' => N("Italy"),
		       'Europe/Brussels' => N("Belgium"), 
		       'America/New_York' => N("United States"),
		       'Europe/London' => N("United Kingdom") 
		      );
    my %tm_parse = MDK::Common::System::getVarsFromSh('/etc/sysconfig/clock');
    my @country;
    foreach (keys %tmz2country) {
	if ($_ eq $tm_parse{ZONE}) {
	    unshift @country, $tmz2country{$_};
	} else { push @country, $tmz2country{$_} };
    }
    \@country;
}

sub type2interface {
    my ($i) = @_;
    $i =~ /$_->[0]/ and return $_->[1] foreach [ modem => 'ppp' ],
					     [ isdn_internal => 'ippp' ],
					     [ isdn_external => 'ppp' ],
					     [ adsl => 'ppp' ],
					     [ cable => 'eth' ],
					     [ lan => 'eth' ];
}

sub connected { gethostbyname("mandrakesoft.com") ? 1 : 0 }

my $kid_pipe;
sub connected_bg {
    local $| = 1;
    my ($ref) = @_;
    if (defined $kid_pipe) {
	fcntl($kid_pipe, c::F_SETFL(), c::O_NONBLOCK()) or die "can't fcntl F_SETFL: $!";
	my $a;
  	if (defined($a = <$kid_pipe>)) {
	    close($kid_pipe) || warn "kid exited $?";
	    undef $kid_pipe;
	    $$ref = $a;
  	}
    } else { $kid_pipe = connected2() }
    1;
}

# test if connected;
# cmd = 0 : ask current status
#     return : 0 : not connected; 1 : connected; -1 : no test ever done; -2 : test in progress
# cmd = 1 : start new connection test
#     return : -2
# cmd = 2 : cancel current test
#    return : nothing
# cmd = 3 : return current status even if a test is in progress
my $kid_pipe_connect;
my $kid_pid;
my $current_connection_status;

sub test_connected {
    local $| = 1;
    my ($cmd) = @_;

    if (!defined $current_connection_status) { $current_connection_status = -1 }

    if ($cmd == 0) {
        if (defined $kid_pipe_connect) {
	    fcntl($kid_pipe_connect, c::F_SETFL(), c::O_NONBLOCK()) or die "can't fcntl F_SETFL: $!";
	    my $a;
	    if (defined($a = <$kid_pipe_connect>)) {
		close($kid_pipe_connect) || warn "kid exited $?";
		undef $kid_pipe_connect;
		undef $kid_pid;
		$current_connection_status = $a;
	    }
        }
	return $current_connection_status;
    }

    if ($cmd == 1) {
        if ($current_connection_status != -2) {
             $current_connection_status = -2;
             $kid_pipe_connect = connected2();
        }
    }
    if ($cmd == 2) {
        if (defined($kid_pid)) {
	    kill -9, $kid_pid;
	    undef $kid_pid;
        }
    }
    return $current_connection_status;
}

sub connected2 {
    if ($kid_pid = open(my $kid_to_read, "-|")) {
	#- parent
	$kid_to_read;
    } else {      
	#- child
	my $a = gethostbyname("mandrakesoft.com") ? 1 : 0;
	print $a;
	c::_exit(0);
    }
}

sub disconnected {}


sub write_initscript {
    $::testing and return;
    output_with_perm("$prefix/etc/rc.d/init.d/internet", 0755,
		     sprintf(<<'EOF', $connect_file, $connect_file, $disconnect_file, $disconnect_file));
#!/bin/bash
#
# internet       Bring up/down internet connection
#
# chkconfig: 2345 11 89
# description: Activates/Deactivates the internet interfaces
#
# dam's (damien@mandrakesoft.com)

# Source function library.
. /etc/rc.d/init.d/functions

	case "$1" in
		start)
                if [ -e %s ]; then
			action "Checking internet connections to start at boot" "%s --boot_time"
		else
			action "No connection to start" "true"
		fi
		touch /var/lock/subsys/internet
		;;
	stop)
                if [ -e %s ]; then
			action "Stopping internet connection if needed: " "%s --boot_time"
		else
			action "No connection to stop" "true"
		fi
		rm -f /var/lock/subsys/internet
		;;
	restart)
		$0 stop
		echo "Waiting 10 sec before restarting the internet connection."
		sleep 10
		$0 start
		;;
	status)
		;;
	*)
	echo "Usage: internet {start|stop|status|restart}"
	exit 1
esac
exit 0
EOF
    $::isStandalone ? system("/sbin/chkconfig --add internet") : do {
	symlinkf("../init.d/internet", "$prefix/etc/rc.d/rc$_") foreach
	  '0.d/K11internet', '1.d/K11internet', '2.d/K11internet', '3.d/S89internet', '5.d/S89internet', '6.d/K11internet';
    };
}

1;
