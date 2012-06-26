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

sub _get_compiler {
	my ($self, $opts) = @_;
	my $language = delete $opts->{language} || 'C';
	croak 'Only C is supported so far' if $language ne 'C';
	my $cc = $self->config->get('cc');
	if (is_os_type('Unix') or $cc =~ / \A gcc \b /xm) {
		my @cc = split_like_shell($cc);
		my $module = 'ExtUtils::Builder::Compiler::' . ($cc[0] =~ /gcc/i || delete $opts->{force_gcc} ? 'GCC' : 'Unixy');
		load($module);
		my $compiler = $module->new(command => shift @cc, language => $language, type => delete $opts->{type}, config => $self->config);
		$compiler->add_argument(ranking => 0, value => \@cc) if @cc;
		return $compiler;
	}
	else {
		croak 'Non-Unix is not supported yet...';
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
	croak 'Unkown options: ' . join ',', keys %opts if keys %opts;
	return $compiler;
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $language = delete $opts->{language} || 'C';
	croak 'Only C is supported so far' if $language ne 'C';
	if (is_os_type('Unix')) {
		require ExtUtils::Builder::Linker::Unixy;
		my $ld     = $self->config->get('ld');
		my @ld     = split_like_shell($ld);
		my $linker = ExtUtils::Builder::Linker::Unixy->new(command => shift @ld, type => delete $opts->{type}, language => $language, config => $self->config);
		$linker->add_argument(ranking => 0, value => \@ld) if @ld;
		return $linker;
	}
	else {
		croak 'Non-Unix is not supported yet...';
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
		$self->add_library_dirs($library_dirs);
	}
	if (my $libraries = delete $opts{libraries}) {
		$self->add_libraries($libraries);
	}
	if (my $extra_args = delete $opts{extra_args}) {
		$self->add_argument(ranking => 45, value => [ @{ $opts{extra_args} } ]);
	}
	croak 'Unkown options: ' . join ',', keys %opts if keys %opts;
	return $linker;
}

1;

# ABSTRACT: Compiling and linking, the abstract way
