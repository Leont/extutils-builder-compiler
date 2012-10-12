package ExtUtils::Builder;

use Moo;

use Carp 'croak';
use ExtUtils::Config;
use ExtUtils::Helpers 'split_like_shell';
use Module::Load;
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

sub _make_command {
	my ($self, $shortname, $command, %options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	load($module);
	my @command = ref $command ? @{$command} : split_like_shell($command);
	my %env = $command[0] =~ / \w+ = \S+ /x ? split /=/, shift @command, 2 : ();
	my $thingie = $module->new(command => shift @command, env => \%env, %options);
	$thingie->add_argument(ranking => 0, value => \@command) if @command;
	return $thingie;
}

sub _is_gcc {
	my ($self, $cc, $opts) = @_;
	return $self->_get_opt($opts, 'gccversion') || $cc =~ / ^ gcc /ix;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $cc = $self->_get_opt($opts, 'cc');
	my $module = $self->_is_gcc($cc, $opts) ? 'GCC' : is_os_type('Unix') ? 'Unixy' : is_os_type('Windows') ? 'MSVC' : croak 'Your platform is not supported yet';
	my %args = (language => delete $opts->{language} || 'C', type => delete $opts->{type}, cccdlflags => $self->_get_opt($opts, 'cccdlflags'));
	return $self->_make_command("Compiler::$module", $cc, %args);
}

sub get_compiler {
	my ($self, %opts) = @_;
	my $compiler = $self->_get_compiler(\%opts);
	if (my $profile = delete $opts{profile}) {
		my $profile_module = "ExtUtils::Builder::Profile::$profile";
		load($profile_module);
		$profile_module->process_compiler($compiler, $self->config, \%opts);
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
	my %ldflags = map { ( $_ => 1 ) } ExtUtils::Helpers::split_like_shell($self->_get_opt($opts, 'ldflags'));
	return [ grep { not $ldflags{$_} } ExtUtils::Helpers::split_like_shell($lddlflags) ];
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $type = delete $opts->{type};
	my $prelink = !is_os_type('Unix') || $^O eq 'aix';
	my %args = (
		type => $type, language => delete $opts->{language} || 'C',
		export => delete $opts->{export} || !$prelink ? 'all' : 'none', prelink => $prelink,
		ccdlflags => $self->_get_opt($opts, 'ccdlflags'), lddlflags => $self->_lddlflags($opts));
	my $ld = $self->_get_opt($opts, 'ld');
	my $module =
		$type eq 'static-library' ? 'Ar' :
		$self->_is_gcc($ld, $opts) ? 'GCC' :
		is_os_type('Unix') ? 'Unixy' :
		croak 'Linking is not supported yet on your platform';
	return $self->_make_command("Linker::$module", $ld, %args);
}

sub get_linker {
	my ($self, %opts) = @_;
	my $linker = $self->_get_linker(\%opts);
	if (my $profile = delete $opts{profile}) {
		my $profile_module = "ExtUtils::Builder::Profile::$profile";
		load($profile_module);
		$profile_module->process_linker($linker, $self->config, %opts);
	}
	if (defined(my $shared = $opts{shared})) {
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

# ABSTRACT: Compiling and linking, the abstract way
