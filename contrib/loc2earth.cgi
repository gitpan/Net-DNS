#!/usr/local/bin/perl -T

# loc2earth.cgi - generates a redirect to Earth Viewer based on LOC record
# [ see <URL: http://www.kei.com/homepages/ckd/dns-loc/ > or RFC 1876 ]

# by Christopher Davis <ckd@kei.com>

# $Id: loc2earth.cgi,v 1.5 1997/06/30 19:29:08 ckd Exp $

die "I want 5.004 and I want it now" if $] < 5.004;

use CGI qw(:standard 2.36);	# style support in 2.36 and later
use Net::DNS '0.08';		# LOC support in 0.08 and later

print header(-Title => "RFC 1876 Resources: Earth Viewer Demo");

print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html><head> <title>RFC 1876 Resources: Earth Viewer Demo</title>
<!-- Generated by $Id: loc2earth.cgi,v 1.5 1997/06/30 19:29:08 ckd Exp $ -->
 <link rev="made" href="mailto:ckd@kei.com">
 <link rel="stylesheet" href="../ckdstyle.css" title="ckd\'s styles">
</head>
<body bgcolor="#FFFFFF" text="#000000" vlink="#663399" link="#0000FF" alink="#FF0000">
<h2><a href="./">RFC 1876 Resources</a></h2>
<h1>loc2earth: The <a href="http://www.fourmilab.ch/earthview/vplanet.html">Earth Viewer</a> Demo</h1>
<hr>';

print p("This is a fairly quick &amp; dirty demonstration of the use of the",
	a({-href => 'http://www.dimensional.com/~mfuhr/perldns/'},
	  'Net::DNS module'),"and the",
	a({-href =>
            'http://www-genome.wi.mit.edu/ftp/pub/software/WWW/cgi_docs.html'},
	  'CGI.pm library'), "to write LOC-aware Web applications.");

print startform("GET");

print p(strong("Hostname"),textfield(-name => host, -size => 50));

print p(submit, reset), endform;

if (param('host')) {
    $res = new Net::DNS::Resolver;

    $query = $res->query(param('host'),"LOC");

    if (defined ($query)) {	# then we got an answer of some sort
	foreach $ans ($query->answer) {
	    if ($ans->type eq "LOC") {
		$latlonstr = $ans->rdatastr;
		($latdeg,$latmin,$latsec,$lathem,
		 $londeg,$lonmin,$lonsec,$lonhem) = split (/ /,$latlonstr);
		print hr,p("The host",param('host'),"appears to be at",
			   "${latdeg}&#176;${latmin}'${latsec}\" ${lathem}",
			   "latitude and ${londeg}&#176;${lonmin}'${lonsec}\"",
			   "${lonhem} longitude according to the DNS.");
		$evurl = ("http://www.fourmilab.ch/cgi-bin/uncgi/Earth?" .
			  "lat=${latdeg}d${latmin}m${latsec}s&ns=" .
			  (($lathem eq "S")?"lSouth":"lNorth") .
			  "&lon=${londeg}d${lonmin}m${lonsec}s&ew=" .
			  (($lonhem eq "W")?"West":"East") .
			  "&alt=35875");
		print p(a({-href=>$evurl}, "Generate an Earth Viewer image " .
			  "from above this point"));
	    } elsif ($ans->type eq "CNAME") {
		# XXX should follow CNAME chains here
	    }
	}
    } else {
	print hr,p("Sorry, there appear to be no LOC records for the host",
		   param('host'),"in the DNS.");
    }
}

print '<hr>
  <a href="http://www.kei.com/homepages/ckd/dns-loc/"><img
  src="http://www.kei.com/homepages/ckd/dns-loc/rfc1876-now.gif"
    alt="RFC 1876 Now" height=32 width=80 align=right></a>
<address><a href="http://www.kei.com/homepages/ckd/">Christopher Davis</a>
&lt;<a href="mailto:ckd@kei.com">ckd@kei.com</a>&gt;</address>
</body></html>';

