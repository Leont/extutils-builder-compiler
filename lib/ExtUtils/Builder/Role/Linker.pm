package ExtUtils::Builder::Role::Linker;

use Moo::Role;

use ExtUtils::Builder::Role::Command;

with Command(method => 'link', source => 'multiple', profile_method => 'process_linker'), 'ExtUtils::Builder::Role::Toolchain';

requires qw/add_library_dirs add_libraries linker_flags/;

use Carp ();

my %allowed_export = map { $_ => 1 } qw/none some all/;
has export => (
	is => 'lazy',
	isa => sub {
		Carp::croak("$_[0] is not an allowed export value") if not $allowed_export{ $_[0] };
	},
);
requires '_build_export';

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return (
		$self->$orig($from, $to, %opts),
		$self->linker_flags($from, $to, %opts),
	);
};

1;

