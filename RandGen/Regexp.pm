# $Revision: #3 $$Date: 2003/08/20 $$Author: wsnyder $
######################################################################
#
# This program is Copyright 2003 by Jeff Dutton.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

package Parse::RandGen::Regexp;

require 5.006_001;
use Carp;
use Parse::RandGen;
use YAPE::Regex;
use strict;
use vars qw(@ISA $Debug %_Yterm);
$Debug = $Parse::RandGen::Debug;
@ISA = ('Parse::RandGen::Condition');

sub _newDerived {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $type = ref($self);
    my $elemRef = ref($self->element());
    ($elemRef eq "Regexp") or confess("%Error:  $type has an element that is not a Regexp reference (ref=\"$elemRef\")!");

    # Implement a RandGen::Rule to represent the complexities of the Regexp
    #   This is only used for pick()ing a matching value for the Regexp...
    my $yape = YAPE::Regex->new($self->element());
    $yape->parse();
    my $treeArray = $yape->{TREE};
    ($#{$treeArray} > 0) and die("Found a YAPE::Regex TREE with more than one entry!\n");
    (ref($$treeArray[0]) eq "YAPE::Regex::group") or die("Found a YAPE::Regex TREE, but its entry is not a group!\n");

    $self->{_rule} = Parse::RandGen::Rule->new();
    my $prod = Parse::RandGen::Production->new();
    $self->{_rule}->addProd($prod);
    my $cur = {
	rule => $self->{_rule},
	prod => $prod,
	on => { },
	off => { i=>1, m=>1, s=>1, x=>1 },
    };
    $Data::Dumper::Indent = 1 if $Debug;
    #print ("Parse::RandGen::Regexp::new():  Getting ready to parse the following Regexp ".$self->element().":\n", Data::Dumper->Dump([$yape])) if $Debug;
    $self->_parseRegexp($$treeArray[0], { rule=>$self->{_rule}, prod=>$prod } );
    #print ("Parse::RandGen::Regexp::new():  Finished parsing the following Regexp ".$self->element()." and now \$self->{_rule} is:\n", $self->{_rule}->dumpHeir(), "\n\n") if $Debug;
    #print ("Parse::RandGen::Regexp::new():  Finished parsing the following Regexp ".$self->element()." and now \$self->{_rule} is:\n", Data::Dumper->Dump([$self->{_rule}])) if $Debug;
}

sub dump {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $delimiter = "'";
    my $output = $self->element();
    $output =~ s/($delimiter)/\\$1/gs;  # First, escape the delimiter (compiled regex is devoid of a specific delimiter)
    $output = "m${delimiter}${output}${delimiter}";
    return $output;
}

sub pick {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1, # Default is to pick matching data
		 @_ );
    my $val = $self->{_rule}->pick(%args);
    my $elem = $self->element();
    #print ("Parse::RandGen::Regexp($elem)::pick(match=>$args{match}) with value of ", $self->dumpVal($val), "\n");
    return($val);
}

# YAPE::Regex elements that are supported as CharClass objects
%_Yterm = (
	   "YAPE::Regex::class"    => sub{ my $y=shift; return ( $y->{NEG} . $y->{TEXT} ); },
	   "YAPE::Regex::slash"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::macro"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::oct"      => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::hex"      => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::utf8hex"  => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::ctrl"     => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::named"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::any"      => sub{ my $y=shift; return ($y->text()); },
	   );

sub _parseRegexp {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $yIter = shift;              # YAPE::Regex object iterator
    my $curRef = shift or confess();  # Current position in Condition ($self) object
    my %cur = %$curRef;  # Make a local copy of current state

    my $yType = ref($yIter);
    if ($yType eq "YAPE::Regex::group") {
	foreach my $switch (split //, $yIter->{ON})  { delete $cur{off}{$switch}; $cur{on}{$switch} = 1; }
	foreach my $switch (split //, $yIter->{OFF}) { delete $cur{on}{$switch}; $cur{off}{$switch} = 1; }
    }

    if ( ($yType eq "YAPE::Regex::group")
	 || ($yType eq "YAPE::Regex::capture") ){
	defined($yIter->{NGREED}) or confess("$yType type does not have NGREED implemented!\n");
	defined($yIter->{QUANT}) or confess("$yType type does not have QUANT implemented!\n");

	my @yList = @{$yIter->{CONTENT}};
	foreach my $elemIter (@yList) {
	    my $elemType = ref($elemIter);
	    if ($elemType eq "YAPE::Regex::alt") {
		$cur{rule}->addProd($cur{prod} = Parse::RandGen::Production->new());
	    } elsif ( ($elemType eq "YAPE::Regex::group")
			|| ($elemType eq "YAPE::Regex::capture") ) {

		defined($elemIter->{NGREED}) or confess("$elemType type does not have NGREED implemented!\n");
		defined($elemIter->{QUANT}) or confess("$elemType type does not have QUANT implemented!\n");
		my $greedy = !$elemIter->{NGREED};
		my $quant = $elemIter->{QUANT};

		my $prod = Parse::RandGen::Production->new();
		my $rule = Parse::RandGen::Rule->new();
		$rule->addProd($prod);

		#print "jeff: creating a subrule (elem=>$rule, quant=>$quant, greedy=>$greedy)\n";
		$cur{prod}->addCond(Parse::RandGen::Subrule->new($rule, quant=>$quant, greedy=>$greedy));

		my %next = %cur;
		$next{rule} = $rule;
		$next{prod} = $prod;
		$self->_parseRegexp($elemIter, \%next);
	    } else {
		$self->_parseRegexp($elemIter, \%cur);
	    }
	}
    } elsif ( ($yType eq "YAPE::Regex::whitespace")
	      || ($yType eq "YAPE::Regex::anchor")
	      ){
	# Do nothing, simply ignore these objects
    } else {
	defined($yIter->{NGREED}) or confess("$yType type does not have NGREED implemented!\n");
	defined($yIter->{QUANT}) or confess("$yType type does not have QUANT implemented!\n");
	my $greedy = !$yIter->{NGREED};
	my $quant = $yIter->{QUANT};
	my @charClasses = ();

	if (($yType eq "YAPE::Regex::text") && $cur{off}{i} && !$quant) {
	    my $cond = Parse::RandGen::Literal->new($yIter->{TEXT}, greedy => $greedy);
	    $cur{prod}->addCond($cond);
	} elsif ($yType eq "YAPE::Regex::alt") {
	    confess("Not expecting a $yType here!\n");
	} else {
	    if ($yType eq "YAPE::Regex::text") {
		# Case-insensitive text
		my $text = $yIter->{TEXT};
		for (my $offset=0; $offset < length($text); $offset++) {
		    my $char = substr($text, $offset, 1);
		    my $nchar = lc($char);
		    $nchar = uc($char) unless ($nchar ne $char);
		    if (($nchar eq $char) || $cur{off}{i}) {
			#print ("Parse::RandGen::Regexp:  creating a case-sensitive CharClass for letter $offset of the literal \"$text\" ([$char])\n");
			push @charClasses, "$char";
		    } else {
			#print ("Parse::RandGen::Regexp:  creating a case-insenstive CharClass for letter $offset of the literal \"$text\" ([$char$nchar])\n");
			push @charClasses, "$char$nchar";
		    }
		}
	    } elsif (exists($_Yterm{$yType})) {
		@charClasses = ( &{$_Yterm{$yType}}($yIter) );
	    } else {
		confess("%Error:  YAPE type unknown or unsupported (\"$yType\")!");
	    }

	    foreach my $cclass (@charClasses) {
		my $on =  join('', sort(keys(%{$cur{on}})));
		my $off = join('', sort(keys(%{$cur{off}})));
		my $charClassRE;
		if ($yType eq "YAPE::Regex::any") {
		    $charClassRE = qr/(?$on-$off:$cclass)/;  # Cannot match the . character in [ ]
		} else {
		    #print "Parse::RandGen::Regexp: cclass is $cclass\n";
		    if (!$on && ($off eq "imsx")) {
			$charClassRE = qr/[$cclass]/;  # default
		    } else {
			$charClassRE = qr/(?$on-$off:[$cclass])/;
		    }
		    #print "Parse::RandGen::Regexp: cclass charClassRE is $charClassRE\n";
		}
		
		my $cond = Parse::RandGen::CharClass->new($charClassRE, quant=>$quant, greedy=>$greedy);
		$cur{prod}->addCond($cond);
	    }
	}
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Regexp - Regular expression Condition element.

=head1 DESCRIPTION

=over 4

Regexp is a Condition element that matches the given compiled regular expression.  For picking random
data, the regular expression is parsed into its component Subrules, Literals, CharClasses, etc....
Therefore, the pick functionality for a regular expression is ultimately the same as the pick functionality
of a Rule (including the limitations w/r to greediness - see Rule).

=head1 METHODS

=head2 new

Creates a new Regexp.  The first argument (required) is the regular expression element (e.g. qr/foo(bar|baz)+\d{1,10}/).
All other arguments are named pairs.

=head2 element

Returns the Regexp element (i.e. the compiled regular expression itself).

=back

=head1 SEE ALSO

B<Parse::RandGen::Condition>,
B<Parse::RandGen::Subrule>,
B<Parse::RandGen::Literal>,
B<Parse::RandGen::CharClass>,
B<Parse::RandGen::Rule>,
B<Parse::RandGen::Production>, and
B<Parse::RandGen>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
