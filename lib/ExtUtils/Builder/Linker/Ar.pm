package ExtUtils::Builder::Linker::Ar;

use Moo;

use Carp ();
use ExtUtils::Builder::Argument;
use ExtUtils::Builder::Role::Command;

with Command(method => 'link'), 'ExtUtils::Builder::Role::Linker';

has static_args => (
	is => 'ro',
	default => sub { 'cr' },
);

has _library_dirs => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	push @{ $self->_library_dirs }, @{$dirs};
	return;
}

has _libraries => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_libraries {
	my ($self, $libs, %opts) = @_;
	Carp::croak 'Can\'t add libraries to static link yet' if @{$libs};
	push @{ $self->_libraries }, @{$libs};
	return;
}

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return (
		$self->$orig,
		ExtUtils::Builder::Argument->new(ranking =>  0, value => $self->static_args),
		ExtUtils::Builder::Argument->new(ranking => 10, value => [ $to ]),
		ExtUtils::Builder::Argument->new(ranking => 75, value => [ @{$from} ]),
	);
};

1;
