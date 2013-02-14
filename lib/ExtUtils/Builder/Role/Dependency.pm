package ExtUtils::Builder::Role::Dependency;

use Moo::Role;

has target => (
	is       => 'ro',
	required => 1,
);

has _dependencies => (
	is       => 'ro',
	required => 1,
	init_arg => 'dependencies',
);

sub dependencies {
	my $self = shift;
	return @{ $self->_dependencies };
}

1;
