#!/usr/local/bin/perl -w
# $Revision: #1 $$Date: 2003/08/19 $$Author: jdutton $
#DESCRIPTION: Perl ExtUtils: Common routines required by package tests

use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib -IPreproc/blib/arch -IPreproc/blib/lib";

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
    use lib "Preproc/blib/lib";
    use lib "Preproc/blib/arch";
}

1;
