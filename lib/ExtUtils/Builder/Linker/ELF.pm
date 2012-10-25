package ExtUtils::Builder::Linker::ELF;

use Moo;

use ExtUtils::Builder::Argument;

with 'ExtUtils::Builder::Role::Linker::Unixy';

has ccdlflags => (
	is => 'ro',
	required => 1,
);

has lddlflags => (
	is => 'ro',
	required => 1,
);

sub _build_export {
	my $self = shift;
	return $self->type eq 'executable' ? 'none' : 'all';
}

around 'linker_flags' => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => $self->lddlflags);
	}
	elsif ($type eq 'executable') {
		push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => $self->ccdlflags) if $self->export eq 'all';
	}
	else {
		croak("Unknown linkage type $type");
	}
	return @ret;
};

1;
