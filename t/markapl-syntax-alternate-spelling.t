#!/usr/bin/env perl -w
use strict;
use Test::More tests => 3;

package View;
use base 'Template::Declare';
use Template::Declare::Tags;

template table => sub {
    table {
        row {
            cell {"One"};
            cell {"Two"};
            cell {"Three"}
        }
    }
};

package main;
use Template::Declare;

Template::Declare->init(roots => ['View']);

my $out = Template::Declare->show("table");

# diag $out;

like $out, qr/<td>.*?<\/td>/s;
like $out, qr/<tr>.*?<\/tr>/s;
like $out, qr/<table>.*?<\/table>/s;
