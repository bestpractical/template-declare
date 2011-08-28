package My::Other::Template;
use base 'Template::Declare';
use Template::Declare::Tags;

__PACKAGE__->import_template_files();

1;
