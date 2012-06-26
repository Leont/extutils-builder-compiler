package ExtUtils::Builder::Compiler::Unixy;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::ActionSet;
use ExtUtils::Builder::Argument;

has pic => (
	is => 'lazy',
);

sub _build_pic {
	my $self = shift;
	return $self->type eq 'shared-library' || $self->type eq 'loadable-object' ? $self->config->get('cccdlflags') : ();
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => _fix_ranking(30, $opts{ranking}), value => [ map { "-I$_" } @{$dirs} ]);
	return;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	for my $key (keys %{$defines}) {
		my $value = defined $defines->{$key} ? $defines->{$key} ne '' ? "-D$key=$defines->{$key}" : "-D$key" : "-U$key";
		$self->add_argument(ranking => _fix_ranking(40, $opts{ranking}), value => [$value]);
	}
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	return 
		($self->pic ? ExtUtils::Builder::Argument->new(ranking => 45, value => [ $self->pic ]) : ()),
		ExtUtils::Builder::Argument->new(ranking => 75, value => [ '-o' => $to, '-c', $from ]);
}

sub compile {
	my ($self, $from, $to, %opts) = @_;

	my @arguments = ($self->arguments, $self->compile_flags($from, $to));

	my $action = ExtUtils::Builder::Action::Command->new(program => $self->command, arguments => \@arguments);
	return ExtUtils::Builder::ActionSet->new($action);
}

1;
