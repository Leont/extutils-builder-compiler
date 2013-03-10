package ExtUtils::Builder::Compiler::MSVC;

use Moo;

with qw/ExtUtils::Builder::Role::Compiler ExtUtils::Builder::Role::MultiLingual/;

use ExtUtils::Builder::Argument;

sub _build_cc {
	return ['cl'];
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "/I$_" } @{$dirs} ]);
	return;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	for my $key (keys %{$defines}) {
		my $value = defined $defines->{$key} ? $defines->{$key} ne '' ? "/D$key=$defines->{$key}" : "/D$key" : "/U$key";
		$self->add_argument(ranking => $self->fix_ranking(40, $opts{ranking}), value => [$value]);
	}
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;

	my @ret;
	push @ret, ExtUtils::Builder::Argument->new(ranking => 5,  value => ['/NOLOGO']);
	push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => [qw{/TP /EHsc}]) if $self->language eq 'C++';
	push @ret, ExtUtils::Builder::Argument->new(ranking => 75, value => [ "/Fo$to", '/c', $from ]);
	return @ret;
}

1;
