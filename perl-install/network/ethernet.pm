package network::ethernet; # $Id$

use c;
use network::network;
use modules;
use modules::interactive;
use detect_devices;
use common;
use run_program;
use network::tools;
use vars qw(@ISA @EXPORT);

use MDK::Common::Globals "network", qw($in);

@ISA = qw(Exporter);
@EXPORT = qw(conf_network_card_backend);

# FIXME: unused code to merge in into wizard
sub ether_conf {
    my ($in, $netcnx, $netc, $intf) = @_;
    configureNetwork2($in, $::prefix, $netc, $intf);
    $netc->{NETWORKING} = "yes";
    if ($netc->{GATEWAY} || any { $_->{BOOTPROTO} =~ /dhcp/ } values %$intf) {
	$netcnx->{type} = 'lan';
	$netcnx->{NET_DEVICE} = $netc->{NET_DEVICE} = '';
	$netcnx->{NET_INTERFACE} = 'lan'; #$netc->{NET_INTERFACE};
        set_cnx_script($netc, "local network",
qq(
/etc/rc.d/init.d/network restart
),
qq(
/etc/rc.d/init.d/network stop
/sbin/ifup lo
), $netcnx->{type});
    }
    $::isStandalone and modules::write_conf();
    1;
}


sub mapIntfToDevice {
    my ($interface) = @_;
    my ($bus, $slot, $_func) = map { hex($_) } (c::getHwIDs($interface) =~ /([0-9a-f])+:([0-9a-f])+\.([0-9a-f]+)/);
    grep { $_->{pci_bus} == $bus && $_->{pci_device} == $slot } detect_devices::probeall();
}


# return list of [ intf_name, module, device_description ] tuples such as:
# [ "eth0", "3c59x", "3Com Corporation|3c905C-TX [Fast Etherlink]" ]
sub get_eth_cards() {
    my @all_cards = detect_devices::getNet();

    my @devs = detect_devices::pcmcia_probe();
    modules::mergein_conf("$::prefix/etc/modules.conf");
    my $saved_driver;
    return map {
        my $interface = $_;
        my $a = c::getNetDriver($interface) || modules::get_alias($interface);
        my $b = find { $_->{device} eq $interface } @devs;
        $a ||= $b->{driver};
        $a and $saved_driver = $a; # handle multiple cards managed by the same driver
        [ $interface, $saved_driver, (mapIntfToDevice($interface))[0]->{description} ]
    } @all_cards;
}


#- conf_network_card_backend : configure the network cards and return the list of them, or configure one specified interface : WARNING, you have to setup the ethernet cards, by calling load_category($in, 'network/main|gigabit|usb', !$::expert, 1) or load_category_backend before calling this function. Basically, you call this function in 2 times.
#- input
#-  $prefix
#-  $netc
#-  $intf
#-  $type : type of interface, must be given if $interface is : string : "static" or "dhcp"
#-  $interface : facultative, if given, set this interface and return it in a proper form. If not, return @all_cards
#-  $ipadr : facultative, ip address of the interface : string
#-  $netadr : facultative, netaddress of the interface : string
#- when $interface is given, informations are written in $intf and $netc. If not, @all_cards is returned.
#- $intf output: $device is the result of
#-  $intf->{$device}->{DEVICE} : which device is concerned : $device is the result of $interface =~ /(eth[0-9]+)/; my $device = $1;;
#-  $intf->{$device}->{BOOTPROTO} : $type
#-  $intf->{$device}->{NETMASK} : '255.255.255.0'
#-  $intf->{$device}->{NETWORK} : $netadr
#-  $intf->{$device}->{ONBOOT} : "yes"
#- $netc output:
#-  $netc->{NET_DEVICE} : this is used to indicate that this eth card is used to connect to internet : $device
#- output:
#-  $device : only returned in case $interface was given it's $interface, but filtered by /eth[0-9+]/ : string : /eth[0-9+]/
sub conf_network_card_backend {
    my ($netc, $intf, $type, $interface, $o_ipadr, $o_netadr) = @_;
    #-type =static or dhcp

    $interface =~ /eth[0-9]+/ or die("the interface is not an ethx");
    
    # FIXME: this is wrong regarding some wireless interfaces or/and if user play if ifname(1):
    $netc->{NET_DEVICE} = $interface; #- one consider that there is only ONE Internet connection device..
    
    @{$intf->{$interface}}{qw(DEVICE BOOTPROTO NETMASK NETWORK ONBOOT)} = ($interface, $type, '255.255.255.0', $o_netadr, 'yes');
    
    $intf->{$interface}{IPADDR} = $o_ipadr if $o_ipadr;
    $interface;
}

# automatic net aliases configuration
sub configure_eth_aliases() {
    foreach (detect_devices::getNet()) {
        my $driver = c::getNetDriver($_) or next;
        modules::add_alias($_, $driver);
    }
}

1;
