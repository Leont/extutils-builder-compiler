package ExtUtils::Builder::Linker::GCC::Darwin;

use Moo;

with 'ExtUtils::Builder::Role::Linker::Unixy';

has '+command' => (
	default => sub { 'gcc' },
);

has '+export' => (
	default => sub { 'implicit' },
);

my %flag_for = (
	'loadable-object' => '-bundle',
	'shared-library' => '-dynamiclib',
);

around 'linker_flags' => sub {
	my ($orig, $self, %opts) = @_;
	my @ret = $self->$orig(%opts);
	push @ret, ExtUtils::Builder::Arguments->new(rank => 10, value => [ $flag_for{ $self->type }, qw/-undefined dynamic_lookup/ ]) if $flag_for{ $self->type };
	return @ret;
};

1;
