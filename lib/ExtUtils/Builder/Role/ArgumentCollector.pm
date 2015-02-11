package ExtUtils::Builder::Role::ArgumentCollector;

use Moo::Role;

has _arguments => (
	is      => 'ro',
	default => sub { [] },
);

sub add_argument {
	my ($self, %arguments) = @_;
	$arguments{ranking} = $self->fix_ranking(delete @arguments{qw/ranking fix/});
	push @{ $self->_arguments }, $self->new_argument(%arguments);
	return;
}

sub new_argument {
	my ($self, %args) = @_;
	return [ $args{ranking} || 50, $args{value} ];
}

sub collect_arguments {
	my $self = shift;
	return @{ $self->_arguments };
}

sub arguments {
	my ($self, @args) = @_;
	use sort 'stable';
	return map { @{ $_->[1] } } sort { $a->[0] <=> $b->[0] } $self->collect_arguments(@args);
}

sub fix_ranking {
	my (undef, $baseline, $override) = @_;
	return $baseline if not defined $override;
	return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
}

1;
