package ExtUtils::Builder::Role::Command;

use Moo::Role;

use ExtUtils::Builder::Argument;

has _arguments => (
	is      => 'ro',
	default => sub { [] },
);

sub add_argument {
	my ($self, %arguments) = @_;
	push @{ $self->_arguments }, ExtUtils::Builder::Argument->new(%arguments);
	return;
}

sub collect_arguments {
	my $self = shift;
	return @{ $self->_arguments };
}

sub arguments {
	my ($self, @args) = @_;
	use sort 'stable';
	return map { $_->value } sort { $a->ranking <=> $b->ranking } $self->collect_arguments(@args);
}

sub fix_ranking {
	my (undef, $baseline, $override) = @_;
	return $baseline if not defined $override;
	return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
}

1;
