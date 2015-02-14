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

override 'add_libraries' => sub {
	my ($orig, $self, $libs, %opts) = @_;
	Carp::croak 'Can\'t add libraries to static link yet' if @{$libs};
	push @{ $self->_libraries }, @{$libs};
	return;
};

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking =>  0, value => $self->static_args);
	push @ret, $self->new_argument(ranking => 10, value => [ $to ]),
	push @ret, $self->new_argument(ranking => 75, value => [ @{$from} ]),
	return @ret;
}

1;
