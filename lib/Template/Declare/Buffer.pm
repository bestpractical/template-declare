use warnings;
use strict;

package Template::Declare::Buffer;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors('data');

sub append {
    no warnings 'uninitialized';
    # stringify first as it can be overloaded object
    # that changes our buffer
    my $append = "$_[1]";
    $_[0]->data( $_[0]->data . $append );
};

sub clear {
    my $self = shift;
    $self->data('');
};

1;
__END__

=head1 NAME

Template::Declare::Buffer - manage output buffer

=head1 DESCRIPTION

We use this class to manage the output buffer used by L<Template::Declare>.

=head1 SEE ALSO

L<Template::Declare>.

