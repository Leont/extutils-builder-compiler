package ExtUtils::Builder::ActionSet;

use Moo;

use Carp 'croak';

has _actions => (
	is       => 'ro',
	required => 1,
	init_arg => 'actions',
);

sub BUILDARGS {
	my ($self, @args) = @_;
	return { actions => \@args };
}

sub execute {
	my ($self, %opts) = @_;
	for my $action (@{ $self->_actions }) {
		$action->execute(%opts);
	}
	return;
}

sub serialize {
	my ($self, %opts) = @_;
	return map { [ $_->serialize(%opts) ] } @{ $self->_actions };
}

1;
