package ExtUtils::Builder::Role::Linker;

use Moo::Role;

use Carp ();

with 'ExtUtils::Builder::Role::ToolchainCommand';

has export => (
	is => 'ro',
	predicate => '_has_export',
);

requires qw/link add_library_dirs add_libraries/;

1;

