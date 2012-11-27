package ExtUtils::Builder::Role::Linker::COFF;

use Moo::Role;# 1.000007

#with 'ExtUtils::Builder::Role::Linker::Shared';

my %export_for = (
	executable => 'none',
	'static-library' => 'all',
	'shared-library' => 'some',
	'loadable-object' => 'some',
);

sub _build_export {
	my $self = shift;
	return $export_for{ $self->type };
}

1;
