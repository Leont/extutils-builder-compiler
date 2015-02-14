package ExtUtils::Builder::Compiler::Unixy;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

sub _build_cc {
	return ['cc'];
}

has pic => (
	is      => 'lazy',
	default => sub {
		my $self = shift;
		return +($self->type eq 'shared-library' || $self->type eq 'loadable-object') && @{ $self->cccdlflags };
	},
);

has cccdlflags => (
	is       => 'ro',
	required => 1,
);

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 75, value => [ '-o' => $to, '-c', $from ]);
	push @ret, $self->new_argument(ranking => 45, value => $self->cccdlflags) if $self->pic;
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-I$_->{value}" ]) } @{ $self->_include_dirs };
	for my $entry (@{ $self->_defines }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "-D$key=$entry->{value}" : "-D$key" : "-U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;
