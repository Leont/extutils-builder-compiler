package ExtUtils::Builder::Compiler::Unixy;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Compiler';

sub _init {
	my ($self, %args) = @_;
	$args{cc} //= ['cc'];
	$self->SUPER::_init(%args);
	$self->{cccdlflags} = $args{cccdlflags};
	$self->{pic} = $args{pic} // ($self->type eq 'shared-library' || $self->type eq 'loadable-object') && @{ $self->{cccdlflags} };
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 75, value => [ '-o' => $to, '-c', $from ]);
	push @ret, $self->new_argument(ranking => 45, value => $self->{cccdlflags}) if $self->{pic};
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-I$_->{value}" ]) } @{ $self->{include_dirs} };
	for my $entry (@{ $self->{defines} }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "-D$key=$entry->{value}" : "-D$key" : "-U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;

#ABSTRACT: Class for compiling with a unix compiler
