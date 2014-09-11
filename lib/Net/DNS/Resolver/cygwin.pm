package Net::DNS::Resolver::cygwin;

#
# $Id: cygwin.pm 1258 2014-09-04 12:23:18Z willem $
#
use vars qw($VERSION);
$VERSION = (qw$LastChangedRevision: 1258 $)[1];

=head1 NAME

Net::DNS::Resolver::cygwin - Cygwin Resolver Class

=cut


use strict;
use base qw(Net::DNS::Resolver::Base);


sub getregkey {
	my $key = join '/', @_;

	local *LM;
	open( LM, "<$key" ) or return '';
	my $value = <LM>;
	$value =~ s/\0+$// if $value;
	close(LM);

	return $value || '';
}


sub _untaint { map defined && /^(.+)$/ ? $1 : (), @_; }


sub init {
	my $defaults = shift->defaults;

	local *LM;

	my $root = '/proc/registry/HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Services/Tcpip/Parameters';

	unless ( -d $root ) {

		# Doesn't exist, maybe we are on 95/98/Me?
		$root = '/proc/registry/HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Services/VxD/MSTCP';
		-d $root || Carp::croak "can't read registry: $!";
	}

	# Best effort to find a useful domain name for the current host
	# if domain ends up blank, we're probably (?) not connected anywhere
	# a DNS server is interesting either...
	my $domain = getregkey( $root, 'Domain' ) || getregkey( $root, 'DhcpDomain' );

	# If nothing else, the searchlist should probably contain our own domain
	# also see below for domain name devolution if so configured
	# (also remove any duplicates later)
	my $devolution = getregkey( $root, 'UseDomainNameDevolution' );
	my $searchlist = getregkey( $root, 'SearchList' );
	my @searchlist = _untaint $domain;
	$defaults->domain(@searchlist);
	push @searchlist, split m/[\s,]+/, $searchlist;


	# This is (probably) adequate on NT4
	my @nt4nameservers;
	foreach ( grep length, getregkey( $root, 'NameServer' ), getregkey( $root, 'DhcpNameServer' ) ) {
		push @nt4nameservers, split;
		last;
	}


	# but on W2K/XP the registry layout is more advanced due to dynamically
	# appearing connections. So we attempt to handle them, too...
	# opt to silently fail if something isn't ok (maybe we're on NT4)
	# If this doesn't fail override any NT4 style result we found, as it
	# may be there but is not valid.
	# drop any duplicates later
	my @nameservers;

	my $dnsadapters = join '/', $root, 'DNSRegisteredAdapters';
	if ( opendir( LM, $dnsadapters ) ) {
		my @adapters = grep !/^\.\.?$/, readdir(LM);
		closedir(LM);
		foreach my $adapter (@adapters) {
			my $ns = getregkey( $dnsadapters, $adapter, 'DNSServerAddresses' );
			until ( length($ns) < 4 ) {
				push @nameservers, join '.', unpack( 'C4', $ns );
				substr( $ns, 0, 4 ) = '';
			}
		}
	}

	my $interfaces = join '/', $root, 'Interfaces';
	if ( opendir( LM, $interfaces ) ) {
		my @ifacelist = grep !/^\.\.?$/, readdir(LM);
		closedir(LM);
		foreach my $iface (@ifacelist) {
			my $ip = getregkey( $interfaces, $iface, 'DhcpIPAddress' )
					|| getregkey( $interfaces, $iface, 'IPAddress' );
			next unless $ip;
			next if $ip eq '0.0.0.0';

			foreach (
				grep length,
				getregkey( $interfaces, $iface, 'NameServer' ),
				getregkey( $interfaces, $iface, 'DhcpNameServer' )
				) {
				push @nameservers, split;
				last;
			}
		}
	}

	@nameservers = @nt4nameservers unless @nameservers;
	$defaults->nameservers( _untaint @nameservers );


	# fix devolution if configured, and simultaneously
	# make sure no dups (but keep the order)
	my @list;
	my %seen;
	foreach my $entry (@searchlist) {
		push @list, $entry unless $seen{$entry}++;

		next unless $devolution;

		# as long there are more than two pieces, cut
		while ( $entry =~ m#\..+\.# ) {
			$entry =~ s#^[^\.]+\.(.+)$#$1#;
			push @list, $entry unless $seen{$entry}++;
		}
	}
	$defaults->searchlist( _untaint @list );

	$defaults->read_env;
}


1;
__END__


=head1 SYNOPSIS

    use Net::DNS::Resolver;

=head1 DESCRIPTION

This class implements the OS specific portions of C<Net::DNS::Resolver>.

No user serviceable parts inside, see L<Net::DNS::Resolver|Net::DNS::Resolver>
for all your resolving needs.

=head1 COPYRIGHT

Copyright (c)1997-2002 Michael Fuhr.

Portions Copyright (c)2002-2004 Chris Reinhardt.

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Net::DNS>, L<Net::DNS::Resolver>

=cut
