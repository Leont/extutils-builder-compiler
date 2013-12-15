package ExtUtils::Builder::Linker::Mach::GCC;

use Moo;

with 'ExtUtils::Builder::Role::Linker::Unixy';

sub _build_ld {
	return [qw/env MACOSX_DEPLOYMENT_TARGET=10.3 cc/];
}

sub _build_export {
	return 'all';
}

my %flag_for = (
	'loadable-object' => [qw/-bundle -undefined dynamic_lookup/],
	'shared-library'  => ['-dynamiclib'],
);

sub BUILD {
	my $self = shift;
	$self->add_argument(rank => 10, value => $flag_for{ $self->type }) if $flag_for{ $self->type };
	return;
}

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;
