package Net::DNS::RR::MR;

# $Id: MR.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my($newname) = Net::DNS::Packet::dn_expand($data, $offset);
	$self->{"newname"} = $newname;
	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return "$self->{newname}.";
}
1;
__END__

=head1 NAME

Net::DNS::RR::MR - DNS MR resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS Mail Rename (MR) resource records.

=head1 METHODS

=head2 newname

    print "newname = ", $rr->newname, "\n";

Returns the RR's new name field.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035 Section 3.3.8

=cut
