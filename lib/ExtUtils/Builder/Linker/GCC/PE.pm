package ExtUtils::Builder::Linker::GCC::PE;

use Moo;

with 'ExtUtils::Builder::Role::Linker::Unixy';

use File::Basename ();
use ExtUtils::Builder::Argument;

has '+command' => (
	default => sub { 'gcc' },
);

sub _build_export {
	my $self = shift;
	return $self->type eq 'executable' ? 'none' : 'all';
}

around linker_flags => sub {
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig($from, $to, %opts);
	push @ret, ExtUtils::Builder::Argument->new(ranking => 85, value => [ '-Wl,--enable-auto-import', '-Wl,--enable-auto-image-base' ]);
	if ($self->export eq 'all') {
		push @ret, ExtUtils::Builder::Argument->new(ranking => 85, value => [ '-Wl,--export-all-symbols' ]);
	}
	elsif ($self->export eq 'some') {
		my $export_file = $opts{export_file} || ($opts{basename} || File::Basename::basename($to)).".def";
		push @ret, ExtUtils::Builder::Argument->new(ranking => 20, value => [ $export_file ])
	}
	return @ret;
};

1;
