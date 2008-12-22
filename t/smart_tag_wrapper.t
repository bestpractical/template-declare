use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

sub test_smart_tag (&) {
    my $code = shift;

    smart_tag_wrapper {
        my %args = @_;
        outs(   "START "
              . join( ', ', map { "$_: $args{$_}" } sort keys %args )
              . "\n" );
        $code->();
        outs("END\n");
    };
}

template simple => sub {
    with( foo => 'bar' ),    #
      test_smart_tag { outs("simple\n"); };
};

template leak_check => sub {
    with( foo => 'bar' ),    #
      test_smart_tag { outs("first\n"); };
    test_smart_tag   { outs("second\n"); };
};

package main;
use Template::Declare::Tags;
Template::Declare->init( roots => ['Wifty::UI'] );

use Test::More tests => 2;
require "t/utils.pl";

my $simple = show('simple');
is(
    $simple,
    "\nSTART foo: bar\nsimple\nEND\n",
    "got correct output for simple"
);

my $leak_check = show('leak_check');
is(
    $leak_check,                        #
    "\nSTART foo: bar\nfirst\nEND\n"    #
      . "\nSTART \nsecond\nEND\n",      #
    "got correct output for simple"
);
