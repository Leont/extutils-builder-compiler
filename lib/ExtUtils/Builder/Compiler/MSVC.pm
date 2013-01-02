package ExtUtils::Builder::Compiler::MSVC;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

use ExtUtils::Builder::Argument;

has '+cc' => (
	default => sub { ['cl'] },
);

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "/I$_" } @{$dirs} ]);
	return;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	for my $key (keys %{$defines}) {
		my $value = defined $defines->{$key} ? $defines->{$key} ne '' ? "/D$key=$defines->{$key}" : "/D$key" : "/U$key";
		$self->add_argument(ranking => $self->fix_ranking(40, $opts{ranking}), value => [ $value ]);
	}
	return;
}

sub language_flags {
	my $self = shift;
	return $self->language eq 'C++' ? ExtUtils::Builder::Argument->new(ranking => 10, value => [qw{/TP /EHsc}]) : ();
}

sub compile_flags {
	my ($self, $from, $to) = @_;

	return map { ExtUtils::Builder::Argument->new($_) } { ranking => 5, value => [ '/NOLOGO' ] }, { ranking => 75, value => [ "/Fo$to", '/c', $from ]};
}

1;
