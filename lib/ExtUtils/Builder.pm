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

sub _make_command {
	my ($self, $shortname, $command, @options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	load($module);
	my @command = ref $command ? @{$command} : split_like_shell($command);
	my $thingie = $module->new(command => shift @command, config => $self->config, @options);
	$thingie->add_argument(ranking => 0, value => \@command) if @command;
	return $thingie;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $language = delete $opts->{language} || 'C';
	my $cc = $self->config->get('cc');
	if (is_os_type('Unix') or $cc =~ / \A gcc \b /xm) {
		my $module = 'Compiler::' . ($cc =~ /^gcc/i || delete $opts->{force_gcc} ? 'GCC' : 'Unixy');
		return $self->_make_command($module, $cc, language => $language, type => delete $opts->{type});
	}
	elsif (is_os_type('Windows') && $cc =~ /^ cl \b /x) {
		return $self->_make_command('Compiler::MSVC', $cc, language => $language, type => delete $opts->{type});
	}
	else {
		croak 'Your platform is not supported yet...';
	}
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

sub _get_linker {
	my ($self, $opts) = @_;
	my $language = delete $opts->{language} || 'C';
	if (is_os_type('Unix') and $^O ne 'aix') {
		my $type = delete $opts->{type};
		if ($type ne 'static-library') {
			return $self->_make_command('Linker::Unixy', $self->config->get('ld'), type => $type, language => $language);
		}
		else {
			return $self->_make_command('Linker::Ar', $self->config->get('ar'), type => $type, language => $language);
		}
	}
	else {
		croak 'Non-Unix linking is not supported yet...';
	}
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
