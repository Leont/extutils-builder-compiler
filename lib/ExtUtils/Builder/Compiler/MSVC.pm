package ExtUtils::Builder::Compiler::MSVC;

use Moo;

with qw/ExtUtils::Builder::Role::Compiler ExtUtils::Builder::Role::MultiLingual/;

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

sub BUILD {
	my $self = shift;
	$self->add_argument(ranking => 5,  value => ['/NOLOGO']);
	$self->add_argument(ranking => 10, value => [qw{/TP /EHsc}]) if $self->language eq 'C++';
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	return $self->new_argument(ranking => 75, value => [ "/Fo$to", '/c', $from ]);
}

1;
