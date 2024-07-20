package ExtUtils::Builder::Linker::PE::MSVC;

use strict;
use warnings;

use ExtUtils::Builder::Action::Command;

use parent qw/ExtUtils::Builder::Linker::COFF/;

sub _init {
	my ($self, %args) = @_;
	$args{ld} ||= ['link'];
	$self->ExtUtils::Builder::Linker::COFF::_init(%args);
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking =>  5, value => ['/nologo']);
	push @ret, $self->new_argument(ranking => 10, value => ['/dll']) if $self->type eq 'shared-library' or $self->type eq 'loadable-object';
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "/libpath:-L$_->{value}" ]) } @{ $self->{library_dirs} };
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "$_->{value}.lib" ]) } @{ $self->{libraries} };
	push @ret, $self->new_argument(ranking => 50, value => [ @{$from} ]);
	push @ret, $self->new_argument(ranking => 80, value => ["/OUT:$to"]);
	# map_file, implib, def_file?…
	return @ret;
}

sub post_action {
	my ($self, $from, $to, %opts) = @_;
	my @ret = $self->SUPER::post_action(%opts);
	my $manifest = $opts{manifest} || "$to.manifest";
	push @ret, ExtUtils::Builder::Action::Command->new(command => [ 'if', 'exist', $manifest, 'mt', '-nologo', '-manifest', $manifest, "-outputresource:$to;2" ]);
	return @ret;
}

1;

