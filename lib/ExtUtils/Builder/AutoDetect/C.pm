package ExtUtils::Builder::AutoDetect::C;

use strict;
use warnings;

use Carp 'croak';
use ExtUtils::Config 0.007;
use Perl::OSType 'is_os_type';
use Text::ParseWords 'shellwords';

sub new {
	my ($class, %args) = @_;
	return bless {
		config  => $args{config} || ExtUtils::Config->new,
	}, $class;
}

sub config {
	my $self = shift;
	return $self->{config}
}

sub _get_conf {
	my ($self, $name) = @_;
	return $self->config->get($name);
}

sub _split_conf {
	my ($self, $name) = @_;
	my $ret = _get_conf($self, $name);
	return ref($ret) ? $ret : [ shellwords($ret) ];
}

sub _make_command {
	my ($self, $shortname, $argument, $command, %options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	require_module($module);
	my @command = ref $command ? @{$command} : shellwords($command);
	return $module->new($argument => \@command, %options);
}

sub _is_gcc {
	my ($self, $cc, $opts) = @_;
	return $self->_get_conf('gccversion') || $cc =~ / ^ g(?: cc | [+]{2} ) /ix;
}

sub _filter_args {
	my ($opts, @names) = @_;
	return map { $_ => delete $opts->{$_} } grep { exists $opts->{$_} } @names;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = delete $opts->{osname} || $^O;
	my $cc = $self->_get_conf('cc');
	my ($module, %extra) = is_os_type('Unix', $os) || $self->_is_gcc($cc, $opts) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	my %args = (_filter_args($opts, qw/language type/), cccdlflags => $self->_split_conf('cccdlflags'));
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
	my $compiler = $self->_make_command($self->_get_compiler(\%opts));
	if (my $profile = delete $opts{profile}) {
		$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
		require_module($profile);
		$profile->process_compiler($compiler, { %opts, config => $self->config });
	}
	if (my $include_dirs = delete $opts{include_dirs}) {
		$compiler->add_include_dirs($include_dirs);
	}
	if (my $defines = delete $opts{define}) {
		$compiler->add_defines($defines);
	}
	if (my $extra = delete $opts{extra_args}) {
		$compiler->add_argument(value => $extra);
	}
	croak 'Unkown options: ' . join ',', keys %opts if keys %opts;
	return $compiler;
}

sub _lddlflags {
	my ($self, $opts) = @_;
	return delete $opts->{lddlflags} if defined $opts->{lddlflags};
	my $lddlflags = $self->config->get('lddlflags');
	my $optimize = $self->_get_conf('optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not delete $self->{auto_optimize};
	my %ldflags = map { ($_ => 1) } @{ $self->_split_conf('ldflags') };
	return [ grep { not $ldflags{$_} } shellwords($lddlflags) ];
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = delete $opts->{osname} || $^O;
	my %args = _filter_args($opts, qw/type export language/);
	my $cc = $self->_get_conf('cc');
	my $ld = $self->_get_conf('ld');
	my ($module, $link, %opts) =
		$args{type} eq 'static-library' ? ('Ar', $self->_get_conf('ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $cc) :
		$self->_is_gcc($ld, $opts) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc) : ('ELF::GCC', $cc) :
		$os eq 'aix' ? ('XCOFF', $cc) :
		is_os_type('Unix', $os) ? ('ELF', $cc, ccdlflags => $self->_split_conf('ccdlflags'), lddlflags => $self->_lddlflags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld) :
		croak 'Linking is not supported yet on your platform';
	return ("Linker::$module", ld => $link, %opts, %args);
}

sub get_linker {
	my ($self, %opts) = @_;
	my $linker = $self->_make_command($self->_get_linker(\%opts));
	if (my $profile = delete $opts{profile}) {
		$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
		require_module($profile);
		$profile->process_linker($linker, { %opts, config => $self->config });
	}
	if (my $library_dirs = delete $opts{library_dirs}) {
		$linker->add_library_dirs($library_dirs);
	}
	if (my $libraries = delete $opts{libraries}) {
		$linker->add_libraries($libraries);
	}
	if (my $extra_args = delete $opts{extra_args}) {
		$linker->add_argument(ranking => 85, value => [ @{$extra_args} ]);
	}
	croak 'Unknown options: ' . join ',', keys %opts if keys %opts;
	return $linker;
}

1;

