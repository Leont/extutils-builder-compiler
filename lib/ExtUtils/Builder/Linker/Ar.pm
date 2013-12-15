package ExtUtils::Builder::Linker::Ar;

use Moo;

use Carp ();

with 'ExtUtils::Builder::Role::Linker';

sub _build_ld {
	return ['ar'];
}

sub _build_export {
	return 'all';
}

has static_args => (
	is      => 'ro',
	default => sub { ['cr'] },
);

sub BUILD {
	my $self = shift;
	$self->add_argument(ranking =>  0, value => $self->static_args);
	return;
}

has _library_dirs => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => undef,
);

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	push @{ $self->_library_dirs }, @{$dirs};
	return;
}

has _libraries => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => undef,
);

sub add_libraries {
	my ($self, $libs, %opts) = @_;
	Carp::croak 'Can\'t add libraries to static link yet' if @{$libs};
	push @{ $self->_libraries }, @{$libs};
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	return (
		$self->new_argument(ranking => 10, value => [ $to ]),
		$self->new_argument(ranking => 75, value => [ @{$from} ]),
	);
}

1;
