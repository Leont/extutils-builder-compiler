package ExtUtils::Builder::AutoDetect::C;

use strict;
use warnings;

use Carp 'croak';
use ExtUtils::Config 0.007;
use Perl::OSType 'is_os_type';
use Text::ParseWords 'shellwords';

sub _split_conf {
	my ($config, $name) = @_;
	return shellwords($config->get($name));
}

sub _make_command {
	my ($self, $shortname, $argument, $command, %options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	require_module($module);
	my @command = ref $command ? @{$command} : shellwords($command);
	return $module->new($argument => \@command, %options);
}

sub _is_gcc {
	my ($config, $cc, $opts) = @_;
	return $config->get('gccversion') || $cc =~ / ^ g(?: cc | [+]{2} ) /ix;
}

sub _filter_args {
	my ($opts, @names) = @_;
	return map { $_ => $opts->{$_} } grep { exists $opts->{$_} } @names;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $cc = $opts->{config}->get('cc');
	my ($module, %extra) = is_os_type('Unix', $os) || _is_gcc($opts->{config}, $cc, $opts) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	my %args = _filter_args($opts, qw/language type/);
	$args{cccdlflags} = [ _split_conf($opts->{config}, 'cccdlflags') ];
	return ("Compiler::$module", cc => $cc, %extra, %args);
}

sub require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

sub get_compiler {
	my ($self, %opts) = @_;

	$opts{config} ||= ExtUtils::Config->new;
	my $compiler = $self->_make_command($self->_get_compiler(\%opts));
	if (my $profile = delete $opts{profile}) {
		$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
		require_module($profile);
		$profile->process_compiler($compiler, \%opts);
	}
	if (my $include_dirs = $opts{include_dirs}) {
		$compiler->add_include_dirs($include_dirs);
	}
	if (my $defines = $opts{define}) {
		$compiler->add_defines($defines);
	}
	if (my $extra = $opts{extra_args}) {
		$compiler->add_argument(value => $extra);
	}
	return $compiler;
}

sub _unix_flags {
	my ($self, $opts) = @_;
	return $opts->{lddlflags} if defined $opts->{lddlflags};
	my $lddlflags = $opts->{config}->get('lddlflags');
	my $optimize = $opts->{config}->get('optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not $self->{auto_optimize};
	my %ldflags = map { ($_ => 1) } _split_conf($opts->{config}, 'ldflags');
	my @lddlflags = grep { not $ldflags{$_} } shellwords($lddlflags);
	my @cc = _split_conf($opts->{config}, 'ccdlflags');
	return (cc => \@cc, ldd_flags => \@lddlflags )
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my %args = _filter_args($opts, qw/type export language/);
	my $cc = $opts->{config}->get('cc');
	my $ld = $opts->{config}->get('ld');
	my ($module, $link, %opts) =
		$args{type} eq 'static-library' ? ('Ar', $opts->{config}->get('ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $cc) :
		_is_gcc($opts->{config}, $ld, $opts) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc) : ('ELF::GCC', $cc) :
		$os eq 'aix' ? ('XCOFF', $cc) :
		is_os_type('Unix', $os) ? ('ELF', $cc, $self->_unix_flags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld) :
		croak 'Linking is not supported yet on your platform';
	return ("Linker::$module", ld => $link, %opts, %args);
}

sub get_linker {
	my ($self, %opts) = @_;
	$opts{config} ||= ExtUtils::Config->new;
	my $linker = $self->_make_command($self->_get_linker(\%opts));
	if (my $profile = delete $opts{profile}) {
		$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
		require_module($profile);
		$profile->process_linker($linker, \%opts);
	}
	if (my $library_dirs = $opts{library_dirs}) {
		$linker->add_library_dirs($library_dirs);
	}
	if (my $libraries = $opts{libraries}) {
		$linker->add_libraries($libraries);
	}
	if (my $extra_args = $opts{extra_args}) {
		$linker->add_argument(ranking => 85, value => [ @{$extra_args} ]);
	}
	return $linker;
}

1;

#ABSTRACT: compiler configuration, derived from perl's configuration

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 my $auto = ExtUtils::Builder::AutoDetect::C;
 my $compiler = $auto->get_compiler(profile => 'Perl', type => 'loadable-object');
 $compiler->compile('foo.c', 'foo.o');
 my $linker = $auto->get_linker(profile => 'Perl', type => 'loadable-object');
 $linker->link([ 'foo.o' ], 'foo.so');
 my $plan = $planner->plan;

=head1 DESCRIPTION

=method get_compiler(%options)

=over 4

=item profile

=item include_dirs

=item define

=item extra_args

=back

=method get_linker(%options)

=over 4

=item profile

=item libraries

=item library_dirs

=item extra_args

=back
