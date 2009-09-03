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
    with ( id => 'body' ), div {
        outs( 'This is my content from' . $self );
    };
};

import_templates Wifty::UI::imported_pkg under '/imported_pkg';
import_templates Wifty::UI::imported_subclass_pkg under '/imported_subclass_pkg';

package main;
use Template::Declare::Tags;
Template::Declare->init( roots => ['Wifty::UI'] );

use Test::More tests => 14;
require "t/utils.pl";

ok( Wifty::UI::imported_pkg->has_template('imported'),
    'Original template should be visible' );
ok( Wifty::UI::imported_subclass_pkg->has_template('imported'),
    'And be visible in a subclass');

ok( Template::Declare->has_template('imported_pkg/imported'),
    'Template should have been imported' );
ok( Template::Declare->has_template('imported_subclass_pkg/imported'),
    'Superclass imports should be visible to subclasses');

is(
    Wifty::UI::imported_subclass_pkg->path_for('imported'),
    '/imported_subclass_pkg/imported',
    'The path for the imported template should be correct'
);
is( Wifty::UI->path_for('simple'), '/simple', 'Simple template shoudl be unimported' );

{
    ok my $simple = ( show('imported_pkg/imported') ), 'Should get output for imported template';
    like( $simple, qr'This is imported', 'Its output should be correct' );
    like( $simple, qr'Wifty::UI', '$self is correct in template block' );
    ok_lint($simple);
}

{
    ok my $simple = ( show('imported_subclass_pkg/imported') ),
        'Should get output from imported template from subclass';
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
