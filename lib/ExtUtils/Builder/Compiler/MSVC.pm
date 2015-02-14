package ExtUtils::Builder::Compiler::MSVC;

use Moo;

with qw/ExtUtils::Builder::Role::Compiler ExtUtils::Builder::Role::MultiLingual/;

sub _build_cc {
	return ['cl'];
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 5,  value => ['/NOLOGO']);
	push @ret, $self->new_argument(ranking => 10, value => [qw{/TP /EHsc}]) if $self->language eq 'C++';
	push @ret, $self->new_argument(ranking => 75, value => [ "/Fo$to", '/c', $from ]);
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "/I$_->{value}" ]) } @{ $self->_include_dirs };
	for my $entry (@{ $self->_defines }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "/D$key=$entry->{value}" : "/D$key" : "/U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;
