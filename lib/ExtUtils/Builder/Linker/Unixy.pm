package ExtUtils::Builder::Linker::Unixy;

use Moo;

use ExtUtils::Builder::Argument;

with 'ExtUtils::Builder::Role::Linker::Shared';

has '+prelinking' => (
	default => sub { 0 },
);

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => _fix_ranking(30, $opts{ranking}), value => [ map { "-L$_" } @{$dirs} ]);
	return;
}

sub add_libraries {
	my ($self, $libraries, %opts) = @_;
	$self->add_argument(ranking => _fix_ranking(75, $opts{ranking}), value => [ map { "-l$_" } @{$libraries} ]);
	return;
}

sub file_flags {
	my ($self, $from, $to, %opts) = @_;
	return ExtUtils::Builder::Argument->new(ranking => 50, value => [ '-o' => $to, @{$from} ]),
}

has cpp_flags => (
	is => 'rw',
	default => sub {
		return [ '-lstdc++' ];
	},
);

sub language_flags {
	my $self = shift;
	return if $self->language eq 'C';
	return ExtUtils::Builder::Argument->new(ranking => 76, value => $self->cpp_flags) if $self->language eq 'C++';
}

1;

