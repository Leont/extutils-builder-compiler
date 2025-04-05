package ExtUtils::Builder::Profile::Perl;

use strict;
use warnings;

use ExtUtils::Helpers 0.027 'split_like_shell';
use File::Spec::Functions qw/catdir/;

sub _get_var {
	my ($config, $opts, $key) = @_;
	return delete $opts->{$key} // $config->get($key);
}

sub _split_var {
	my ($config, $opts, $key) = @_;
	return delete $opts->{$key} // [ split_like_shell($config->get($key)) ];
}

sub process_compiler {
	my ($class, $compiler, $opts) = @_;
	my $config = delete $opts->{config};
	my $incdir = catdir(_get_var($config, $opts, 'archlibexp'), 'CORE');
	my $os = _get_var($config, $opts, 'osname');
	my $osver = _get_var($config, $opts, 'osvers');
	my ($osmajor) = $osver =~ /^(\d+)/;
	if ($os eq 'darwin' && $^X eq '/usr/bin/perl' && $osmajor >= 18) {
		$compiler->add_argument(value => [ '-iwithsysroot', $incdir ], ranking => $compiler->default_include_ranking + 1);
	} else {
		$compiler->add_include_dirs([$incdir], ranking => sub { $_[0] + 1 });
	}
	$compiler->add_argument(ranking => 60, value => _split_var($config, $opts, 'ccflags'));
	$compiler->add_argument(ranking => 65, value => _split_var($config, $opts, 'optimize'));
	return;
}

my $rpath_regex = qr/ ( (?<! \w ) (?: -Wl,-R | -Wl,-rpath | -R\ ? ) \S+ ) /x;

my %needs_relinking = map { $_ => 1 } qw/MSWin32 cygwin aix VMS/;

sub process_linker {
	my ($class, $linker, $opts) = @_;
	my $config = delete $opts->{config};
	$linker->add_argument(ranking => 60, value => _split_var($config, $opts, 'ldflags'));
	if ($linker->export eq 'some') {
		$linker->add_option_filter(sub {
			my ($self, $from, $to, %opts) = @_;
			$opts{dl_name} //= $opts{module_name} if $opts{module_name};
			$opts{dl_file} //= do {
				(my $short = $opts{dl_name}) =~ s/.*:://;
				catdir(dirname($from), "$short.def");
			};
			return ($from, $to, %opts);
		});
	}
	my $os = _get_var($config, $opts, 'osname');
	if ($linker->type eq 'executable' or $linker->type eq 'shared-library' or ($linker->type eq 'loadable-object' and $needs_relinking{$os})) {
		my ($libperl, $libext, $so) = map { _get_var($config, $opts, $_) } qw/libperl lib_ext so/;
		my ($lib) = $libperl =~ / \A (?:lib)? ( \w* perl \w* ) (?: \. $so | $libext) \b /msx;
		$linker->add_libraries([$lib], ranking => sub { $_[0] - 1 });

		my $libdir = catdir(_get_var($config, $opts, 'archlibexp'), 'CORE');
		$linker->add_library_dirs([$libdir]);
		$linker->add_argument(ranking => 80, value => _split_var($config, $opts, 'perllibs'));
	}
	if ($linker->type eq 'executable') {
		my $rpath = $opts->{rpath} // [ split_like_shell($config->get('ccdlflags') =~ $rpath_regex) ];
		$linker->add_argument(ranking => 40, value => $rpath) if @{$rpath};
	}
	return;
}

1;

# ABSTRACT: A profile for compiling and linking against perl

=head1 SYNOPSIS

 $planner->load_extension('ExtUtils::Builder::AutoDetect::C',
    profile => '@Perl',
 );

=head1 DESCRIPTION

This is a profile for compiling against perl, whether you're compiling an XS extension or embedding it into your application.
