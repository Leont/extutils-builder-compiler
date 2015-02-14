package ExtUtils::Builder::Role::Compiler;

use Moo::Role;

with qw/ExtUtils::Builder::Role::ArgumentCollector ExtUtils::Builder::Role::Binary/;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Node;
use Module::Runtime ();

requires qw/compile_flags _build_cc/;

has _cc => (
	is       => 'ro',
	builder  => '_build_cc',
	init_arg => 'cc',
	coerce   => sub {
		return ref $_[0] ? $_[0] : [ $_[0] ];
	},
);

sub cc {
	my $self = shift;
	return @{ $self->_cc };
}

has _include_dirs => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_include_ranking, $opts{ranking});
	push @{ $self->_include_dirs }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_include_ranking {
	return 30;
}

has _defines => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_defines {
	my ($self, $defines, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_define_ranking, $opts{ranking});
	push @{ $self->_defines }, map { { key => $_, ranking => $ranking, value => $defines->{$_} } } keys %{ $defines };
	return;
}

sub default_define_ranking {
	return 40;
}

around collect_arguments => sub {
	my ($orig, $self, @args) = @_;
	return ($self->$orig, $self->compile_flags(@args));
};

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

