package ExtUtils::Builder::Linker::GCC;

use Moo;

extends 'ExtUtils::Builder::Linker::Unixy';

has '+ccdlflags' => (
	default => sub { ['-Wl,-E'] },
);

has '+lddlflags' => (
	default => sub { ['-shared'] }
);

1;

