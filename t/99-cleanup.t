# $Id: 99-cleanup.t 954 2011-11-02 21:32:55Z willem $ -*-perl-*-
use Test::More;
plan tests => 1;

diag ("Cleaning");

unlink("t/online.disabled") if (-e "t/online.disabled");
unlink("t/IPv6.disabled") if (-e "t/IPv6.disabled");

ok(1,"Dummy");



