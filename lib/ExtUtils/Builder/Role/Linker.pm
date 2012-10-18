package ExtUtils::Builder::Role::Linker;

use Moo::Role;

use ExtUtils::Builder::Role::Command;

with Command(method => 'link'), 'ExtUtils::Builder::Role::Toolchain';

requires qw/add_library_dirs add_libraries linker_flags/;

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return (
		$self->$orig($from, $to, %opts),
		$self->linker_flags($from, $to, %opts),
	);
};

1;

