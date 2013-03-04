package ExtUtils::Builder::Role::Compiler;

use Moo::Role;
use ExtUtils::Builder::Role::Command;

with Command(method => 'compile', source => 'single', profile_method => 'process_compiler', name => 'cc'), 'ExtUtils::Builder::Role::Binary';

requires qw/add_include_dirs add_defines compile_flags/;

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return ($self->$orig, $self->compile_flags($from, $to));
};

1;
