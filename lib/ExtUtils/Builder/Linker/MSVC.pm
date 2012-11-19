package ExtUtils::Builder::Linker::MSVC;

use Moo;

use ExtUtils::Builder::Argument;
use ExtUtils::Builder::Action::Command;

with 'ExtUtils::Builder::Role::Linker::Shared';

has '+command' => (
	default => sub { 'link' },
);

my %export_for = (
	executable => 'none',
	'static-library' => 'all',
	'shared-library' => 'some',
	'loadable-object' => 'some',
);

sub _build_export {
	my $self = shift;
	return $export_for{ $self->type };
}

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { qq{/libpath:"$_"} } @{$dirs} ]);
	return;
}

sub add_libraries {
	my ($self, $libraries, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(75, $opts{ranking}), value => [ map { "$_.lib" } @{$libraries} ]); # XXX
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	my $type = $self->type;
	push @ret, ExtUtils::Builder::Argument->new(ranking =>  5, value => [ '/nologo' ]);
	push @ret, ExtUtils::Builder::Argument->new(ranking => 10, value => [ '/dll' ]) if $type eq 'shared-library' or $type eq 'loadable-object';
	push @ret, ExtUtils::Builder::Argument->new(ranking => 50, value => [ @{$from} ]);
	push @ret, ExtUtils::Builder::Argument->new(ranking => 80, value => [ "/OUT:$to"]);
	# map_file, implib, def_file?…
	return @ret;
};

around 'post_action' => sub {
	# XXX Conditional command?
	my ($orig, $self, $from, $to, %opts) = @_;
	my @ret = $self->$orig(%opts);
	my $manifest = $opts{manifest} || "$to.manifest";
	push @ret, ExtUtils::Builder::Action::Command->new(command => [ 'if', 'exist', $manifest, 'mt', '-nologo', $manifest, "-outputresource:$to;2" ]);
	return @ret;
};

1;
