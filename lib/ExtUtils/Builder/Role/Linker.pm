package ExtUtils::Builder::Role::Linker;

use Moo::Role;

use Carp ();

with qw/ExtUtils::Builder::Role::Toolchain/;

has export => (
	is => 'ro',
	required => 1,
);

requires qw/link add_library_dirs add_libraries/;

1;

