package ExtUtils::Builder::Role::Compiler;

use Moo::Role;

with 'ExtUtils::Builder::Role::ToolchainCommand';

requires qw/compile add_include_dirs add_defines/;

1;
