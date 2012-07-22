package ExtUtils::Builder::Role::Toolchain;

use Moo::Role;

has config => (
	is       => 'ro',
	required => 1,
);

has language => (
	is       => 'ro',
	required => 1,
);

my %allowed_types = map { ( $_ => 1) } qw/shared-library static-library loadable-object executable/;

has type => (
	is => 'ro',
	required => 1,
	isa => sub { defined $_[0] and $allowed_types{$_[0]} or Carp::confess((defined $_[0] ? $_[0] : 'undef') . ' is not an allowed linkage type') },
);

1;

