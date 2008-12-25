#!/usr/bin/env perl -w
use strict;

package TestView;
use base 'Template::Declare';
use Template::Declare::Tags;

template t1 => sub {
    div(id => "id") {
        p { "This is my content" }
    }
};

template t2 => sub {
    div("#id") {
        p { "This is my content" }
    }
};

template t3 => sub {
    div {
        p { "This is my content" }
    }
};


package main;

Template::Declare->init(roots => [ 'TestView']);

1;

use Test::More tests => 3;

for(1..3) {
    my $out = (Template::Declare->show("t$_"));
    # diag $out;
    like($out, qr{<div(\s+id="id")?>\s*<p>.+?</p>\s*</div>});
}
