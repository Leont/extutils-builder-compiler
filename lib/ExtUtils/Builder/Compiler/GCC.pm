package ExtUtils::Builder::Compiler::GCC;

use Moo;

extends 'ExtUtils::Builder::Compiler::Unixy';

sub _build_cc {
	return ['gcc'];
}

has '+cccdlflags' => (
	default => sub { ['-fPIC'] },
);

1;
