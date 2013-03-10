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

around 'linker_flags' => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	push @ret, ExtUtils::Builder::Argument->new(rank => 10, value => $flag_for{ $self->type }) if $flag_for{ $self->type };
	return @ret;
};

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;
