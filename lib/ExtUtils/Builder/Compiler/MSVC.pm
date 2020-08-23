package ExtUtils::Builder::Compiler::MSVC;

use strict;
use warnings;

use base qw/ExtUtils::Builder::Compiler ExtUtils::Builder::MultiLingual/;

sub _init {
	my ($self, %args) = @_;
	$args{cc} ||= ['cl'];
	$self->ExtUtils::Builder::Compiler::_init(%args);
	$self->ExtUtils::Builder::MultiLingual::_init(%args);
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 5,  value => ['/NOLOGO']);
	push @ret, $self->new_argument(ranking => 10, value => [qw{/TP /EHsc}]) if $self->language eq 'C++';
	push @ret, $self->new_argument(ranking => 75, value => [ "/Fo$to", '/c', $from ]);
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "/I$_->{value}" ]) } @{ $self->{include_dirs} };
	for my $entry (@{ $self->{defines} }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "/D$key=$entry->{value}" : "/D$key" : "/U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;
