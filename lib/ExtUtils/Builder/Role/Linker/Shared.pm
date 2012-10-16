package ExtUtils::Builder::Role::Linker::Shared;

use Moo::Role;

with 'ExtUtils::Builder::Role::Linker';

use ExtUtils::Builder::Action::Code;

has prelinking => (
	is => 'ro',
	required => 1,
);

has export => (
	is => 'lazy',
	default => sub {
		my $self = shift;
		return $self->prelinking ? 'none' : 'some';
	},
);

has ccdlflags => (
	is => 'ro',
	required => 1,
);

has lddlflags => (
	is => 'ro',
	required => 1,
);

sub get_linker_flags {
	my ($self, %opts) = @_;
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		return @{ $self->lddlflags };
	}
	elsif ($type eq 'executable') {
		return $self->export eq 'all' ? @{ $self->ccdlflags } : ();
	}
	else {
		croak("Unknown linkage type $type");
	}
}

around pre_action => sub {
	my ($orig, $self, %args) = @_;
	return ($self->$orig(%args), $self->prelinking ? ExtUtils::Builder::Action::Code->new(code => sub { _prelink(%args, @_) }) : ());
};

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return (
		$self->$orig($from, $to, %opts),
		ExtUtils::Builder::Argument->new(ranking => 10, value => [ $self->get_linker_flags ]),
		$self->file_flags($from, $to, %opts),
		$self->language_flags(%opts),
	);
};

sub _prelink {
	my ($self, %args) = @_;
	require ExtUtils::Mksymlists;
	ExtUtils::Mksymlists::Mksymlists(
		DL_VARS  => $args{dl_vars}      || [],
		DL_FUNCS => $args{dl_funcs}     || {},
		FUNCLIST => $args{dl_func_list} || [],
		IMPORTS  => $args{dl_imports}   || {},
		NAME     => $args{dl_name},    # Name of the Perl module
		DLBASE   => $args{dl_base},    # Basename of DLL file
		FILE     => $args{dl_file},    # Dir + Basename of symlist file
		VERSION  => (defined $args{dl_version} ? $args{dl_version} : '0.0'),
	);

	return grep -e, map "$args{dl_file}.$_", qw(ext def opt);
}

1;
