package ExtUtils::Builder::Linker::XCOFF;

use Moo;

with qw/ExtUtils::Builder::Role::Linker::Unixy ExtUtils::Builder::Role::Linker::COFF/;

use File::Basename ();

sub _build_ld {
	return ['ld'];
}

around linker_flags => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	push @ret, $self->new_argument(ranking => 20, value => ['-bnoautoimp']) if !$self->autoimport;

	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		if ($self->export eq 'some') {
			my $basename = $opts{basename} || File::Basename::basename($to);
			push @ret, $self->new_arguments(ranking => 20, value => ["-bE:$basename.exp"]);
		}
		elsif ($self->export eq 'all') {
			push @ret, $self->new_argument(ranking => 20, value => ['-bexpfull']);
		}
	}
	return @ret;
};

1;
