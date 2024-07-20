package ExtUtils::Builder::Compiler;

use strict;
use warnings;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Node;

use parent qw/ExtUtils::Builder::ArgumentCollector ExtUtils::Builder::Binary/;

sub new {
	my ($class, %args) = @_;
	my $cc = $args{cc};
	$cc = [ $cc ] if not ref $cc;
	my $self = bless {
		cc           => $cc,
		include_dirs => [],
		defines      => [],
	}, $class;
	$self->_init(%args);
	return $self;
}

sub _init {
	my ($self, %args) = @_;
	$self->ExtUtils::Builder::ArgumentCollector::_init(%args);
	$self->ExtUtils::Builder::Binary::_init(%args);
	return;
}

sub compile_flags;

sub cc {
	my $self = shift;
	return @{ $self->{cc} };
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_include_ranking, $opts{ranking});
	push @{ $self->{include_dirs} }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_include_ranking {
	return 30;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_define_ranking, $opts{ranking});
	push @{ $self->{defines} }, map { { key => $_, ranking => $ranking, value => $defines->{$_} } } keys %{ $defines };
	return;
}

sub default_define_ranking {
	return 40;
}

sub collect_arguments  {
	my ($self, @args) = @_;
	return ($self->SUPER::collect_arguments, $self->compile_flags(@args));
}

sub compile {
	my ($self, $from, $to, %opts) = @_;
	my @actions ;
	if ($opts{mkdir}) {
		my $dirname = File::Basename::dirname($to);
		push @actions, ExtUtils::Builder::Action::Function->new(
			module    => 'File::Path',
			function  => 'make_path',
			exports   => 'explicit',
			arguments => [ $dirname ],
			message   => "mkdir $dirname",
		);
	}
	my @argv = $self->arguments($from, $to, %opts);
	push @actions, ExtUtils::Builder::Action::Command->new(command => [ $self->cc, @argv ]);
	my $deps = [ $from, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Node->new(target => $to, dependencies => $deps, actions => \@actions);
}

1;

# ABSTRACT: An interface around different compilers.

=head1 DESCRIPTION

This is an interface wrapping around different compilers. It's usually not used directly but by a portability layer like L<ExtUtils:Builder::Autodetect::C>.

=method add_include_dirs($dirs, %options)

Add dirs the the include list.

=method add_defines($defines, %options)

Add defines (as a hash) to the define list.

=method compile($source, $target, %options)

Compile a C<$source> to C<$destination>.
