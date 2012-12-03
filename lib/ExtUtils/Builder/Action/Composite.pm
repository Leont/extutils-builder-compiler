package ExtUtils::Builder::Action::Composite;

use Moo;

with 'ExtUtils::Builder::Role::Action';

has _actions => (
	is       => 'ro',
	required => 1,
	init_arg => 'actions',
	coerce   => sub { [ map { $_->flatten } @{ $_[0] } ] },
);

sub execute {
	my ($self, %opts) = @_;
	$_->execute(%opts) for $self->flatten;
	return;
}

sub serialize {
	my ($self, %opts) = @_;
	return map { $_->serialize(%opts) } $self->flatten;
}

around flatten => sub {
	my ($orig, $self) = @_;
	return @{ $self->_actions };
};

1;
