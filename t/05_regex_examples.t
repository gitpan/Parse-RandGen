#!/usr/local/bin/perl -w
# $Revision: #1 $$Date: 2003/08/20 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Data::Dumper;
use Test;

BEGIN { plan tests => 2; }
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;
ok(1);

# This test file contains the little standalone examples from the manual

{
    my $reObj = Parse::RandGen::Regexp->new( qr/foo(bar|baz)/ );
    print "Here is some random data that satisfies the RE:     <" . $reObj->pick() . ">\n";
    print "Here is some that (hopefully) doesn't match the RE: <" . $reObj->pick(match=>0) . ">\n";
    ok(1);
}
