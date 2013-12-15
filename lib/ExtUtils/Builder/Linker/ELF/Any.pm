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

sub BUILD {
	my $self = shift;
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		$self->add_argument(ranking => 10, value => $self->lddlflags);
	}
	elsif ($type eq 'executable') {
		$self->add_argument(ranking => 10, value => $self->ccdlflags) if $self->export eq 'all';
	}
	else {
		croak("Unknown linkage type $type");
	}
	return;
}

1;
