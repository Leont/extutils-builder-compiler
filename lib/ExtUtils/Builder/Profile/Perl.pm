package ExtUtils::Builder::Profile::Perl;

use strict;
use warnings;

use File::Spec::Functions qw/catdir/;
use Text::ParseWords 'shellwords';

sub _get_var {
	my ($config, $opts, $key) = @_;
	return delete $opts->{$key} || $config->get($key);
}

sub _split_var {
	my ($config, $opts, $key) = @_;
	return delete $opts->{$key} || [ shellwords($config->get($key)) ];
}

sub process_compiler {
	my ($class, $compiler, $opts) = @_;
	my $config = delete $opts->{config};
	my $incdir = catdir(_get_var($config, $opts, 'archlibexp'), 'CORE');
	$compiler->add_include_dirs([$incdir], ranking => sub { $_[0] + 1 });
	$compiler->add_argument(ranking => 60, value => _split_var($config, $opts, 'ccflags'));
	$compiler->add_argument(ranking => 65, value => _split_var($config, $opts, 'optimize'));
	return;
}

my $rpath_regex = qr/ ( (?<! \w ) (?: -Wl,-R | -Wl,-rpath | -R\ ? ) \S+ ) /x;

sub process_linker {
	my ($class, $linker, $opts) = @_;
	my $config = delete $opts->{config};
	$linker->add_argument(ranking => 60, value => _split_var($config, $opts, 'ldflags'));
	if ($linker->export eq 'some') {
		$linker->add_option_filter(sub {
			my ($self, $from, $to, %opts) = @_;
			$opts{dl_name} ||= $opts{module_name};
			return ($from, $to, %opts);
		});
	}
	if ($linker->type eq 'executable' or $linker->type eq 'shared-library') {
		if (_get_var($config, $opts, 'osname') eq 'MSWin32') {
			$linker->add_argument(value => _split_var($config, $opts, 'libperl'));
		}
		else {
			my ($libperl, $libext, $so) = map { _get_var($config, $opts, $_) } qw/libperl lib_ext so/;
			my ($lib) = $libperl =~ / \A (?:lib)? ( \w* perl \w* ) (?: \. $so | $libext) \b /msx;
			$linker->add_libraries([$lib]);
		}

		my $libdir = catdir(_get_var($config, $opts, 'archlibexp'), 'CORE');
		$linker->add_library_dirs([$libdir]);
		$linker->add_argument(ranking => 80, value => _split_var($config, $opts, 'perllibs'));
	}
	if ($linker->type eq 'executable') {
		my $rpath = $opts->{rpath} || [ shellwords($config->get('ccdlflags') =~ $rpath_regex) ];
		$linker->add_argument(ranking => 40, value => $rpath) if @{$rpath};
	}
	return;
}

1;
