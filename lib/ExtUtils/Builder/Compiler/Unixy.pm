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

sub BUILD {
	my $self = shift;
	$self->add_argument(ranking => 45, value => $self->cccdlflags) if $self->pic;
	return;
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-I$_" } @{$dirs} ]);
	return;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	for my $key (keys %{$defines}) {
		my $value = defined $defines->{$key} ? $defines->{$key} ne '' ? "-D$key=$defines->{$key}" : "-D$key" : "-U$key";
		$self->add_argument(ranking => $self->fix_ranking(40, $opts{ranking}), value => [$value]);
	}
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	return $self->new_argument(ranking => 75, value => [ '-o' => $to, '-c', $from ]);
}

1;
