package ExtUtils::Builder::Linker::XCOFF;

use Moo;

use ExtUtils::Builder::Argument;

with map { "ExtUtils::Builder::Role::Linker::$_" } qw/COFF Unixy/;

use File::Basename ();

around linker_flags => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		my $basename = $opts{basename} || File::Basename::basename($to);
		if ($self->export eq 'some') {
			push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => [ "-bE:$basename.exp" ]);
		}
		elsif ($self->export eq 'all') {
			push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => [ '-bexpall' ]);
		}
	}
	return @ret;
};

1;
