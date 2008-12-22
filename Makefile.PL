use inc::Module::Install;

name            'Template-Declare';
license         'perl';
author          'Jesse Vincent <jesse@bestpractical.com>';
all_from        'lib/Template/Declare.pm';

requires perl => '5.8.2';

build_requires  'HTML::Lint';
build_requires  'Test::More';
build_requires  'Test::Warn';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Class::ISA';

WriteAll;
