package ExtUtils::Builder::AutoDetect;

use Moo;

use Carp 'croak';
use ExtUtils::Config;
use ExtUtils::Helpers 'split_like_shell';
use Module::Runtime qw/require_module/;
use Perl::OSType 'is_os_type';

has config => (
	is      => 'ro',
	default => sub { ExtUtils::Config->new },
);

sub _get_opt {
	my ($self, $opts, $name) = @_;
	return delete $opts->{$name} if defined $opts and defined $opts->{$name};
	return $self->config->get($name);
}

sub _split_opt {
	my ($self, $opts, $name) = @_;
	my $ret = _get_opt($self, $opts, $name);
	return ref($ret) ? $ret : [ split_like_shell($ret) ];
}

sub _make_command {
	my ($self, $shortname, $argument, $command, %options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	require_module($module);
	my @command = ref $command ? @{$command} : split_like_shell($command);
	return $module->new($argument => \@command, %options);
}

sub _is_gcc {
	my ($self, $cc, $opts) = @_;
	return $self->_get_opt($opts, 'gccversion') || $cc =~ / ^ gcc /ix;
}

sub _filter_args {
	my ($opts, @names) = @_;
	return map { $_ => delete $opts->{$_} } grep { exists $opts->{$_} } @names;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = delete $opts->{osname} || $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	my ($module, %extra) = $self->_is_gcc($cc, $opts) ? 'GCC' : is_os_type('Unix', $os) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	my %args = (_filter_args($opts, qw/language type/), cccdlflags => $self->_split_opt($opts, 'cccdlflags'));
	return $self->_make_command("Compiler::$module", cc => $cc, %args, %extra);
}

sub get_compiler {
	my ($self, %opts) = @_;
	my $compiler = $self->_get_compiler(\%opts);
	if (my $profile = delete $opts{profile}) {
		$compiler->load_profile($profile, { %opts, config => $self->config });
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
	my $optimize = $self->_get_opt($opts, 'optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not delete $self->{auto_optimize};
	my %ldflags = map { ( $_ => 1 ) } @{ $self->_split_opt($opts, 'ldflags') };
	return [ grep { not $ldflags{$_} } split_like_shell($lddlflags) ];
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = delete $opts->{osname} || $^O;
	my %args = _filter_args($opts, qw/type export language/);
	my $cc = $self->_get_opt($opts, 'cc');
	my $ld = $self->_get_opt($opts, 'ld');
	my ($module, $link, %opts) =
		$args{type} eq 'static-library' ? ('Ar', $self->_get_opt($opts, 'ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $cc) :
		$self->_is_gcc($ld, $opts) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc) : ('ELF::GCC', $cc) :
		$os eq 'aix' ? ('XCOFF', $cc) :
		is_os_type('Unix', $os) ? ('ELF', $cc, ccdlflags => $self->_split_opt($opts, 'ccdlflags'), lddlflags => $self->_lddlflags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld) :
		croak 'Linking is not supported yet on your platform';
	return $self->_make_command("Linker::$module", ld => $link, %opts, %args);
}

sub get_linker {
	my ($self, %opts) = @_;
	my $linker = $self->_get_linker(\%opts);
	if (my $profile = delete $opts{profile}) {
		$linker->load_profile($profile, { %opts, config => $self->config });
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
	croak 'Unkown options: ' . join ',', keys %opts if keys %opts;
	return $linker;
}

1;

