use warnings;
use strict;

package Wifty::UI::aliased_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'relative'     => sub { show('local') };
template 'relative_dot' => sub { show('./local') };
template 'fullpath'     => sub { show('/aliased_pkg/local') };
template 'root'         => sub { show('/local') };
template 'parent'       => sub { show('../local') };

template 'local' => sub {
    div { outs( 'This is a template local to ' . __PACKAGE__ ) };
};

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

alias Wifty::UI::aliased_pkg under '/aliased_pkg';

template 'relative'     => sub { show('local') };
template 'relative_dot' => sub { show('./local') };
template 'root'         => sub { show('/local') };

template 'local' => sub {
    div { outs( 'This is a template local to ' . __PACKAGE__ ) };
};

package main;
use Template::Declare::Tags;
Template::Declare->init( roots => ['Wifty::UI'] );

use Test::More tests => 23;

ok( Wifty::UI::aliased_pkg->has_template('local') );
ok( Wifty::UI->has_template('local') );
ok( Template::Declare->has_template('aliased_pkg/local') );

{
    my $simple = ( show('local') );
    like( $simple, qr'template local' );
    like( $simple, qr'Wifty::UI', 'Correct package');
}

{
    my $simple = ( show('aliased_pkg/local') );
    like( $simple, qr'template local' );
    like( $simple, qr'Wifty::UI::aliased_pkg', 'Correct package');
}

for my $template (qw(aliased_pkg/relative aliased_pkg/relative_dot aliased_pkg/fullpath)) {
    my $simple = ( show( $template ) );
    like( $simple, qr'template local' );
    like( $simple, qr'Wifty::UI::aliased_pkg', 'Correct package for '.$template);
}

for my $template (qw(aliased_pkg/root aliased_pkg/parent relative relative_dot root)) {
    my $simple = ( show( $template ) );
    like( $simple, qr'template local' );
    like( $simple, qr'Wifty::UI', 'Correct package for '.$template);
}

1;
