package ExtUtils::Builder::Linker::Ar;

use strict;
use warnings;

use Carp ();

use base 'ExtUtils::Builder::Role::Linker';

sub _init {
	my ($self, %args) = @_;
	$args{ld} ||= ['ar'];
	$args{export} ||= 'all';
	$self->SUPER::_init(%args);
	$self->{static_args} = $args{static_args} || ['cr'];
	return;
}

sub add_libraries {
	my ($self, $libs, %opts) = @_;
	Carp::croak 'Can\'t add libraries to static link yet' if @{$libs};
	push @{ $self->_libraries }, @{$libs};
	return;
};

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking =>  0, value => $self->static_args);
	push @ret, $self->new_argument(ranking => 10, value => [ $to ]),
	push @ret, $self->new_argument(ranking => 75, value => [ @{$from} ]),
	return @ret;
}

1;
