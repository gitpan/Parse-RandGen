#!/usr/local/bin/perl -w
# $Revision: #1 $$Date: 2003/08/20 $$Author: jdutton $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Data::Dumper;
use Test;
use vars qw(@TestREs $TestsPerRE);

BEGIN {
    plan tests => 1;
}
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;


{   # README Example
    my $grammar = Parse::RandGen::Grammar->new("Filename");
    $grammar->defineRule("token")->set( prod=>[ cond=>qr/[a-zA-Z0-9_.]+/, ], );
    $grammar->defineRule("pathUnit")->set( prod=>[ cond=>"token", cond=>"'/'", ], );
    $grammar->defineRule("relativePath")->set( prod=>[ cond=>"pathUnit(*)", cond=>"token", ], );
    $grammar->defineRule("absolutePath")->set( prod=>[ cond=>"'/'", cond=>"pathUnit(*)", cond=>"token(?)", ], );
    $grammar->defineRule("path")->set( prod=>[ cond=>"absolutePath", ],
				       prod=>[ cond=>"relativePath", ],  );
    foreach my $i (0..100) {
	print "Here is a random path: <" . $grammar->rule("path")->pick() . ">\n";
    }
    ok(1);
}
