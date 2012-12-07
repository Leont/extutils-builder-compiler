package ExtUtils::Builder::Plan;

use Moo;

with 'ExtUtils::Builder::Role::Action::Composite';

has target => (
	is       => 'ro',
	required => 1,
);

has _dependencies => (
	is       => 'ro',
	required => 1,
	init_arg => 'dependencies',
);

sub sources {
	my $self = shift;
	return @{ $self->_sources };
}

1;

