package ExtUtils::Builder::Linker::PE::GCC;

use Moo;

with qw/ExtUtils::Builder::Role::Linker::Unixy ExtUtils::Builder::Role::Linker::COFF/;

use File::Basename ();

sub _build_ld {
	return ['gcc'];
}

around linker_flags => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);

	push @ret, $self->new_argument(ranking => 85, value => ['-Wl,--enable-auto-image-base']);
	if ($self->type eq 'shared-library' or $self->type eq 'loadable-object') {
		push @ret, $self->new_argument(ranking => 10, value => ['--shared']);
	}
	if ($self->autoimport) {
		push @ret, $self->new_argument(ranking => 85, value => ['-Wl,--enable-auto-import']);
	}

	if ($self->export eq 'all') {
		push @ret, $self->new_arguments(ranking => 85, value => ['-Wl,--export-all-symbols']);
	}
	elsif ($self->export eq 'some') {
		my $export_file = $opts{export_file} || ($opts{basename} || File::Basename::basename($to)) . '.def';
		push @ret, $self->new_argument(ranking => 20, value => [$export_file]);
	}
	return @ret;
};

1;
