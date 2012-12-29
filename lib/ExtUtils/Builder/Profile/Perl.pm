package ExtUtils::Builder::Profile::Perl;

use strict;
use warnings FATAL => 'all';

use ExtUtils::Helpers qw/split_like_shell/;
use File::Spec::Functions qw/catdir/;

sub _get_var {
	my ($config, $opts, $key) = @_;
	return delete $opts->{$key} || [ split_like_shell($config->get($key)) ];
}

sub process_compiler {
	my ($class, $compiler, $opts) = @_;
	my $config = delete $opts->{config};
	$compiler->add_include_dirs([ catdir($config->get('archlibexp'), 'CORE') ], ranking => sub { $_[0] + 1 });
	$compiler->add_argument(ranking => 60, value => _get_var($config, $opts, 'ccflags'));
	$compiler->add_argument(ranking => 65, value => _get_var($config, $opts, 'optimize'));
	return;
}

my $rpath_regex = qr/ ( (?<! \w ) (?: -Wl,-R | -Wl,-rpath | -R\ ? ) \S+ ) /x;

sub process_linker {
	my ($class, $linker, $opts) = @_;
	my $config = delete $opts->{config};
	$linker->add_argument(ranking => 60, value => _get_var($config, $opts, 'ldflags'));
	if ($linker->export eq 'some') {
		$linker->add_option_filter(sub {
			my ($self, $from, $to, %opts) = @_;
			$opts{dl_name} ||= $opts{module_name};
			return ($from, $to, %opts);
		});
	}
	if ($linker->type eq 'executable' or $linker->type eq 'shared-library') {
		my ($libperl, $so) = map { $opts->{$_} || $config->get($_) } qw/libperl so/;
		my ($lib) = $libperl =~ / \A (?:lib)? ( perl \w* ) \. $so \z /msx;
		$linker->add_libraries([$lib]);
		$linker->add_library_dirs([ catdir($config->get('archlibexp'), 'CORE')]);
		$linker->add_argument(ranking => 80, value => _get_var($config, $opts, 'perllibs'));
	}
	if ($linker->type eq 'executable') {
		my $rpath = $opts->{rpath} || [ split_like_shell($config->get('ccdlflags') =~ $rpath_regex) ];
		$linker->add_argument(ranking => 40, value => $rpath) if @{$rpath};
	}
	return;
}

1;
