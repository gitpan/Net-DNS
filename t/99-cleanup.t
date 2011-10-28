# $Id: 99-cleanup.t 940 2011-10-28 14:10:01Z willem $ -*-perl-*-
use Test::More;
plan tests => 1;

diag ("Cleaning");

unlink("t/online.disabled") if (-e "t/online.disabled");
unlink("t/IPv6.disabled") if (-e "t/IPv6.disabled");

ok(1,"Dummy");



