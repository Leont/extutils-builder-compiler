package ExtUtils::Builder::Linker::XCOFF;

use Moo;

use ExtUtils::Builder::Argument;

with qw/ExtUtils::Builder::Role::Linker::COFF ExtUtils::Builder::Role::Linker::Unixy/;

use File::Basename ();

sub _build_ld {
	return ['ld'];
}

around linker_flags => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		if ($self->export eq 'some') {
			my $basename = $opts{basename} || File::Basename::basename($to);
			push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => ["-bE:$basename.exp"]);
		}
		elsif ($self->export eq 'all') {
			push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => ['-bexpfull']);
		}
		if (!$self->autoimport) {
			push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => ['-bnoautoimp']);
		}
	}
	return @ret;
};

1;
