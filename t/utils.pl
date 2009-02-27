use warnings;
use strict;

use Test::More;

sub ok_lint {
    my $html = shift;

SKIP:
    {
        skip "HTML::Lint not installed. Skipping", 1
            unless eval { require HTML::Lint; 1 };

        my $lint = HTML::Lint->new;
        $lint->parse($html);
        is( $lint->errors, 0, "Lint checked clean" );
        foreach my $error ( $lint->errors ) {
            diag( $error->as_string );
        }
    }

}

1;
