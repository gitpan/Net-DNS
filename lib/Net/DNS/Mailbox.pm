package Net::DNS::Mailbox;
use base qw(Net::DNS::DomainName);

#
# $Id: Mailbox.pm 1006 2012-08-24 14:18:12Z willem $
#
use vars qw($VERSION);
$VERSION = (qw$LastChangedRevision: 1006 $)[1];


=head1 NAME

Net::DNS::Mailbox - DNS mailbox representation

=head1 SYNOPSIS

    use Net::DNS::Mailbox;

    $mailbox = new Net::DNS::Mailbox('user@example.com');
    $address = $mailbox->address;

=head1 DESCRIPTION

The Net::DNS::Mailbox module implements a subclass of DNS domain name
objects representing the DNS coded form of RFC822 mailbox address.

=cut


use strict;
use Carp;


=head1 METHODS

=head2 new

    $mailbox = new Net::DNS::Mailbox('John.Doe@example.com');
    $mailbox = new Net::DNS::Mailbox('John Doe <j.doe@example.com>');

Creates a mailbox object which represents the DNS domain encoded form
of the mail address specified by the character string argument.

The argument string consists of printable characters from the 7-bit
ASCII repertoire.

=cut

sub new {
	my $class = shift;
	local $_ = shift;
	confess 'undefined mail address' unless defined $_;

	s/^.*<//g;						# strip excess on left
	s/>.*$//g;						# strip excess on right

	s/\\\@/\\064/g;						# disguise escaped @
	s/^(".*)\@(.*")/$1\\064$2/g;				# disguise quoted @

	my ( $mbox, @host ) = split /\@/;			# split on @ if present
	$mbox ||= '';
	$mbox =~ s/^"(.*)"$/$1/;				# strip quotes
	$mbox =~ s/\\\./\\046/g;				# disguise escaped dot
	$mbox =~ s/\./\\046/g if @host;				# escape dots in local part

	bless __PACKAGE__->SUPER::new( join '.', $mbox, @host ), $class;
}


=head2 address

    $address = $mailbox->address;

Returns a character string containing the RFC822 mailbox address
corresponding to the encoded domain name representation described
in RFC1035 section 8.

=cut

sub address {
	my @label = shift->label;
	local $_ = shift(@label) || return '<>';
	s/\\\./\./g;						# unescape dots
	s/\\032/ /g;						# unescape space
	s/^(.+)$/"$1"/ if /[ ",@\[\\\]]/;			# quote local part
	return join '@', $_, join( '.', @label ) || ();
}


########################################

=head1 DOMAIN NAME COMPRESSION AND CANONICALISATION

The Net::DNS::Mailbox1035 and Net::DNS::Mailbox2535 subclass
packages implement RFC1035 domain name compression and RFC2535
canonicalisation.

=cut

package Net::DNS::Mailbox1035;
use base qw(Net::DNS::DomainName1035);

sub new { &Net::DNS::Mailbox::new; }

sub address { &Net::DNS::Mailbox::address; }


package Net::DNS::Mailbox2535;
use base qw(Net::DNS::DomainName2535);

sub new { &Net::DNS::Mailbox::new; }

sub address { &Net::DNS::Mailbox::address; }


1;
__END__


########################################

=head1 COPYRIGHT

Copyright (c)2009,2012 Dick Franks.

All rights reserved.

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<perl>, L<Net::DNS>, L<Net::DNS::DomainName>, RFC822, RFC1035, RFC5322

=cut

