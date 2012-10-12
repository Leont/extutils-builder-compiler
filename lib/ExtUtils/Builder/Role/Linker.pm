package ExtUtils::Builder::Role::Linker;

use Moo::Role;

with qw/ExtUtils::Builder::Role::Toolchain/;

has export => (
	is => 'ro',
	required => 1,
);

requires qw/link add_library_dirs add_libraries/;

use ExtUtils::Builder::Action::Code;

has prelinking => (
	is => 'ro',
	default => sub { 0 },
);

around pre_action => sub {
	my ($orig, $self, %args) = @_;
	return ($self->$orig(%args), $self->prelinking ? ExtUtils::Builder::Action::Code->new(code => sub { _prelink(%args, @_) }) : ());
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

