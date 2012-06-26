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
	my @actions = @{ $self->_actions };
	for my $action (@actions) {
		$action->execute(%opts);
	}
	return;
}

sub oneliners {
	my ($self, %opts) = @_;
	return map { $_->oneliner } @{ $self->_actions };
}

1;
