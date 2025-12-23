package ExtUtils::Builder::BuildTools::FromPerl;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use ExtUtils::Config 0.007;
use ExtUtils::Builder::Util 0.018 qw/require_module split_like_shell/;
use File::Spec::Functions 'catfile';
use Perl::OSType 'is_os_type';

sub _is_gcc {
	my ($config, $cc, $opts) = @_;
	return $config->get('gccversion') || $cc =~ / ^ (?: gcc | g[+]{2} | clang (?: [+]{2} ) ) /ix;
}

sub _apply_profiles {
	my ($tool, $method, %args) = @_;

	$args{profiles} = [ delete $args{profile} ] if $args{profile} and not $args{profiles};
	if (my $profiles = $args{profiles}) {
		for my $profile (@$profiles) {
			if (not ref($profile)) {
				$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
				require_module($profile);
			}
			$profile->$method($tool, \%args);
		}
	}
}

my %gpp_map = (
	'cc' => 'c++',
	'gcc' => 'g++',
	'clang' => 'clang++',
);
my %is_gpp = reverse %gpp_map;

sub make_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $raw_cc = $opts->{config}->get('cc');
	my ($cc, @cc_extra) = ref $raw_cc ? @{$raw_cc} : split_like_shell($raw_cc);
	my ($module, %command) = is_os_type('Unix', $os) || _is_gcc($opts->{config}, $cc) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	$command{$_} = $opts->{$_} for grep { exists $opts->{$_} } qw/language type/;
	$command{cccdlflags} = [ split_like_shell($opts->{config}->get('cccdlflags')) ];
	my $module_name = "ExtUtils::Builder::Compiler::$module";

	my $language = $opts->{language} // 'C';
	if (uc $language eq 'C++') {
		if ($module_name->isa('ExtUtils::Builder::Compiler::Unixy')) {
			push @{ $command{extra_flags} }, qw/-xc++/ if _is_gcc($opts->{config}, $cc);
			$cc = $gpp_map{$cc} // croak "Don't know C++ compiler for $cc" unless $is_gpp{$cc};
		} elsif (!$module_name->isa('ExtUtils::Builder::Compiler::MSVC')) {
			croak "Can't find C++ compiler for your platform"
		}
	} elsif (uc $language ne 'C') {
		croak "Unknown language $language";
	}

	require_module($module_name);
	return $module_name->new(cc => [$cc, @cc_extra], %command);
}

sub _unix_flags {
	my ($self, $opts) = @_;
	return $opts->{lddlflags} if defined $opts->{lddlflags};
	my $lddlflags = $opts->{config}->get('lddlflags');
	my $optimize = $opts->{config}->get('optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not $opts->{auto_optimize};
	my %ldflags = map { ($_ => 1) } split_like_shell($opts->{config}->get('ldflags'));
	my @lddlflags = grep { not $ldflags{$_} } split_like_shell($lddlflags);
	return (lddlflags => \@lddlflags )
}

sub make_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $raw_cc = $opts->{config}->get('cc');
	my ($cc, @cc_extra) = ref $raw_cc ? @{$raw_cc} : split_like_shell($raw_cc);
	my $raw_ld = $opts->{config}->get('ld');
	my ($ld, @ld_extra) = ref $raw_ld ? @{$raw_ld} : split_like_shell($raw_ld);
	my ($eff_ld, @eff_extra) = ($opts->{type} eq 'executable') ? ($cc, @cc_extra) : ($ld, @ld_extra);
	my ($module, $link, $extra, %command) =
		$opts->{type} eq 'static-library' ? ('Ar', $opts->{config}->get('ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $eff_ld, \@eff_extra) :
		_is_gcc($opts->{config}, $ld) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc, \@cc_extra) : ('ELF::GCC', $eff_ld, \@eff_extra) :
		$os eq 'aix' ? ('XCOFF', $cc, \@cc_extra) :
		is_os_type('Unix', $os) ? ('ELF::Any', $eff_ld, \@eff_extra, $self->_unix_flags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld, \@ld_extra) :
		croak 'Linking is not supported yet on your platform';
	$command{$_} = $opts->{$_} for grep { exists $opts->{$_} } qw/exports language type/;
	my $module_name = "ExtUtils::Builder::Linker::$module";

	my $language = $opts->{language} // 'C';
	if (uc $language eq 'C++') {
		my $prefix = 'ExtUtils::Builder::Linker:';
		if ($module->isa("$prefix:ELF::GCC") || $module->isa("$prefix:Mach::GCC") || $module->isa("$prefix:PE::GCC")) {
			$link = $gpp_map{$link} // croak "Don't know C++ compiler for $link" unless $is_gpp{$link};
		} elsif (!$module->isa("$prefix:PE::MSVC") && !$module->isa("$prefix:Ar")) {
			croak "Can't find C++ linker for your platform"
		}
	} elsif (uc $language ne 'C') {
		croak "Unknown language $language";
	}

	require_module($module_name);
	return $module_name->new(ld => [ $link, @{$extra} ], %command);
}

sub add_methods {
	my ($class, $planner, %opts) = @_;

	$opts{config} //= $planner->can('config') ? $planner->config : ExtUtils::Config->new;
	$opts{type} //= 'executable';

	my $compiler_as = delete $opts{compiler_as} // 'compile';
	$planner->add_delegate($compiler_as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);

		my $compiler = $class->make_compiler(\%args);

		_apply_profiles($compiler, 'process_compiler', %args);

		if (my $include_dirs = $args{include_dirs}) {
			$compiler->add_include_dirs($include_dirs);
		}
		if (my $defines = $args{defines}) {
			$compiler->add_defines($defines);
		}
		if (my $extra = $args{extra_args}) {
			$compiler->add_argument(value => $extra);
		}
		if (my $standard = $args{standard}) {
			$compiler->set_standard($standard);
		}

		my $node = $compiler->compile($from, $to, %args);
		$planner->add_node($node);
	});

	my $linker_as = delete $opts{linker_as} // 'link';
	$planner->add_delegate($linker_as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);

		my $linker = $class->make_linker(\%args);

		_apply_profiles($linker, 'process_linker', %args);

		if (my $library_dirs = $args{library_dirs}) {
			$linker->add_library_dirs($library_dirs);
		}
		if (my $libraries = $args{libraries}) {
			$linker->add_libraries($libraries);
		}
		if (my $extra_args = $args{extra_args}) {
			$linker->add_argument(ranking => 85, value => [ @{$extra_args} ]);
		}

		my $node = $linker->link($from, $to, %args);
		$planner->add_node($node);
	});

	my %extensions = (
		object_file         => $opts{config}->get('_o'),
		library_file        => '.' . $opts{config}->get('so'),
		static_library_file => $opts{config}->get('_a'),
		loadable_file       => '.' . $opts{config}->get('dlext'),
		executable_file     => $opts{config}->get('_exe'),
	);

	for my $name (qw/object_file library_file static_library_file loadable_file executable_file/) {
		my $tail = $extensions{$name};
		$planner->add_delegate($name, sub {
			my ($planner, $file, $dir) = @_;
			my $filename = $file . $tail;
			return defined $dir ? catfile($dir, $filename) : $filename;
		});
	}
	# backwards compatability
	$planner->add_delegate('obj_file', sub {
		my ($this, @args) = @_;
		return $this->object_file(@args);
	});

	return;
}

1;

#ABSTRACT: compiler configuration, derived from perl's configuration

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->load_extension('ExtUtils::Builder::BuildTools::FromPerl', '0.034',
	profiles => ['@Perl'],
	type     => 'loadable-object',
 );
 $planner->compile('foo.c', 'foo.o', include_dirs => ['.']);
 $planner->link([ 'foo.o' ], 'foo.so', libraries => ['foo']);
 my $plan = $planner->materialize;
 $plan->run(['foo.so']);

=head1 DESCRIPTION

This module is a L<ExtUtils::Builder::Planner::Extension|ExtUtils::Builder::Planner::Extension> that facilitates compiling object.

=method add_methods(%options)

This adds two delegate methods to the planner, C<compile> and C<link>. It takes named arguments that will be prefixed to the named arguments for all delegate calls. In practice, it's mainly useful with the C<config>, C<profile> and C<type> arguments.

If your C<$planner> has a C<config> delegate, that will be used as default value for C<config>.

This is usually not called directly, but through L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner>'s C<load_extension> method.

=head1 DELEGATES

=head2 compile($source, $target, %options)

This compiles C<$source> to C<$target>. It takes the following optional arguments:

=over 4

=item type

The type of the final product. This must be one of:

=over 4

=item * executable

An executable to be run. This is the default.

=item * static-library

A static library to link against.

=item * dynamic-library

A dynamic library to link against.

=item * loadable-object

A loadable extension. On most platforms this is the same as a dynamic library, but some (Mac) make a distinction between these two.

=back

=item config

A Perl configuration to take hints from, must be an C<ExtUtils::Config> compatible object.

=item profiles

A list of profile that can be used when compiling and linking. One profile comes with this distribution: C<'@Perl'>, which sets up the appropriate things to compile/link with C<libperl>.

=item include_dirs

A list of directories to add to the include path, e.g. C<['include', '.']>.

=item define

A hash of preprocessor defines, e.g. C<< {DEBUG => 1, HAVE_FEATURE => 0 } >>

=item language

The language to use for compilation. Valid values are C<"C"> or C<"C++">.

=item standard

The language standard to use, e.g. C<"c99">, C<"c11">.

=item extra_args

A list of additional arguments to the compiler.

=back

=method link(\@sources, $target, %options)

=over 4

=item type

This works the same as with C<compile>.

=item config

This works the same as with C<compile>.

=item profile

This works the same as with C<compile>.

=item language

This works the same as with C<compile>.

=item libraries

A list of libraries to link to. E.g. C<['z']>.

=item library_dirs

A list of directories to find libraries in. E.g. C<['/opt/my-app/lib/']>.

=item extra_args

A list of additional arguments to the linker.

=back
