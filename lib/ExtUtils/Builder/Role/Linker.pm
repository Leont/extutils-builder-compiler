package ExtUtils::Builder::Role::Linker;

use Moo::Role;

with qw/ExtUtils::Builder::Role::ArgumentCollector ExtUtils::Builder::Role::Binary/;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Action::Code;
use ExtUtils::Builder::Node;
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

has _library_dirs => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_libdir_ranking, $opts{ranking});
	push @{ $self->_library_dirs }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_libdir_ranking {
	return 30;
}

has _libraries => (
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
);

sub add_libraries {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_library_ranking, $opts{ranking});
	push @{ $self->_libraries }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_library_ranking {
	return 75;
}

has _option_filters => (
	is      => 'ro',
	default => sub { [] },
);

sub add_option_filter {
	my ($self, $filter) = @_;
	push @{ $self->_option_filters }, $filter;
	return;
}

my %key_for = (
	dl_vars      => 'DL_VARS',
	dl_funcs     => 'DL_FUNCS',
	dl_func_list => 'FUNCLIST',
	dl_imports   => 'IMPORTS',
	dl_name      => 'NAME',
	dl_base      => 'DLBASE',
	dl_file      => 'FILE',
);
sub pre_action  {
	my ($self, $from, $to, %opts) = @_;
	if ($self->export eq 'some') {
		my %args = map { $key_for{$_} => $opts{$_} } grep { exists $key_for{$_} } keys %opts;
		return ExtUtils::Builder::Action::Function->new(
			module    => 'ExtUtils::Mksymlists',
			function  => 'Mksymlists',
			message   => join(' ', 'prelink', $to, %args),
			arguments => \%args,
			exports   => 1,
		);
	}
	return;
}
sub post_action { }

sub link {
	my ($self, @args) = @_;
	@args = $self->$_(@args) for @{ $self->_option_filters };
	my ($from, $to, %opts) = @args;
	my @argv    = $self->arguments(@args);
	my $main    = ExtUtils::Builder::Action::Command->new(command => [ $self->ld, @argv ]);
	my @actions = ($self->pre_action(@args), $main, $self->post_action(@args));
	my $deps    = [ @{$from}, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Node->new(target => $to, dependencies => $deps, actions => \@actions);
}

sub load_profile {
	my ($self, $module, $arguments) = @_;
	$module =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
	Module::Runtime::require_module($module);
	return $module->process_linker($self, $arguments);
}

1;

