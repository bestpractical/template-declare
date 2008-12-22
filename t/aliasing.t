use warnings;
use strict;

package Wifty::UI::aliased_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'aliased' => sub {
    my $self = shift;
    div { outs( 'This is aliased from ' . $self ) };
    div { 'Variable ', $self->package_variable('VARIABLE') };
};

package Wifty::UI::aliased_subclass_pkg;
use base qw/Wifty::UI::aliased_pkg/;
use Template::Declare::Tags;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {

    html {
        head {};
        body { show 'private-content'; };
        }

};

private template 'private-content' => sub {
    my $self = shift;
    with( id => 'body' ), div {
        outs( 'This is my content from' . $self );
    };
};


alias Wifty::UI::aliased_pkg under '/aliased_pkg', { VARIABLE => 'SET' } ;
alias Wifty::UI::aliased_pkg under '/aliased_pkg2';
alias Wifty::UI::aliased_subclass_pkg under '/aliased_subclass_pkg';

package main;
use Template::Declare::Tags;
Template::Declare->init( roots => ['Wifty::UI'] );

use Test::More tests => 16;
require "t/utils.pl";

ok( Wifty::UI::aliased_pkg->has_template('aliased') );
ok( !  Wifty::UI->has_template('aliased') );
ok( Wifty::UI::aliased_subclass_pkg->has_template('aliased') );

ok( Template::Declare->has_template('aliased_pkg/aliased') );


ok( Template::Declare->has_template('aliased_subclass_pkg/aliased'), "When you subclass and then alias, the superclass's aliass are there" );

{
    my $simple = ( show('aliased_pkg/aliased') );
    like( $simple, qr'This is aliased' );
    like( $simple, qr'Variable SET' , "The variable was set");
    like( $simple, qr'Wifty::UI::aliased_pkg',
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    my $simple = ( show('aliased_pkg2/aliased') );
    like( $simple, qr'This is aliased' );
    unlike( $simple, qr'Varialble SET' , "The variable was  not set on second aliasing");
    like( $simple, qr'Wifty::UI::aliased_pkg',
        '$self is correct in template block' );
    ok_lint($simple);
}



{
    my $simple = ( show('aliased_subclass_pkg/aliased') );
    like(
        $simple,
        qr'This is aliased',
        "We got the aliased version in the subclass"
    );
    like(
        $simple,
        qr'Wifty::UI::aliased_subclass_pkg',
        '$self is correct in template block'
    );
    ok_lint($simple);
}

1;
