package ExtUtils::Builder::Compiler::GCC;

use Moo;

extends 'ExtUtils::Builder::Compiler::Unixy';

has '+command' => (
	default => sub { 'gcc' },
);

has '+cccdlflags' => (
	default => sub { ['-fPIC'] },
);

1;
