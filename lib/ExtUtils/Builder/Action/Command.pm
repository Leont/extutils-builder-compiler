package ExtUtils::Builder::Action::Command;

use Moo;

with 'ExtUtils::Builder::Role::Action';

use IPC::System::Simple qw/systemx capturex/;

has program => (
	is       => 'ro',
	required => 1,
);

has arguments => (
	is       => 'ro',
	default  => sub { [] },
);

has command => (
	is => 'lazy',
#	init_arg => undef,
);

sub _build_command {
	my $self = shift;
	use sort 'stable';
	my @arguments = map { @{ $_->value } } sort { $a->ranking <=> $b->ranking } @{ $self->arguments };

	return [ $self->program, @arguments ];
}

has env => (
	is       => 'ro',
	required => 1,
);

has logger => (
	is      => 'ro',
	default => sub { \*STDOUT },
);

sub execute {
	my ($self, %opts) = @_;
	my $env = $self->env;
	print { $opts{logger} || $self->logger } $self->oneliner, "\n" if not $opts{quiet};
	if (not $opts{dry_run}) {
		local @ENV{keys %{$env}} = values %{$env};
		if ($opts{verbose}) {
			systemx(@{ $self->command });
		}
		else {
			capturex(@{ $self->command });
		}
	}
	return;
}

sub oneliner {
	my ($self, %opts) = @_;
	return join ' ', @{ $self->command };
}

1;
