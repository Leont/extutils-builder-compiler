package ExtUtils::Builder::Linker;

use base qw/ExtUtils::Builder::ArgumentCollector ExtUtils::Builder::Binary/;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Action::Code;
use ExtUtils::Builder::Node;

use Carp ();

my %allowed_export = map { $_ => 1 } qw/none some all/;

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->_init(%args);
	return $self;
}

sub _init {
	my ($self, %args) = @_;
	$self->ExtUtils::Builder::ArgumentCollector::_init(%args);
	$self->ExtUtils::Builder::Binary::_init(%args);

	my $export = $args{export};
	Carp::croak("'$export' is not an allowed export value") if not $allowed_export{$export};
	$self->{export} = $export;

	$self->{ld} = $args{ld};
	$self->{library_dirs} = [];
	$self->{libraries} = [];
	$self->{option_filters} = [];

	return;
}

sub export {
	my $self = shift;
	return $self->{export};
}

sub ld {
	my $self = shift;
	return @{ $self->{ld} };
}

sub collect_arguments {
	my ($self, @args) = @_;
	return ($self->SUPER::collect_arguments(@args), $self->linker_flags(@args));
}

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_libdir_ranking, $opts{ranking});
	push @{ $self->{library_dirs} }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_libdir_ranking {
	return 30;
}

sub add_libraries {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_library_ranking, $opts{ranking});
	push @{ $self->{libraries} }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_library_ranking {
	return 75;
}

sub add_option_filter {
	my ($self, $filter) = @_;
	push @{ $self->{option_filters} }, $filter;
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
			arguments => [ %args ],
			exports   => 1,
		);
	}
	return;
}
sub post_action { }

sub link {
	my ($self, @args) = @_;
	@args = $self->$_(@args) for @{ $self->{option_filters} };
	my ($from, $to, %opts) = @args;
	my @argv    = $self->arguments(@args);
	my $main    = ExtUtils::Builder::Action::Command->new(command => [ $self->ld, @argv ]);
	my @actions = ($self->pre_action(@args), $main, $self->post_action(@args));
	my $deps    = [ @{$from}, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Node->new(target => $to, dependencies => $deps, actions => \@actions);
}

1;

=method new

=over 4

=item type

This must be either C<executable>, C<shared-library>, C<loadable-object> or C<static-library>.

=item libraries

=item library_dirs

=item export

=back

=method add_library_dirs

=method add_libraries

=method link($source, $target, %options)


