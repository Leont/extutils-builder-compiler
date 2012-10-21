package ExtUtils::Builder::Linker::GCC::Darwin;

use Moo;

with 'ExtUtils::Builder::Role::Linker::Unixy';

has '+command' => (
	default => sub { 'gcc' },
);

has '+export' => (
	default => sub { 'all' },
);

my %flag_for = (
	'loadable-object' => [ qw/-bundle -undefined dynamic_lookup/ ],
	'shared-library' => [ '-dynamiclib' ],
);

around 'linker_flags' => sub {
	my ($orig, $self, %opts) = @_;
	my @ret = $self->$orig(%opts);
	push @ret, ExtUtils::Builder::Arguments->new(rank => 10, value => $flag_for{ $self->type }) if $flag_for{ $self->type };
	return @ret;
};

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;
