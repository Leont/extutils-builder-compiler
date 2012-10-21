package ExtUtils::Builder::Role::Linker::Shared;

use Moo::Role;

with 'ExtUtils::Builder::Role::Linker';

use ExtUtils::Builder::Action::Code;

around pre_action => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig(%opts);
	if ($self->export eq 'some') {
		push @ret, ExtUtils::Builder::Action::Code->new(
			code => sub { ExtUtils::Mksymlists::Mksymlists(@_) },
			modules => [ 'ExtUtils::Mksymlists' ],
			args => { 
				DL_VARS  => $opts{dl_vars}      || [],
				DL_FUNCS => $opts{dl_funcs}     || {},
				FUNCLIST => $opts{dl_func_list} || [],
				IMPORTS  => $opts{dl_imports}   || {},
				NAME     => $opts{dl_name},    # Name of the Perl module
				DLBASE   => $opts{dl_base},    # Basename of DLL file
				FILE     => $opts{dl_file},    # Dir + Basename of symlist file
				VERSION  => (defined $opts{dl_version} ? $opts{dl_version} : '0.0'),
			},
		);
	}
	return @ret;
};

around arguments => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	return ($self->$orig($from, $to, %opts), $self->language_flags(%opts));
};

sub language_flags {
}

1;
