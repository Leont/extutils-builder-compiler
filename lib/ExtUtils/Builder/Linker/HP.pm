package ExtUtils::Builder::Linker::HP;

use Moo;

extends 'ExtUtils::Builder::Linker::ELF';

has '+ccdlflags' => (
	default => sub { [qw/-E -B deferred/] },
);

has '+lddlflags' => (
	default => sub { [qw/-b +vnocompatwarnings/] },
);

around 'linker_flags' => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @from = (('/usr/ccs/lib/crt0.o') x ($self->type eq 'executable'), @{$from});
	return $self->$orig(\@from, $to, %opts);
};

1;

