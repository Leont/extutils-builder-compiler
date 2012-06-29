package ExtUtils::Builder::Linker::Unixy;

use Moo;

use Carp ();
use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::ActionSet;
use ExtUtils::Builder::Argument;

with 'ExtUtils::Builder::Role::Linker';

sub add_library_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => _fix_ranking(30, $opts{ranking}), value => [ map { "-L$_" } @{$dirs} ]);
	return;
}

sub add_libraries {
	my ($self, $libraries, %opts) = @_;
	$self->add_argument(ranking => _fix_ranking(35, $opts{ranking}), value => [ map { "-l$_" } @{$libraries} ]);
	return;
}

has _ccdlflags => (
	is => 'ro',
	default => sub { 
		my $self = shift;
		require ExtUtils::Helpers;
		return [ ExtUtils::Helpers::split_like_shell($self->config->get('ccdlflags')) ];
	},
	lazy => 1,
);

has _lddlflags => (
	is => 'ro',
	default => sub {
		my $self = shift;
		require ExtUtils::Helpers;
		my $lddlflags = $self->config->get('lddlflags');
		my $optimize = $self->config->get('optimize');
		$lddlflags =~ s/ ?\Q$optimize//;
		my %ldflags = map { ( $_ => 1 ) } ExtUtils::Helpers::split_like_shell($self->config->get('ldflags'));
		return [ grep { not $ldflags{$_} } ExtUtils::Helpers::split_like_shell($lddlflags) ];
	},
	lazy => 1,
);

sub get_linker_flags {
	my ($self, %opts) = @_;
	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		return $self->_lddlflags;
	}
	elsif ($type eq 'executable') {
		return $self->_has_export && $self->export eq 'all' ? $self->_ccdlflags : [];
	}
	else {
		Carp::croak("Unknown linkage type $type");
	}
}

sub link {
	my ($self, $from, $to, %opts) = @_;

	$from = [ $from ] if not ref $from;

	if ($self->type eq 'static-lib') {
		...;
	}
	else {
		my @arguments = (
			$self->arguments,
			ExtUtils::Builder::Argument->new(ranking => 10, value => $self->get_linker_flags),
			ExtUtils::Builder::Argument->new(ranking => 75, value => [ '-o' => $to, @{$from} ]),
		);

		my $action = ExtUtils::Builder::Action::Command->new(program => $self->command, arguments => \@arguments);
		return ExtUtils::Builder::ActionSet->new($action);
	}
}

1;
