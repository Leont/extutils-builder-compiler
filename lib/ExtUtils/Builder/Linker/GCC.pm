package ExtUtils::Builder::Linker::GCC;

use Moo;

extends 'ExtUtils::Builder::Linker::Unixy';

has '+command' => (
	default => sub { 'gcc' },
);

has '+ccdlflags' => (
	default => sub { ['-Wl,-E'] },
);

has '+lddlflags' => (
	default => sub { ['-shared'] }
);

1;

