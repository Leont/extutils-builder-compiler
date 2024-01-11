package ExtUtils::Builder::Binary;

use strict;
use warnings;

use Carp qw//;

my %allowed_types = map { ($_ => 1) } qw/shared-library static-library loadable-object executable/;

sub _init {
	my ($self, %args) = @_;
	my $type = $args{type} or Carp::croak('No type given');
	$allowed_types{$type} or Carp::croak("$type is not an allowed linkage type");
	$self->{type} = $type;
	return;
}

sub type {
	my $self = shift;
	return $self->{type};
}

1;

# ABSTRACT: Helper role for classes producing binary objects
