package ExtUtils::Builder::Role::Linker::Shared;

use Moo::Role;

with 'ExtUtils::Builder::Role::Linker';

use ExtUtils::Builder::Action::Code;

around pre_action => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig(%opts);
	if ($self->export eq 'explicit') {
		my %dl_args = map { $_ => $opts{$_} } grep { /^dl_/ } keys %opts;
		push @ret, ExtUtils::Builder::Action::Code->new(code => \&prelink, args => \%dl_args);
	}
	return @ret;
};

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return ($self->$orig($from, $to, %opts), $self->language_flags(%opts));
};

sub language_flags {
}

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

	return grep { -e } map { "$args{dl_file}.$_" } qw(ext def opt);
}

1;
