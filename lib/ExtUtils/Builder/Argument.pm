package ExtUtils::Builder::Argument;

use Moo;

use Carp 'croak';

has ranking => (
	is      => 'ro',
	default => sub { 50 },
	isa     => sub { croak "$_[0] in not in range 0 .. 100" if $_[0] < 0 || $_[0] > 100 },
);

has _value => (
	is       => 'ro',
	isa      => sub { croak 'value must be an array or a string: ' if ref($_[0]) ne 'ARRAY' },
	init_arg => 'value',
	required => 1,
);

sub value {
	my $self = shift;
	return @{ $self->_value };
}

1;
