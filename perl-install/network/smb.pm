package network::smb; # $Id$

use strict;
use diagnostics;

use common;
use fs;
use network::network;
use network::smbnfs;


our @ISA = 'network::smbnfs';

sub to_fstab_entry {
    my ($class, $e) = @_;
    my $part = $class->to_fstab_entry_raw($e, 'smbfs');
    if ($e->{server}{username}) {
	my ($options, $unknown) = fs::mount_options_unpack($part);
	$options->{"$_="} = $e->{server}{$_} foreach qw(username password domain);
	fs::mount_options_pack($part, $options, $unknown);
    }
    $part;
}
sub from_dev { 
    my ($class, $dev) = @_;
    $dev =~ m|//(.*?)/(.*)|;
}
sub to_dev_raw {
    my ($class, $server, $name) = @_;
    '//' . $server . '/' . $name;
}

sub check {
    my ($class, $in) = @_;
    $class->raw_check($in, 'samba-client', '/usr/bin/nmblookup');
}

sub smbclient {
    my ($server) = @_;
    my $name  = $server->{name} || $server->{ip};
    my $ip    = $server->{ip} ? "-I $server->{ip}" : '';
    my $group = $server->{group} ? " -W $server->{group}" : '';

    my $U = $server->{username} ? sprintf("%s/%s%%%s", @$server{'domain', 'username', 'password'}) : '%';
    `smbclient -U $U -L $name $ip$group`;
}

sub find_servers {
    my (undef, @l) = `nmblookup "*"`;
    s/\s.*\n// foreach @l;
    my @servers = grep { network::network::is_ip($_) } @l;
    my %servers;
    $servers{$_}{ip} = $_ foreach @servers;
    my ($ip, $browse);
    foreach (`nmblookup -A @servers`) {
	my $nb = /^Looking up status of (\S+)/ .. /^$/ or next;
	if ($nb == 1) {
	    $ip = $1;
	} elsif (/<00>/) {
	    $servers{$ip}{/<GROUP>/ ? 'group' : 'name'} ||= lc first(/(\S+)/);
	} elsif (/__MSBROWSE__/) {
	    $browse ||= $servers{$ip};
	}
    }
    if ($browse) {
	my %l;
	foreach (smbclient($browse)) {
	    my $nb = /^\s*Workgroup/ .. /^$/;
	    $nb > 2 or next;
	    my ($group, $name) = split(' ', lc($_));

	    # already done
	    next if grep { $group eq $_->{group} } values %servers;

	    $l{$name} = $group;
	}
	if (my @l = keys %l) {
	    foreach (`nmblookup @l`) {
		$servers{$1} = { name => $2, group => $l{$2} } if /(\S+)\s+([^<]+)<00>/;
	    }
	}
    }
    values %servers;
}

sub find_exports {
    my ($class, $server) = @_;
    my @l;

    foreach (smbclient($server)) {
	chomp;
	s/^\t//;
	/NT_STATUS_/ and die $_;
	my ($name, $type, $comment) = unpack "A15 A10 A*", $_;
	if ($name eq '---------' && $type eq '----' && $comment eq '-------' .. /^$/) {
	    push @l, { name => $name, type => $type, comment => $comment, server => $server }
	      if $type eq 'Disk' && $name !~ /\$$/ && $name !~ /NETLOGON|SYSVOL/;
	}
    }
    @l;
}

sub authentifications_available {
    my ($server) = @_;
    map { if_(/^auth.\Q$server->{name}.\E(.*)/, $1) } all("/etc/samba");
}

sub to_credentials {
    my ($server_name, $username) = @_;
    $username or die 'to_credentials';
    "/etc/samba/auth.$server_name.$username";
}

sub fstab_entry_to_credentials {
    my ($part) = @_;    

    my ($server_name) = network::smb->from_dev($part->{device}) or return;

    my ($options, $unknown) = fs::mount_options_unpack($part);
    $options->{'username='} && $options->{'password='} or return;
    my %h = map { $_ => delete $options->{"$_="} } qw(username domain password);
    $h{file} = $options->{'credentials='} = to_credentials($server_name, $h{username});
    fs::mount_options_pack_($part, $options, $unknown), \%h;
}

sub remove_bad_credentials {
    my ($server) = @_;
    unlink to_credentials($server->{name}, $server->{username});
}

sub save_credentials {
    my ($credentials) = @_;
    my $file = $credentials->{file};
    output_p("$::prefix$file", map { "$_ = $credentials->{$_}\n" } qw(username domain password));
    chmod(0640, "$::prefix$file");
}


sub read_credentials_raw {
    my ($file) = @_;
    my %h = map { /(.*?)\s*=\s*(.*)/ } cat_("$::prefix$file");
    \%h;
}

sub read_credentials {
    my ($server, $username) = @_;
    put_in_hash($server, read_credentials_raw(to_credentials($server->{name}, $username)));
}

1;
