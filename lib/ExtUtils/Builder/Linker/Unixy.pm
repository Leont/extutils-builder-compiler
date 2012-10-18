package ExtUtils::Builder::Linker::Unixy;

use Moo;

use ExtUtils::Builder::Argument;

with 'ExtUtils::Builder::Role::Linker::Shared';

has ccdlflags => (
	is => 'ro',
	required => 1,
);

has lddlflags => (
	is => 'ro',
	required => 1,
);

has '+export' => (
	default => sub {
		my $self = shift;
		return $self->type eq 'executable' ? 'none' : 'all';
	},
	lazy => 1,
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

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my $type = $self->type;
	my @ret;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => $self->lddlflags);
	}
	elsif ($type eq 'executable') {
		push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => $self->ccdlflags) if $self->export eq 'all';
	}
	else {
		croak("Unknown linkage type $type");
	}
	push @ret, ExtUtils::Builder::Argument->new(ranking => 50, value => [ '-o' => $to, @{$from} ]);
	return @ret;
}

has cpp_flags => (
	is => 'rw',
	default => sub {
		return [ '-lstdc++' ];
	},
);

around 'language_flags' => sub {
	my ($orig, $self, %opts) = @_;
	my @ret = $self->$orig(%opts);
	push @ret, ExtUtils::Builder::Argument->new(ranking => 76, value => $self->cpp_flags) if $self->language eq 'C++';
	return @ret;
};

1;

