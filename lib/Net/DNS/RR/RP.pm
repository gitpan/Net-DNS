package Net::DNS::RR::RP;

# $Id: RP.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my ($mbox, $txtdname);
	($mbox, $offset) = Net::DNS::Packet::dn_expand($data, $offset);
	($txtdname, $offset) = Net::DNS::Packet::dn_expand($data, $offset);
	$self->{"mbox"} = $mbox;
	$self->{"txtdname"} = $txtdname;
	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return "$self->{mbox}. $self->{txtdname}.";
}
1;
__END__

=head1 NAME

Net::DNS::RR::RP - DNS RP resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS Responsible Person (RP) resource records.

=head1 METHODS

=head2 mbox

    print "mbox = ", $rr->mbox, "\n";

Returns a domain name that specifies the mailbox for the responsible person.

=head2 txtdname

    print "txtdname = ", $rr->txtdname, "\n";

Returns a domain name that specifies a TXT record containing further
information about the responsible person.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1183 Section 2.2

=cut
