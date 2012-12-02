package ExtUtils::Builder::Dependency;

use Moo;

with 'ExtUtils::Builder::Role::Action::Delegated';

has target => (
	is       => 'ro',
	required => 1,
);

has _sources => (
	is       => 'ro',
	required => 1,
	init_arg => 'sources',
);

sub sources {
	my $self = shift;
	return @{ $self->_sources };
}

1;

