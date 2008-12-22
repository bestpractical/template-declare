use warnings;
use strict;

use Test::More;
use HTML::Lint;

sub ok_lint {
    my $html = shift;
   
    {
    my $lint = HTML::Lint->new;
     $lint->parse($html); 
     is( $lint->errors, 0, "Lint checked clean" );
    foreach my $error ( $lint->errors ) {
        diag( $error->as_string );
        }}

}


1;
