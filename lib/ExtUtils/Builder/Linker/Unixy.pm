package ExtUtils::Builder::Linker::Unixy;

use Moo;

use Carp ();
use ExtUtils::Builder::Argument;
use ExtUtils::Builder::Role::Command;

with Command(method => 'link'), 'ExtUtils::Builder::Role::Linker';

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

has ccdlflags => (
	is => 'ro',
	required => 1,
);

has lddlflags => (
	is => 'ro',
	required => 1,
);

sub get_linker_flags {
	my ($self, %opts) = @_;
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		return $self->lddlflags;
	}
	elsif ($type eq 'executable') {
		return $self->export eq 'all' ? $self->ccdlflags : [];
	}
	else {
		croak("Unknown linkage type $type");
	}
}

has cpp_flags => (
	is => 'rw',
	default => sub {
		return [ '-lstdc++' ];
	},
);
sub get_language_flags {
	my $self = shift;
	return [] if $self->language eq 'C';
	return [ $self->cpp_flags ] if $self->language eq 'C++';
}

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return (
		$self->$orig,
		ExtUtils::Builder::Argument->new(ranking => 10, value => $self->get_linker_flags),
		ExtUtils::Builder::Argument->new(ranking => 50, value => [ '-o' => $to, @{$from} ]),
		ExtUtils::Builder::Argument->new(ranking => 75, value => $self->get_language_flags),
	);
};

1;

