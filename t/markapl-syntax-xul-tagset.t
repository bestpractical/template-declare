#!/usr/bin/env perl -w
use strict;

package TestView;
use base 'Template::Declare';
use Template::Declare::Tags 'XUL';

template 'main' => sub {
    groupbox {
        caption(label => "Colors") {
            radiogroup {
                for my $id ( qw< orange violet yellow > ) {
                    radio(id => $id, label => ucfirst($id), $id eq 'violet' ? (selected => 'true') : ());
                }
            }
        }
    }
};

1;

package main;

Template::Declare->init(roots => [ 'TestView']);

use Test::More tests => 1;

my $out = (Template::Declare->show("main"));
diag($out);

# like($out, qr{<div(\s+id="id")?>\s*<p>.+?</p>\s*</div>});
pass;






