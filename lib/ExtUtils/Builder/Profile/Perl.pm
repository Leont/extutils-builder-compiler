package ExtUtils::Builder::Profile::Perl;

use strict;
use warnings FATAL => 'all';

use ExtUtils::Helpers qw/split_like_shell/;

sub process_compiler {
	my ($class, $compiler, $config, $opts) = @_;
	$compiler->add_include_dirs([ File::Spec->catdir($config->get('archlibexp'), 'CORE') ], ranking => sub { $_[0] + 1 });
	$compiler->add_argument(ranking => 60, value => delete $opts->{ccflags} || [ split_like_shell($config->get('ccflags')) ]);
	$compiler->add_argument(ranking => 65, value => delete $opts->{optimize} || [ split_like_shell($config->get('optimize')) ]);
	return;
}

sub process_linker {
	my ($class, $linker, $config) = @_;
	$linker->add_argument(ranking => 60, value => [ split_like_shell($config->get('ldflags')) ]);
	return;
}

1;
