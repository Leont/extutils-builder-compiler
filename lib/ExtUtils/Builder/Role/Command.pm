package ExtUtils::Builder::Role::Command;

use Moo::Role;

has command => (
	is => 'ro',
	required => 1,
);

has _arguments => (
	is => 'ro',
	default => sub { [] },
	init_arg => 'arguments',
);

sub arguments {
	my $self = shift;
	return @{ $self->_arguments };
}

sub add_argument {
	my ($self, %opts) = @_;
	push @{ $self->_arguments }, ExtUtils::Builder::Argument->new(%opts);
	return;
}

sub _fix_ranking {
	my ($baseline, $override) = @_;
	return $baseline if not defined $override;
	return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
}

1;
