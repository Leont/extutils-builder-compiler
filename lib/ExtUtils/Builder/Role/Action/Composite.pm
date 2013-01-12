package ExtUtils::Builder::Role::Action::Composite;

use Moo::Role;

with 'ExtUtils::Builder::Role::Action';

sub _build_preference_map {
	return {
		flatten => 3,
		execute => 2,
		command => 1,
		code    => 0,
	};
}

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

sub to_code {
	my ($self, %opts) = @_;
	return map { $_->to_code(%opts) } $self->flatten;
}

sub to_command {
	my ($self, %opts) = @_;
	return map { $_->to_command(%opts) } $self->flatten;
}

around flatten => sub {
	my ($orig, $self) = @_;
	return @{ $self->_actions };
};

1;
