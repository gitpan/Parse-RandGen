# $Revision: #3 $$Date: 2003/08/20 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

$DOLLAR = '$$';	# Quoted properly for make
sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

clean::
	-rm -rf test_dir

dist: maintainer-copy distcheck README

## Maintainer use:
tag:
	p4 label -d     \$(DISTNAME)_\$(VERSION_SYM) || true
	p4 label        \$(DISTNAME)_\$(VERSION_SYM)
	p4 labelsync -l \$(DISTNAME)_\$(VERSION_SYM) ...
#	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-dist: dist tag
	mv \$(DISTVNAME).tar.gz \$(HOME)/src/kits

maintainer-copy:

maintainer-clean: distclean
	-rm README Makefile

";
}

WriteMakefile(
	      DISTNAME  => 'Parse-RandGen',
	      NAME      => 'Parse::RandGen',
	      AUTHOR	=> 'Jeff Dutton <jeff_dutton@hotmail.com>',
	      ABSTRACT  => 'Generate random parse data for regexp or BNF grammar',
	      VERSION_FROM  => 'RandGen.pm',
	      PMLIBDIRS => ['lib', 'Parse', 'RandGen',],
	      PREREQ_PM => { 'YAPE::Regex' => 3.02,
			   },
	      'clean'	=> {FILES => qw (test_dir),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

