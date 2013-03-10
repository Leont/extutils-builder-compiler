package ExtUtils::Builder::AutoDetect::Cpp;

use Moo;
extends 'ExtUtils::Builder::AutoDetect::C';

around _get_compiler => sub {
	my ($orig, $self, $opts) = @_;
	my $os = $opts->{osname} || $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->$orig({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->$orig({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
};

around _get_linker => sub {
	my ($orig, $self, $opts) = @_;
	my $os = $opts->{osname} || $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->$orig({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->$orig({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
	return;
};

1;
