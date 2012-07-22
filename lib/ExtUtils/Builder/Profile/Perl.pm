package ExtUtils::Builder::Profile::Perl;

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw/catdir/;

sub process_compiler {
	my ($class, $compiler, $config, $opts) = @_;
	$compiler->add_include_dirs([ catdir($config->get('archlibexp'), 'CORE') ], ranking => sub { $_[0] + 1 });
	$compiler->add_argument(ranking => 60, value => delete $opts->{ccflags} || $config->get('ccflags'));
	$compiler->add_argument(ranking => 65, value => delete $opts->{optimize} || $config->get('optimize'));
	return;
}

sub process_linker {
	my ($class, $linker, $config) = @_;
	$linker->add_argument(ranking => 60, value => $config->get('ldflags'));
	if ($linker->type eq 'executable' or $linker->type eq 'shared-library') {
		$linker->add_libraries(['perl']);
		$linker->add_library_dirs([ catdir($config->get('archlibexp'), 'CORE')]);
		$linker->add_argument(ranking => 80, value => $config->get('perllibs'));
	}
	return;
}

1;
