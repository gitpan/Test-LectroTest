package Test::LectroTest;

use warnings;
use strict;

use Test::LectroTest::TestRunner;
use Filter::Util::Call;
require Test::LectroTest::Property;
require Test::LectroTest::Generator;

our $VERSION = 0.20_06;

=head1 NAME 

Test::LectroTest - Easy, automatic, specification-based tests

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use MyModule;  # contains code we want to test
    use Test::LectroTest;

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

    Property { ... }, name => "yet another property" ;

    # more properties to check here

=head1 DESCRIPTION

This module provides a simple (yet full featured) interface to
LectroTest, an automated, specification-based testing system for Perl.
To use it, you declare properties that specify the expected behavior
of your software.  LectroTest then checks your software see whether
those properties hold.

You declare properties using the C<Property> function, which takes a
block of code and promotes it to a L<Test::LectroTest::Property>:

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

The first part of the block must contain a generator-binding
declaration.  For example:

        ##[  x <- Int, y <- Int  ]##

(Note the special bracketing, which is required.)  This particular
binding says, "For all integers I<x> and I<y>."  (By the way, you
aren't limited to integers.  LectroTest also gives you booleans,
strings, lists, hashes, and more, and it lets you define your own
generator types.  See L<Test::LectroTest::Generator> for more.)

The second part of the block is simply a snippet of code that makes
use of the variables we bound earlier to test whether a property holds
for the piece of software we are testing:

        MyModule::my_function( $x, $y ) >= 0;

In this case, it asserts that C<MyModule::my_function($x,$y)> returns
a non-negative result.  (Yes, C<$x> and C<$y> refer to the same I<x>
and I<y> that we bound to the generators earlier.  LectroTest
automagically loads these lexically bound Perl variables with values
behind the scenes.)

Finally, we give the whole Property a name, in this case "my_function
output is non-negative."  It's a good idea to use a meaningful name
because LectroTest refers to properties by name in its output.

Let's take a look at the finished property specification:

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

It says, "For all integers I<x> and I<y>, we assert that my_function's
output is non-negative."

To check whether this property holds, simply put it in a Perl program
that uses the Test::LectroTest module.  (See the L</SYNOPSIS> for an
example.)  When you run the program, LectroTest will load the property
(and any others in the file) and check it by running random trials
against the software you're testing.

If LectroTest is able to "break" your software during the property
check, it will emit a counterexample to your property's assertions and
stop.  You can plug the counterexample back into your software to
debug the problem.  (You might also want to add the counterexample to
a list of regression tests.)

A successful LectroTest looks like this:

  1..1
  ok 1 - 'my_function output is non-negative' (1000 attempts)

On the other hand, if you're not so lucky:

  1..1
  not ok 1 - 'my_function output is non-negative' falsified \
      in 324 attempts
  # Counterexample:
  # $x = -34
  # $y = 0

=head1 ADJUSTING THE TESTING PARAMETERS

There is one testing parameter that you may wish to change: The number
of trials to run against each property checked.  By default it is
1,000.  If you want to try more or fewer trials, pass the
C<trials=E<gt>>I<N> flag:

  use Test::LectroTest trials => 10_000;


=head1 CAVEATS

A Property specification must appear in the first column, i.e.,
without any indentation, in order for it to be automatically loaded
and checked.  If this poses a problem, let me know, and this
restriction can be lifted.

=head1 SEE ALSO

For a more in-depth introduction to LectroTest, see
Test::LectroTest::Tutorial.  For more information on the various parts
of LectroTest, see Test::LectroTest::Property,
Test::LectroTest::Generator, and Test::LectroTest::TestRunner.

Also, the slides from my LectroTest talk for the Pittsburgh Perl
Mongers make for a great introduction.  Download a copy from the
LectroTest home (see below).


=cut

our $r;
our @props;
our @opts;

sub import {
    my $self = shift;
    Test::LectroTest::Property->export_to_level(1, $self);
    Test::LectroTest::Generator->export_to_level(
        1, $self, qw(:common :combinators Gen) );
    @opts = @_;
    $r = Test::LectroTest::TestRunner->new( @_ );
    my $lines = 0;
    my $subfilter = Test::LectroTest::Property::make_code_filter();
    filter_add( sub {
        my $status = filter_read();
        s{^(?=Test|Property)\b}{push \@Test::LectroTest::props, };
        $subfilter->( $status );
    });
}

sub run {
    $r->run_suite( @props, @opts ) if @props;
}

END { Test::LectroTest::run() }

1;

__END__


=head1 LECTROTEST HOME

The LectroTest home is 
http://community.moertel.com/LectroTest.
There you will find more documentation, presentations, a wiki,
and other helpful LectroTest-related resources.  It's also the
best place to ask questions.

=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 INSPIRATION

The LectroTest project was inspired by Haskell's fabulous
QuickCheck module by Koen Claessen and John Hughes:
http://www.cs.chalmers.se/~rjmh/QuickCheck/.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut