package ExtUtils::Builder::Role::Linker::COFF;

use strict;
use warnings;

use base 'ExtUtils::Builder::Role::Linker';

my %export_for = (
	executable        => 'none',
	'static-library'  => 'all',
	'shared-library'  => 'some',
	'loadable-object' => 'some',
);

sub _init {
	my ($self, %args) = @_;
	$args{export} ||= $export_for{ $args{type} };
	$self->SUPER::_init(%args);
	$self->{autoimport} = defined $args{autoimport} ? $args{autoimport} : 1;
	return;
}

sub autoimport {
	my $self = shift;
	return $self->{autoimport};
}

1;
