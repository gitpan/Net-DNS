# $Id: 03-question.t 931 2011-10-25 12:10:56Z willem $	-*-perl-*-

use strict;
use diagnostics;
use Test::More;


BEGIN {
	use Net::DNS;

	plan tests => 98 + keys(%Net::DNS::classesbyname) + keys(%Net::DNS::typesbyname);
}


{	# check type conversion functions
	my ($anon) = grep { not defined $Net::DNS::typesbyval{$_} } ( 1  .. 1 << 16 );

	is( Net::DNS::typesbyval(1),		 'A',	      "Net::DNS::typesbyval(1)" );
	is( Net::DNS::typesbyval($anon),	 "TYPE$anon", "Net::DNS::typesbyval($anon)" );
	is( Net::DNS::typesbyname("TYPE$anon"),	 $anon,	      "Net::DNS::typesbyname('TYPE$anon')" );
	is( Net::DNS::typesbyname("TYPE0$anon"), $anon,	      "Net::DNS::typesbyname('TYPE0$anon')" );

	my $large = 1 << 16;
	eval { Net::DNS::typesbyval($large); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "Net::DNS::typesbyval($large)\t[$exception]" );

	foreach ( sort keys %Net::DNS::typesbyname ) {
		my $code      = Net::DNS::typesbyname($_);
		my $name      = eval { Net::DNS::typesbyval($code) };
		my $exception = $@ =~ /^(.+)\n/ ? $1 : '';
		is( $name, $_, "Net::DNS::typesbyname('$_')\t$exception" );
	}
}


{	# check class conversion functions
	my ($anon) = grep { not defined $Net::DNS::classesbyval{$_} } ( 1  .. 1 << 16 );

	is( Net::DNS::classesbyval(1),		    'IN',	  "Net::DNS::classesbyval(1)" );
	is( Net::DNS::classesbyval($anon),	    "CLASS$anon", "Net::DNS::classesbyval($anon)" );
	is( Net::DNS::classesbyname("CLASS$anon"),  $anon,	  "Net::DNS::classesbyname('CLASS$anon')" );
	is( Net::DNS::classesbyname("CLASS0$anon"), $anon,	  "Net::DNS::classesbyname('CLASS0$anon')" );

	my $large = 1 << 16;
	eval { Net::DNS::classesbyval($large); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "Net::DNS::classesbyval($large)\t[$exception]" );

	foreach ( sort keys %Net::DNS::classesbyname ) {
		my $code      = Net::DNS::classesbyname($_);
		my $name      = eval { Net::DNS::classesbyval($code) };
		my $exception = $@ =~ /^(.+)\n/ ? $1 : '';
		is( $name, $_, "Net::DNS::classesbyname('$_')\t$exception" );
	}
}


{
	my $fqdn = 'example.com.';
	my $question = new Net::DNS::Question( $fqdn, 'A', 'IN' );
	isa_ok( $question, 'Net::DNS::Question', 'object returned by new() constructor' );

	my $string   = $question->string;
	my $expected = "$fqdn\tIN\tA";
	is( $string, $expected, '$question->string returns text representation of object' );

	my $test = 'new() argument undefined or absent';
	is( new Net::DNS::Question( $fqdn, 'A',   undef )->string, $expected, "$test\t( $fqdn,\tA,\tundef\t)" );
	is( new Net::DNS::Question( $fqdn, 'A',   ()    )->string, $expected, "$test\t( $fqdn,\tA,\t\t)" );
	is( new Net::DNS::Question( $fqdn, undef, 'IN'  )->string, $expected, "$test\t( $fqdn,\tundef,\tIN\t)" );
	is( new Net::DNS::Question( $fqdn, (),    'IN'  )->string, $expected, "$test\t( $fqdn,\t\tIN\t)" );
	is( new Net::DNS::Question( $fqdn, undef, undef )->string, $expected, "$test\t( $fqdn,\tundef,\tundef\t)" );
	is( new Net::DNS::Question( $fqdn, (),    ()    )->string, $expected, "$test\t( $fqdn \t\t\t)" );
}


{
	my $test = 'new() arguments in zone file order';
	my $fqdn = 'example.com.';
	foreach my $class (qw(IN CLASS1 ANY)) {
		foreach my $type (qw(A TYPE1 ANY)) {
			my $testcase = new Net::DNS::Question( $fqdn, $class, $type )->string;
			my $expected = new Net::DNS::Question( $fqdn, $type,  $class )->string;
			is( $testcase, $expected, "$test\t( $fqdn,\t$class,\t$type\t)" );
		}
	}
}


{
	my $packet     = new Net::DNS::Packet('example.com');
	my $encoded    = $packet->data;
	my ($question) = new Net::DNS::Packet( \$encoded )->question;
	isa_ok( $question, 'Net::DNS::Question', 'check decoded object' );
}


{
	my $test = 'decoded object matches encoded data';
	foreach my $class (qw(IN HS ANY)) {
		foreach my $type (qw(A AAAA MX NS SOA ANY)) {
			my $packet     = new Net::DNS::Packet( 'example.com', $type, $class );
			my $encoded    = $packet->data;
			my ($example)  = $packet->question;
			my $expected   = $example->string;
			my ($question) = new Net::DNS::Packet( \$encoded )->question;
			is( $question->string, $expected, "$test\t$expected" );
		}
	}
}


{
	my @part = ( 1 .. 4 );
	while (@part) {
		my $test   = 'interpret IPv4 prefix as PTR query';
		my $prefix = join '.', @part;
		my $domain = new Net::DNS::Question($prefix);
		my $actual = $domain->qname;
		my $invert = join '.', reverse 'in-addr.arpa', @part;
		my $inaddr = new Net::DNS::Question($invert);
		my $expect = $inaddr->qname;
		is( $actual, $expect, "$test\t$prefix" );
		pop @part;
	}
}


{
	foreach my $type (qw(NS SOA ANY)) {
		my $test     = "query $type in in-addr.arpa namespace";
		my $question = new Net::DNS::Question( '1.2.3.4', $type );
		my $qtype    = $question->qtype;
		my $string   = $question->string;
		is( $qtype, $type, "$test\t$string" );
	}
}


{
	foreach my $n ( 32, 24, 16, 8 ) {
		my $ip4	   = '1.2.3.4';
		my $test   = "accept CIDR address/$n prefix syntax";
		my $m	   = ( ( $n + 7 ) >> 3 ) << 3;
		my $actual = new Net::DNS::Question("$ip4/$n");
		my $expect = new Net::DNS::Question("$ip4/$m");
		my $string = $expect->qname;
		is( $actual->qname, $expect->qname, "$test\t$string" );
	}
}


{
	is(	new Net::DNS::Question('1:2:3:4:5:6:7:8')->string,
		"8.0.0.0.7.0.0.0.6.0.0.0.5.0.0.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.ip6.arpa.\tIN\tPTR",
		'interpret IPv6 address as PTR query in ip6.arpa namespace'
		);
	is(	new Net::DNS::Question('::x')->string,
		"::x.\tIN\tA",
		'non-address character precludes interpretation as PTR query'
		);
}


{
	my @part = ( 1 .. 8 );
	while (@part) {
		my $n	   = @part * 16;
		my $test   = 'interpret IPv6 prefix as PTR query';
		my $prefix = join ':', @part;
		my $actual = new Net::DNS::Question($prefix)->qname;
		my $expect = new Net::DNS::Question("$prefix/$n")->qname;
		is( $actual, $expect, "$test\t$prefix" ) if $prefix =~ /:/;
		pop @part;
	}
}


{
	foreach my $n ( 16, 12, 8, 4 ) {
		my $ip6	   = '1234:5678:9012:3456:7890:1234:5678:9012';
		my $test   = "accept IPv6 address/$n prefix syntax";
		my $m	   = ( ( $n + 3 ) >> 2 ) << 2;
		my $actual = new Net::DNS::Question("$ip6/$n");
		my $expect = new Net::DNS::Question("$ip6/$m");
		my $string = $expect->qname;
		is( $actual->qname, $expect->qname, "$test\t$string" );
	}
}


{
	my $expected = length new Net::DNS::Question('1:2:3:4:5:6:7:8')->qname;
	foreach my $i ( reverse 0 .. 6 ) {
		foreach my $j ( $i + 3 .. 9 ) {
			my $ip6 = join( ':', 1 .. $i ) . '::' . join( ':', $j .. 8 );
			my $name = new Net::DNS::Question("$ip6")->qname;
			is( length $name, $expected, "check length of expanded IPv6 address\t$ip6" );
		}
	}
}

