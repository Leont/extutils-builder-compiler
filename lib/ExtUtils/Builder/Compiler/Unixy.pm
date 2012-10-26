package ExtUtils::Builder::Compiler::Unixy;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

use ExtUtils::Builder::Argument;

has '+command' => (
	default => sub { 'cc' },
);

has pic => (
	is => 'ro',
	default => sub {
		my $self = shift;
		return ($self->type eq 'shared-library' || $self->type eq 'loadable-object') && @{ $self->cccdlflags };
	},
	lazy => 1,
);

has cccdlflags => (
	is => 'ro',
	required => 1,
);

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
	return
		ExtUtils::Builder::Argument->new(ranking => 75, value => [ '-o' => $to, '-c', $from ]),
		$self->pic ? ExtUtils::Builder::Argument->new(ranking => 45, value => $self->cccdlflags) : ();
}

sub language_flags {
	my $self = shift;
	return $self->language eq 'C++' ? ExtUtils::Builder::Argument->new(ranking => 10, value => [qw/-x c++/]) : ();
}

1;
