package ExtUtils::Builder::ArgumentCollector;

use strict;
use warnings;

sub _init {
	my ($self, %args) = @_;
	$self->{arguments} = $args{arguments} || [];
	return;
}

sub add_argument {
	my ($self, %arguments) = @_;
	$arguments{ranking} = $self->fix_ranking(delete @arguments{qw/ranking fix/});
	push @{ $self->{arguments} }, $self->new_argument(%arguments);
	return;
}

sub new_argument {
	my ($self, %args) = @_;
	return [ $args{ranking} || 50, $args{value} ];
}

sub collect_arguments {
	my $self = shift;
	return @{ $self->{arguments} };
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
