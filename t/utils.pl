use warnings;
use strict;

use Test::More;

sub ok_lint {
    my $html = shift;
  
    if (! eval { require HTML::Lint } ) {
        ok(1, "HTML::Lint not installed. Skipping");
        return
    }

    {
    my $lint = HTML::Lint->new;
     $lint->parse($html); 
     is( $lint->errors, 0, "Lint checked clean" );
    foreach my $error ( $lint->errors ) {
        diag( $error->as_string );
        }}

}


1;
