package ExtUtils::Builder::Role::Linker::Unixy;

use Moo::Role;

use ExtUtils::Builder::Argument;

with 'ExtUtils::Builder::Role::Linker::Shared';

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-L$_" } @{$dirs} ]);
	return;
}

sub add_libraries {
	my ($self, $libraries, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(75, $opts{ranking}), value => [ map { "-l$_" } @{$libraries} ]);
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	return ExtUtils::Builder::Argument->new(ranking => 50, value => [ '-o' => $to, @{$from} ]);
}

1;

