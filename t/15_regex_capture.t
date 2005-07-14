#!/usr/bin/perl -w
# $Revision: #1 $$Date: 2005/04/28 $$Author: nautsw $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2003-2005 by Jeff Dutton.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Data::Dumper;
use Test;
use vars qw(@TestREs $TestsPerRE);

BEGIN {
    $TestsPerRE = 20;  # Number of random strings chosen and tested for each regular expression
    @TestREs = ( { re=>qr/Hello (\w+)!/,
		   captures=>[ { 1=>"World", },
			       { 1=>"Universe", },
			       { 1=>"Washington", },
			       ], },
		 { re=>qr/((http|https|ftp):\/\/)?(www[0-9]?|ftp|\w+)\.(\w+)\.(com|gov|edu|\w{1,5})/x,
		   captures=>[ { 2=>"http", 3=>"www", 4=>"yahoo", 5=>"com" },
			       { 2=>"ftp", 3=>"secret", 4=>"squirrel", 5=>"xyz", },
			       { 1=>"mailto://", 2=>"not used because 1 is specified", },
			       ], },
		 );

    plan tests => ($#TestREs+1);
}
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;

foreach my $testRE (@TestREs) {
    my $re = Parse::RandGen::Regexp->new($testRE->{re});
    my @testCaptures = @{$testRE->{captures}};
    my $error = "";

  TEST_LOOP:
    foreach my $doMatch (1, 0) {
	for (my $i=0; $i<$TestsPerRE; $i++) {
	    foreach my $captures (@testCaptures) {
		my $data = $re->pick(match=>$doMatch, captures=>$captures);
		my $matches = ($data =~ $testRE->{re})?1:0;

		# Use Data Dumper to get readable data (sometimes funky characters are used)
		my $d = Data::Dumper->new([$data]);
		$d->Terse(1)->Indent(0)->Useqq(1);
		my $dispData = $d->Dump();

		if (($matches == $doMatch)
		    || !$doMatch #FIX - currently unable to guarantee a mismatch...  You can always get lucky ;-)
		    ) {
		    printf("Success: %-20s regexp picked a %-6s for the input %s%s\n",
			   $testRE->{re}, ($doMatch?"MATCH":"MISS"), $dispData, ((!$doMatch&&$matches)?"  (the pick was for a MISS, but you can never be sure)":""));
		} else {
		    $error = sprintf("%%Error: %-20s regexp picked a %-6s for the input %s!\n",
				     $testRE->{re}, ($doMatch?"MATCH":"MISS"), $dispData);
		    last TEST_LOOP;
		}
	    }
	}
    }
    warn("\n\n$error\n\n") if $error;
    ok(!$error);
}
