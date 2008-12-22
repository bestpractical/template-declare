use warnings;
use strict;

package Wifty::UI::imported_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'imported' => sub {
    my $self = shift;
    div { outs( 'This is imported from ' . $self ) };
};

package Wifty::UI::imported_subclass_pkg;
use base qw/Wifty::UI::imported_pkg/;
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

import_templates Wifty::UI::imported_pkg under '/imported_pkg';
import_templates Wifty::UI::imported_subclass_pkg under '/imported_subclass_pkg';

package main;
use Template::Declare::Tags;
Template::Declare->init( roots => ['Wifty::UI'] );

use Test::More tests => 12;
require "t/utils.pl";

ok( Wifty::UI::imported_pkg->has_template('imported') );
ok( Wifty::UI::imported_subclass_pkg->has_template('imported') );

ok( Template::Declare->has_template('imported_pkg/imported') );
ok( Template::Declare->has_template('imported_subclass_pkg/imported'), "When you subclass and then import, the superclass's imports are there" );

is( Wifty::UI::imported_subclass_pkg->path_for('imported'), '/imported_subclass_pkg/imported' );
is( Wifty::UI->path_for('simple'), '/simple' );

{
    my $simple = ( show('imported_pkg/imported') );
    like( $simple, qr'This is imported' );
    like( $simple, qr'Wifty::UI',
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    my $simple = ( show('imported_subclass_pkg/imported') );
    like(
        $simple,
        qr'This is imported',
        "We got the imported version in the subclass"
    );
    like(
        $simple,
        qr'Wifty::UI',
        '$self is correct in template block'
    );
    ok_lint($simple);
}
1;
