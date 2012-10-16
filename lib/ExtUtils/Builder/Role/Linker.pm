package ExtUtils::Builder::Role::Linker;

use Moo::Role;

use ExtUtils::Builder::Role::Command;

with Command(method => 'link'), 'ExtUtils::Builder::Role::Toolchain';

requires qw/add_library_dirs add_libraries/;

1;

