package ExtUtils::Builder::Role::Linker;

use Moo::Role;

with qw/ExtUtils::Builder::Role::Command ExtUtils::Builder::Role::Binary/;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Plan;
use Module::Runtime ();

requires qw/add_library_dirs add_libraries linker_flags/;

use Carp ();

my %allowed_export = map { $_ => 1 } qw/none some all/;

has export => (
	is  => 'lazy',
	isa => sub {
		Carp::croak("$_[0] is not an allowed export value") if not $allowed_export{ $_[0] };
	},
);

requires qw/_build_ld _build_export/;

has _ld => (
	is       => 'ro',
	init_arg => 'ld',
	builder  => '_build_ld',
);

sub ld {
	my $self = shift;
	return @{ $self->_ld };
}

around collect_arguments => sub {
	my ($orig, $self, @args) = @_;
	return ($self->$orig, $self->linker_flags(@args));
};

has _option_filters => (
	is      => 'ro',
	default => sub { [] },
);

sub add_option_filter {
	my ($self, $filter) = @_;
	push @{ $self->_option_filters }, $filter;
	return;
}

sub pre_action  { }
sub post_action { }

sub link {
	my ($self, @args) = @_;
	@args = $self->$_(@args) for @{ $self->_option_filters };
	my ($from, $to, %opts) = @args;
	my @argv    = $self->arguments(@args);
	my $main    = ExtUtils::Builder::Action::Command->new(command => [ $self->ld, @argv ]);
	my @actions = ($self->pre_action(@args), $main, $self->post_action(@args));
	my $deps    = [ @{$from}, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Plan->new(target => $to, dependencies => $deps, actions => \@actions);
}

sub load_profile {
	my ($self, $module, $arguments) = @_;
	$module =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
	Module::Runtime::require_module($module);
	return $module->process_linker($self, $arguments);
}

1;

