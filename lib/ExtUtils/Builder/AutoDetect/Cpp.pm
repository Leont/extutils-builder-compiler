package ExtUtils::Builder::AutoDetect::Cpp;

use strict;
use warnings;

use base 'ExtUtils::Builder::AutoDetect::C';

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{osname} || $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->SUPER::_get_compiler({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->SUPER::_get_compiler({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{osname} || $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->SUPER::_get_linker({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->SUPER::_get_linker({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
	return;
}

1;
