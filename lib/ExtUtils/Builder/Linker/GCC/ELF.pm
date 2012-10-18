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

1;


