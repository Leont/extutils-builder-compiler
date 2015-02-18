package ExtUtils::Builder::Linker::ELF::Any;

use Moo;

with 'ExtUtils::Builder::Role::Linker::Unixy';

sub _build_ld {
	return ['cc'];
}

has ccdlflags => (
	is       => 'ro',
	required => 1,
);

has lddlflags => (
	is       => 'ro',
	required => 1,
);

sub _build_export {
	my $self = shift;
	return $self->type eq 'executable' ? 'none' : 'all';
}

override linker_flags => sub {
	my ($orig, $self, %args) = @_;
	my @ret = $self->$orig(%args);

	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		push @ret, $self->new_argument(ranking => 10, value => $self->lddlflags);
	}
	elsif ($type eq 'executable') {
		push @ret, $self->new_argument(ranking => 10, value => $self->ccdlflags) if $self->export eq 'all';
	}
	else {
		croak("Unknown linkage type $type");
	}
	return @ret;
};

1;
