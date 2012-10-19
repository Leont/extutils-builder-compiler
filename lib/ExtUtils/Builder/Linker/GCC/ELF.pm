package ExtUtils::Builder::Linker::GCC::ELF;

use Moo;

extends 'ExtUtils::Builder::Linker::ELF';

has '+command' => (
	default => sub { 'gcc' },
);

has '+ccdlflags' => (
	default => sub { ['-Wl,-E'] },
);

has '+lddlflags' => (
	default => sub { ['-shared'] }
);

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;


