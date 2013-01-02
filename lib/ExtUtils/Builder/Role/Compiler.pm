package ExtUtils::Builder::Role::Compiler;

use Moo::Role;
use ExtUtils::Builder::Role::Command;

with Command(method => 'compile', source => 'single', profile_method => 'process_compiler', name => 'cc'), 'ExtUtils::Builder::Role::Toolchain';

requires qw/add_include_dirs add_defines language_flags compile_flags/;

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return ($self->$orig, $self->language_flags, $self->compile_flags($from, $to));
};

1;
