use 5.006;
use warnings;
use strict;
use Carp;

package Template::Declare;
use Template::Declare::Buffer;
use Class::ISA;
use String::BufferStack;

our $VERSION = "0.40_01";

use base 'Class::Data::Inheritable';
__PACKAGE__->mk_classdata('roots');
__PACKAGE__->mk_classdata('postprocessor');
__PACKAGE__->mk_classdata('aliases');
__PACKAGE__->mk_classdata('alias_metadata');
__PACKAGE__->mk_classdata('templates');
__PACKAGE__->mk_classdata('private_templates');
__PACKAGE__->mk_classdata('buffer');
__PACKAGE__->mk_classdata('imported_into');
__PACKAGE__->mk_classdata('around_template');

__PACKAGE__->roots( [] );
__PACKAGE__->postprocessor( sub { return wantarray ? @_ : $_[0] } );
__PACKAGE__->aliases(           {} );
__PACKAGE__->alias_metadata(    {} );
__PACKAGE__->templates(         {} );
__PACKAGE__->private_templates( {} );
__PACKAGE__->buffer( String::BufferStack->new );
__PACKAGE__->around_template( undef );

*String::BufferStack::data = sub {
    my $ref = shift;
    if (@_) {
        warn "Template::Declare->buffer->data called with argument; this usage is deprecated";
        ${$ref->buffer_ref} = join("", @_);
    }
    return $ref->buffer;
};

use vars qw/$TEMPLATE_VARS/;

=head1 NAME

Template::Declare - Perlish declarative templates

=head1 SYNOPSIS

Here's an example of basic HTML usage:

    package MyApp::Templates;
    use Template::Declare::Tags; # defaults to 'HTML'
    use base 'Template::Declare';

    template simple => sub {
        html {
            head {}
            body {
                p { 'Hello, world wide web!' }
            }
        }
    };

    package main;
    use Template::Declare;
    Template::Declare->init( roots => ['MyApp::Templates'] );
    print Template::Declare->show( 'simple' );

And here's the output:

 <html>
  <head></head>
  <body>
   <p>Hello, world wide web!
   </p>
  </body>
 </html>

=head1 DESCRIPTION

C<Template::Declare> is a pure-Perl Peclarative HTML/XUL/RDF/XML templating
system.

Yes. Another one. There are many others like it, but this one is ours.

A few key features and buzzwords:

=over

=item *

All templates are 100% pure Perl code

=item *

Simple declarative syntax

=item *

No angle brackets

=item *

"Native" XML namespace and declarator support

=item *

Mixins

=item *

Inheritance

=item *

Public and private templates

=back

=head1 USAGE

=head2 Basic usage

A simple HTML example is in the L<SYNOPSIS/SYNOPSIS>. So let's do XUL!

    package MyApp::Templates;
    use base 'Template::Declare';
    use Template::Declare::Tags 'XUL';

    template main => sub {
        xml_decl { 'xml', version => '1.0' };
        xml_decl { 'xml-stylesheet', href => "chrome://global/skin/", type => "text/css" };
        groupbox {
            caption { attr { label => 'Colors' } }
            radiogroup {
                for my $id ( qw< orange violet yellow > ) {
                    radio {
                        attr {
                            id    => $id,
                            label => ucfirst($id),
                            $id eq 'violet' ? (selected => 'true') : ()
                        }
                    }
                } # for
            }
        }
    };

    package main;
    Template::Declare->init( roots => ['MyApp::Templates'] );
    print Template::Declare->show( 'main' );

The output:

 <?xml version="1.0"?>
 <?xml-stylesheet href="chrome://global/skin/" type="text/css"?>

 <groupbox>
  <caption label="Colors" />
  <radiogroup>
   <radio id="orange" label="Orange" />
   <radio id="violet" label="Violet" selected="true" />
   <radio id="yellow" label="Yellow" />
  </radiogroup>
 </groupbox>

=head2 A slightly more advanced example

In this example, we'll show off how to set attributes on HTML tags, how to
call other templates and how to declare a I<private> template that can't be
called directly. We'll also show passing arguments to templates.

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    private template 'header' => sub {
        head {
            title { 'This is a webpage' };
            meta  { attr { generator => "This is not your father's frontpage" } }
        }
    };

    private template 'footer' => sub {
        my $self = shift;
        my $time = shift || gmtime;

        div {
            attr { id => "footer"};
            "Page last generated at $time."
        }
    };

    template simple => sub {
        my $self = shift;
        my $user = shift || 'world wide web';

        html {
            show('header');
            body {
                img { src is 'hello.jpg' }
                p {
                    attr { class => 'greeting'};
                    "Hello, $user!"
                };
            };
            show('footer');
        }
    };

    package main;
    use Template::Declare;
    Template::Declare->init( roots => ['MyApp::Templates'] );
    print Template::Declare->show( 'simple', 'TD user');

And the output:

 <html>
  <head>
   <title>This is a webpage</title>
   <meta generator="This is not your father&#39;s frontpage" />
  </head>
  <body>
   <img src="hello.jpg" />
   <p class="greeting">Hello, TD user!</p>
  </body>
  <div id="footer">Page last generated at Thu Sep  3 20:56:14 2009.</div>
 </html>

For more options, especially the "native" XML namespace support, C<is> syntax
for attributes, and more samples, see L<Template::Declare::Tags>.

=head2 Postprocessing

Sometimes you just want simple syntax for inline elements. The following shows
how to use a postprocessor to emphasize text _like this_.

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template before => sub {
        h1 {
            outs "Welcome to ";
            em { "my" };
            outs " site. It's ";
            em { "great" };
            outs "!";
        };
    };

    template after => sub {
        h1 { "Welcome to _my_ site. It's _great_!" };
        h2 { outs_raw "This is _not_ emphasized." };
    };

    package main;
    use Template::Declare;
    Template::Declare->init(
        roots         => ['MyApp::Templates'],
        postprocessor => \&emphasize,
    );

    print Template::Declare->show( 'before');
    print Template::Declare->show( 'after');

    sub emphasize {
        my $text = shift;
        $text =~ s{_(.+?)_}{<em>$1</em>}g;
        return $text;
    }

And the output:

 <h1>Welcome to
  <em>my</em> site. It&#39;s
  <em>great</em>!</h1>
 <h1>Welcome to <em>my</em> site. It&#39;s <em>great</em>!</h1>
 <h2>This is _not_ emphasized.</h2>

=head2 Inheritance

Templates are really just methods. You can subclass your template packages to
override some of those methods. See also L<Jifty::View::Declare::CRUD>.

    package MyApp::Templates::GenericItem;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template 'list' => sub {
        my ($self, @items) = @_;
        div {
            show('item', $_) for @items;
        }
    };
    template 'item' => sub {
        my ($self, $item) = @_;
        span { $item }
    };

    package MyApp::Templates::BlogPost;
    use Template::Declare::Tags;
    use base 'MyApp::Templates::GenericItem';

    template 'item' => sub {
        my ($self, $post) = @_;
        h1  { $post->title }
        div { $post->body }
    };

    package main;
    use Template::Declare;

    Template::Declare->init( roots => ['MyApp::Templates::GenericItem'] );
    print Template::Declare->show( 'list', 'foo', 'bar', 'baz' );

    Template::Declare->init( roots => ['MyApp::Templates::BlogPost'] );
    my $post = My::Post->new(title => 'Hello', body => 'first post');
    print Template::Declare->show( 'item', $post );

And the output:

 <div>
  <span>foo</span>
  <span>bar</span>
  <span>baz</span>
 </div>

 <h1>Hello</h1>
 <div>first post</div>

=head2 Aliasing

=head2 Multiple template roots (search paths)

=head1 METHODS

=head2 init

This I<class method> initializes the C<Template::Declare> system.

=over

=item roots

An array reference of packages to begin looking for templates.

=item postprocessor

A coderef called to postprocess the HTML or XML output of your templates. This
is to alleviate using Tags for simple text markup.

=item around_template

A coderef called B<instead> of rendering each template. The coderef will
receive three arguments: a coderef to invoke to render the template, the
template's path, an arrayref of the arguments to the template, and the coderef
of the template itself. You can use this for instrumentation. For example:

    Template::Declare->init(around_template => sub {
        my ($orig, $path, $args, $code) = @_;
        my $start = time;
        $orig->();
        warn "Rendering $path took " . (time - $start) . " seconds.";
    });

=back

=cut

sub init {
    my $class = shift;
    my %args  = (@_);

    if ( $args{'roots'} ) {
        $class->roots( $args{'roots'} );
    }

    if ( $args{'postprocessor'} ) {
        $class->postprocessor( $args{'postprocessor'} );
    }

    if ( $args{'around_template'} ) {
        $class->around_template( $args{'around_template'} );
    }

}

sub new_buffer_frame {
    __PACKAGE__->buffer->push( private => 1 );
}

sub end_buffer_frame {
    __PACKAGE__->buffer->pop;
}

=head2 show TEMPLATE_NAME

    Template::Declare->show( 'howdy', name => 'Larry' );
    my $output = Template::Declare->show('index');

Call C<show> with a C<template_name> and C<Template::Declare> will render that
template. Subsequent arguments will be passed to the template. Content
generated by C<show()> can be accessed via the C<output()> method if the
output method you've chosen returns content instead of outputting it directly.

If called in scalar context, this method will also just return the content
when available.

=cut

sub show {
    my $class    = shift;
    my $template = shift;
    local %Template::Declare::Tags::ELEMENT_ID_CACHE = ();
    return Template::Declare::Tags::show_page($template => @_);
}

=head2 path_for $template

    my $path = Template::Declare->path_for('index');

Returns the path for the template name to be used for show, adjusted
with paths used in C<import_templates>.

=cut

sub path_for {
    my $class = shift;
    my $template = shift;
    return ($class->imported_into ||'') . '/' . $template;
}

=head2 resolve_template TEMPLATE_PATH INCLUDE_PRIVATE_TEMPLATES

    my $code = Template::Declare->resolve_template($template);
    my $code = Template::Declare->has_template($template, 1);

Turns a template path (C<TEMPLATE_PATH>) into a C<CODEREF>.  If the
boolean C<INCLUDE_PRIVATE_TEMPLATES> is true, resolves private template
in addition to public ones. C<has_template()> is an alias for this method.

First it looks through all the valid Template::Declare roots. For each
root, it looks to see if the root has a template called $template_name
directly (or via an C<import> statement). Then it looks to see if there
are any L</alias>ed paths for the root with prefixes that match the
template we're looking for.

=cut

sub resolve_template {
    my $self          = shift;
    my $template_name = shift;
    my $show_private  = shift || 0;

    my @search_packages;

    # If we're being called as a class method on T::D it means "search in any package"
    # Otherwise, it means search only in this specific package"
    if ( $self eq __PACKAGE__ ) {
        @search_packages = reverse @{ Template::Declare->roots };
    } else {
        @search_packages = ($self);
    }

    foreach my $package (@search_packages) {
        next unless ( $package and $package->isa(__PACKAGE__) );
        if ( my $coderef = $package->_has_template( $template_name, $show_private ) ) {
            return $coderef;
        } elsif (  $coderef = $package->_has_aliased_template($template_name, $show_private) ) {
            return $coderef;
        }
    }
}

sub has_template { resolve_template(@_) }

=head2 register_template( TEMPLATE_NAME, CODEREF )

    MyApp::Templates->register_template( howdy => sub { ... } );

This method registers a template called C<TEMPLATE_NAME> in the calling class.
As you might guess, C<CODEREF> defines the template's implementation. This
method is mainly intended to be used internally, as you use the C<template>
keyword to create templates, right?

=cut

sub register_template {
    my $class         = shift;
    my $template_name = shift;
    my $code          = shift;
    push @{ __PACKAGE__->templates()->{$class} }, $template_name;
    _register_template( $class, _template_name_to_sub($template_name), $code )
}

=head2 register_private_template( TEMPLATE_NAME, CODEREF )

    MyApp::Templates->register_private_template( howdy => sub { ... } );

This method registers a private template called C<TEMPLATE_NAME> in the caling
class. As you might guess, C<CODEREF> defines the template's implementation.

Private templates can't be called directly from user code but only from other
templates.

This method is mainly intended to be used internally, as you use the
C<private template> expression to create templates, right?

=cut

sub register_private_template {
    my $class         = shift;
    my $template_name = shift;
    my $code          = shift;
    push @{ __PACKAGE__->private_templates()->{$class} }, $template_name;
    _register_template( $class, _template_name_to_private_sub($template_name), $code );

}

=head2 alias TEMPLATE_ROOT under PATH

    alias Some::Clever::Mixin under '/mixin';
    alias Some::Other::Mixin  under '/mymix', { name => 'Larry' };

Sometimes you want to alias templates to a subpath, or mix them into an
existing template path. Use C<alias> to do so. In the first example, if
Some::Clever::Mixin creates templates named "foo" and "bar", they will be
aliased to "mixin/foo" and "mixin/bar".

The second example mixes in the templates defined in Some::Other::Mixin into
the "/mymix" path and defines a package variable for use only by the alias.
If this template was defined in Some::Other::Mixin:

    template 'howdy' => sub {
        my $self = shift;
        outs "Howdy, " . $self->package_variable('name') || 'Jesse';
    };

Then use of the "mymixin/howdy" template will output "Howdy, Lary", while use
of the original template, "howdy", will output "Howdy, Jesse". In other words,
package variables defined for the alias are available only to the alias, and
not to the original.

In either case, ineritance continues to work. A template package that inherits
from Some::Other::Mixin, for example, will be able to access both
"mymixin/howdy" and "howdy".

=cut

sub alias {
    my $alias_into   = caller(0);
    my $mixin        = shift;
    my $prepend_path = shift;
    my $package_vars = shift;

    $prepend_path =~ s|/+/|/|g;
    $prepend_path =~ s|/$||;

    my $alias_key = $mixin . " " . $prepend_path;
    push @{ Template::Declare->aliases->{$alias_into} }, $alias_key;
    $alias_into->alias_metadata()->{$alias_key} = {
        class        => $mixin,
        path         => $prepend_path,
        package_vars => $package_vars
    };

}

=head2 import_templates

    import_templates MyApp::Templates under '/something';

Import the templates defined in a template class into a subpath via the
C<import_templates> function. In this example, the templates defined in
MyApp::Templates will be imported into the "/something" path. Thus, a template
deined in MyApp::Templates named "foo" will also be accessible via
"something/foo". This is not unlike mixing in templates with C<alias>, but is
lighter-weight and package variables cannot be assigned. This is because it is
really like a hard link to the template, whereas an alias is a copy with the
variable information attached to it.

=cut

sub import_templates {
    return undef if $_[0] eq __PACKAGE__;
    my $import_into      = caller(0);
    my $import_from_base = shift;
    my $prepend_path     = shift;

    $prepend_path =~ s|/+/|/|g;
    $prepend_path =~ s|/$||;
    $import_from_base->imported_into($prepend_path);

    my @packages = reverse grep { $_->isa(__PACKAGE__) }
        Class::ISA::self_and_super_path( $import_from_base );

    foreach my $import_from (@packages) {
        foreach my $template_name (  __PACKAGE__->_templates_for($import_from) ) {
            my $code = $import_from->_find_template_sub( _template_name_to_sub($template_name));
            $import_into->register_template( $prepend_path . "/" . $template_name, $code );
        }
        foreach my $template_name (  __PACKAGE__->_private_templates_for($import_from) ) {
            my $code = $import_from->_find_template_sub( _template_name_to_private_sub($template_name) );
            $import_into->register_private_template( $prepend_path . "/" . $template_name, $code );
        }
    }
}

sub _templates_for {
    my $tmpl = shift->templates->{+shift} or return;
    return wantarray ? @{ $tmpl } : $tmpl;
}

sub _private_templates_for {
    my $tmpl = shift->private_templates->{+shift} or return;
    return wantarray ? @{ $tmpl } : $tmpl;
}

sub _has_template {
    # Otherwise find only in specific package
    my $pkg           = shift;
    my $template_name = shift;
    my $show_private  = 0 || shift;

    if ( my $coderef = $pkg->_find_template_sub( _template_name_to_sub($template_name) ) ) {
        return $coderef;
    } elsif ( $show_private and $coderef = $pkg->_find_template_sub( _template_name_to_private_sub($template_name))) {
        return $coderef;
    }

    return undef;
}

sub _has_aliased_template {
    my $package       = shift;
    my $template_name = shift;
    my $show_private  = shift;

    # XXX Should we consider normalizing the path in a more standard way?
    $template_name = "/$template_name" unless $template_name =~ m{^/};

    foreach my $alias_key ( @{ Template::Declare->aliases->{$package} } ) {
        my $alias_info   = $package->alias_metadata()->{$alias_key};
        my $alias_prefix = $alias_info->{path};
        my $alias_class  = $alias_info->{class};
        my $package_vars = $alias_info->{package_vars};

        $alias_prefix = "/$alias_prefix" unless $alias_prefix =~ m{^/};

        # handle the case where we alias something under '/'. the regex appends
        # a '/' so we need to prevent matching against m{^//};
        $alias_prefix = '' if $alias_prefix eq '/';

        if ( $template_name =~ m{^$alias_prefix/(.*)$} ) {
            my $dispatch_to_template = $1;
            if (my $coderef = $alias_class->resolve_template( $dispatch_to_template, $show_private)) {

                return sub {
                    shift @_;  # Get rid of the passed-in "$self" class.
                    local $TEMPLATE_VARS->{$alias_class} = $package_vars;
                    &$coderef($alias_class,@_);
                };
            }

        }

    }
}

sub _dispatch_template {
    my $class = shift;
    my $code  = shift;
    unshift @_, $class;
    goto $code;
}

sub _find_template_sub {
    my $self    = shift;
    my $subname = shift;
    return $self->can($subname);
}

sub _template_name_to_sub {
    return _subname( "_jifty_template_", shift );
}

sub _template_name_to_private_sub {
    return _subname( "_jifty_private_template_", shift );
}

sub _subname {
    my $prefix = shift;
    my $template = shift || '';
    $template =~ s{/+}{/}g;
    $template =~ s{^/}{};
    return join( '', $prefix, $template );
}

sub _register_template {
    my $self    = shift;
    my $class   = ref($self) || $self;
    my $subname = shift;
    my $coderef = shift;
    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::' . $subname } = $coderef;
}

sub package_variable {
    my $self = shift;
    my $var  = shift;
    if (@_) {
        $TEMPLATE_VARS->{$self}->{$var} = shift;
    }
    return $TEMPLATE_VARS->{$self}->{$var};
}

sub package_variables {
    my $self = shift;
    my $var  = shift;
    if (@_) {
        %{ $TEMPLATE_VARS->{$self} } = shift;
    }
    return $TEMPLATE_VARS->{$self};
}

=head1 PITFALLS

We're reusing the perl interpreter for our templating langauge, but Perl was
not designed specifically for our purpose here. Here are some known pitfalls
while you're scripting your templates with this module.

=over

=item *

It's quite common to see tag sub calling statements without trailing
semi-colons right after C<}>. For instance,

    template foo => sub {
        p {
            a { attr { src => '1.png' } }
            a { attr { src => '2.png' } }
            a { attr { src => '3.png' } }
        }
    };

is equivalent to

    template foo => sub {
        p {
            a { attr { src => '1.png' } };
            a { attr { src => '2.png' } };
            a { attr { src => '3.png' } };
        };
    };

But C<xml_decl> is a notable exception. Please always put a trailing semicolon
after C<xml_decl { ... }>, or you'll mess up the outputs.

=item *

Another place that requires trailing semicolon is the statements before a Perl
looping statement, an if statement, or a C<show> call. For example:

    p { "My links:" };
    for (@links) {
        with ( src => $_ ), a {}
    }

The C<;> after C< p { ... } > is required here, or Perl will complain about
syntax errors.

Another example is

    h1 { 'heading' };  # this trailing semicolon is mandatory
    show 'tag_tag'

=item *

The C<is> syntax for declaring tag attributes also requires a trailing
semicolon, unless it is the only statement in a block. For example,

    p { class is 'item'; id is 'item1'; outs "This is an item" }
    img { src is 'cat.gif' }

=item *

Literal strings that have tag siblings won't be captured. So the following template

    p { 'hello'; em { 'world' } }

produces

 <p>
  <em>world</em>
 </p>

instead of the desired output

 <p>
  hello
  <em>world</em>
 </p>

You can use C<outs> here to solve this problem:

    p { outs 'hello'; em { 'world' } }

Note you can always get rid of C<outs> if the string literal is the only
element of the containing block:

    p { 'hello, world!' }

=item *

Look out! If the if block is the last block/statement and the condition part
is evaluated to be 0:

    p { if ( 0 ) { } }

produces

 <p>0</p>

instead of the more intutive output:

 <p></p>

This's because C<if ( 0 )> is the last expression, so it's returned as the
value of the whole block, which is used as the content of <p> tag.

To get rid of this, just put an empty string at the end so it returns empty
string as the content instead of 0:

    p { if ( 0 ) { } '' }

=back

=head1 BUGS

Crawling all over, baby. Be very, very careful. This code is so cutting edge,
it can only be fashioned from carbon nanotubes. But we're already using this
thing in production :) Make sure you have read the L<PITFALLS/PITFALLS>
section above :)

Some specific bugs and design flaws that we'd love to see fixed.

=over

=item Output isn't streamy.

=back

If you run into bugs or misfeatures, please report them to
C<bug-template-declare@rt.cpan.org>.

=head1 SEE ALSO

=over

=item L<Template::Declare::Tags>

=item L<Template::Declare::TagSet>

=item L<Template::Declare::TagSet::HTML>

=item L<Template::Declare::TagSet::XUL>

=item L<Jifty>

=back

=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>

=head1 LICENSE

Template::Declare is Copyright 2006-2009 Best Practical Solutions, LLC.

Template::Declare is distributed under the same terms as Perl itself.

=cut

1;
