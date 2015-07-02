package ExtUtils::Builder::Role::Compiler;

use strict;
use warnings;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Node;
use Module::Runtime ();

use base qw/ExtUtils::Builder::Role::ArgumentCollector ExtUtils::Builder::Role::Binary/;

sub new {
	my ($class, %args) = @_;
	my $cc = $args{cc};
	$cc = [ $cc ] if not ref $cc;
	my $self = bless {
		cc           => $cc,
		include_dirs => [],
		defines      => [],
	}, $class;
	$self->_init(%args);
	return $self;
}

sub _init {
	my ($self, %args) = @_;
	$self->ExtUtils::Builder::Role::ArgumentCollector::_init(%args);
	$self->ExtUtils::Builder::Role::Binary::_init(%args);
	return;
}

sub compile_flags;

sub cc {
	my $self = shift;
	return @{ $self->{cc} };
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_include_ranking, $opts{ranking});
	push @{ $self->{include_dirs} }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_include_ranking {
	return 30;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_define_ranking, $opts{ranking});
	push @{ $self->{defines} }, map { { key => $_, ranking => $ranking, value => $defines->{$_} } } keys %{ $defines };
	return;
}

sub default_define_ranking {
	return 40;
}

sub collect_arguments  {
	my ($self, @args) = @_;
	return ($self->SUPER::collect_arguments, $self->compile_flags(@args));
}

sub compile {
	my ($self, $from, $to, %opts) = @_;
	my @argv = $self->arguments($from, $to, %opts);
	my $main = ExtUtils::Builder::Action::Command->new(command => [ $self->cc, @argv ]);
	my $deps = [ $from, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Node->new(target => $to, dependencies => $deps, actions => [$main]);
}

sub load_profile {
	my ($self, $module, $arguments) = @_;
	$module =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
	Module::Runtime::require_module($module);
	return $module->process_compiler($self, $arguments);
}

1;

