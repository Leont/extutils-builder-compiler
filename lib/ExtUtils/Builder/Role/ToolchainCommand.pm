package ExtUtils::Builder::Role::ToolchainCommand;

use Moo::Role;

with 'ExtUtils::Builder::Role::Command';

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
	isa => sub { defined $_[0] and $allowed_types{$_[0]} or Carp::croak("$_[0] is not an allowed linkage type") },
);

1;

