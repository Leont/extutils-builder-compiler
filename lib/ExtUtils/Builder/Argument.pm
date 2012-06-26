package ExtUtils::Builder::Argument;

use Moo;

use Carp 'croak';

has ranking => (
	is      => 'rw',
	default => sub { 50 },
	isa     => sub { croak "$_[0] in not in range 0 .. 100" if $_[0] < 0 || $_[0] > 100 },
);

has value => (
	is       => 'rw',
	isa      => sub { croak 'value must be an array or a string: ' if ref($_[0]) ne 'ARRAY' },
	coerce   => sub { return ref $_[0] ? $_[0] : [ $_[0] ] },
	required => 1,
);

1;
