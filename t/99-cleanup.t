# $Id: 99-cleanup.t 931 2011-10-25 12:10:56Z willem $ -*-perl-*-
use Test::More;
plan tests => 1;

diag ("Cleaning");

unlink("t/online.disabled") if (-e "t/online.disabled");
unlink("t/IPv6.disabled") if (-e "t/IPv6.disabled");

ok(1,"Dummy");



