package ExtUtils::Builder::Role::Linker::Shared;

use Moo::Role;

with 'ExtUtils::Builder::Role::Linker';

use ExtUtils::Builder::Action::Code;

my %key_for = (
	dl_vars      => 'DL_VARS',
	dl_funcs     => 'DL_FUNCS',
	dl_func_list => 'FUNCLIST',
	dl_imports   => 'IMPORTS',
	dl_name      => 'NAME',
	dl_base      => 'DLBASE',
	dl_file      => 'FILE',
);

around pre_action => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig(%opts);
	if ($self->export eq 'some') {
		my %args = map { $key_for{$_} => $opts{$_} } grep { exists $key_for{$_} } keys %opts;
		push @ret, ExtUtils::Builder::Action::Code->new(
			code => sub { ExtUtils::Mksymlists::Mksymlists(@_) },
			serialized => 'ExtUtils::Mksymlists::Mksymlists(@_)',
			message => join(' ', "prelink $to", %args),
			modules => [ 'ExtUtils::Mksymlists' ],
			arguments => \%args,
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
