#!/usr/local/bin/perl -w
# $Revision: #3 $$Date: 2003/08/20 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Data::Dumper;
use Test;
use vars qw(@TestREs $TestsPerRE);

BEGIN {
    $TestsPerRE = 10;  # Number of random strings chosen and tested for each regular expression
    @TestREs = ( qr/foo(bar|baz){3}/,
		 qr'[\-\_\.\!\~\*\'\(\)]+',
		 qr"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}",
		 qr"don't mess with texas!"i,
		 qr/^hello$/i,
		 qr/fo?oz/,
		 qr//,   # FIX
		 );

    plan tests => ($#TestREs+1);
}
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;

foreach my $testRE (@TestREs) {
    my $re = Parse::RandGen::Regexp->new($testRE);
    my $error = "";

  TEST_LOOP:
    foreach my $doMatch (1, 0) {
	for (my $i=0; $i<$TestsPerRE; $i++) {
	    my $data = $re->pick(match=>$doMatch);
	    my $matches = ($data =~ $testRE)?1:0;

	    # Use Data Dumper to get readable data (sometimes funky characters are used)
	    my $d = Data::Dumper->new([$data]);
	    $d->Terse(1)->Indent(0)->Useqq(1);
	    my $dispData = $d->Dump();

	    if (($matches == $doMatch)
		|| !$doMatch #FIX - currently unable to guarantee a mismatch...  You can always get lucky ;-)
		) {
		printf("Success: %-20s regexp got a %-6s for the input %s%s\n",
		       $testRE, ($doMatch?"MATCH":"MISS"), $dispData, ((!$doMatch&&$matches)?"  (the pick was for a MISS, but you can never be sure)":""));
	    } else {
		$error = sprintf("%%Error: %-20s regexp got a %-6s for the input %s!\n",
				 $testRE, ($doMatch?"MATCH":"MISS"), $dispData);
		last TEST_LOOP;
	    }
	}
    }
    warn("\n\n$error\n\n") if $error;
    ok(!$error);
}
