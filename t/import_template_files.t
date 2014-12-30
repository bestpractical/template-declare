package My::Template;
use base 'Template::Declare';
use Template::Declare::Tags;

My::Template->import_template_files(
    root => 't/imports',
);

package main;

use Test::More tests => 5;

Template::Declare->init( dispatch_to => [ 'My::Template' ] );

like( Template::Declare->show( 'foo', { name => 'foo' } ) 
    => qr#<h1>hi foo</h1>#, 'foo.td' );

like( Template::Declare->show( '/foo/bar', { name => 'bar' } ) 
    => qr#<h1>hello bar</h1>#, 'foo/bar.td' );

My::Template->import_template_files(
    root => 't/imports',
    extension => 'declare',
);

like( Template::Declare->show( '/baz', { name => 'baz' } ) 
    => qr#<h1>hi baz</h1>#, '/baz.declare' );

SKIP: {
    skip "test requires File::ShareDir", 2
        unless eval "use File::ShareDir; 1";

    push @INC, 't/imports/lib';

    ok eval "use My::Other::Template; 1", 'loading My::Other::Template';

    Template::Declare->init( dispatch_to => [ 'My::Other::Template' ] );

    like( Template::Declare->show( '/shared', { name => 'shared' } ) 
        => qr#<h1>hi shared</h1>#, 'shared dir' );
}
