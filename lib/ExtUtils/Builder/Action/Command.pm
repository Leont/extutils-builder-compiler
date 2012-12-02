package ExtUtils::Builder::Action::Command;

use Moo;

with 'ExtUtils::Builder::Role::Action::Logging';

use IPC::System::Simple qw/systemx capturex/;

has _command => (
	is       => 'ro',
	required => 1,
	init_arg => 'command',
);

sub serialize {
	my $self = shift;
	return [ @{ $self->_command } ];
}

sub execute {
	my ($self, %opts) = @_;
	my @command = @{ $self->serialize };
	($opts{logger} || $self->logger)->(join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @command) if not $opts{quiet};
	if (not $opts{dry_run}) {
		if ($opts{verbose}) {
			systemx(@command);
		}
		else {
			capturex(@command);
		}
	}
	return;
}

1;
