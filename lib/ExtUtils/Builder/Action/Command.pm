package ExtUtils::Builder::Action::Command;

use Moo;

with 'ExtUtils::Builder::Role::Action';

use IPC::System::Simple qw/systemx capturex/;

sub _build_preference_map {
	return {
		command => 3,
		execute => 2,
		code    => 1,
		flatten => 0
	};
}

has _command => (
	is       => 'ro',
	required => 1,
	init_arg => 'command',
);

sub to_code {
	my ($self, %opts) = @_;
	require Data::Dumper;
	my @dumped = Data::Dumper->new([ $self->to_command, \%opts ])->Terse(1)->Indent(0)->Dump;
	return sprintf 'sub { my %%opts = @_; require %s; %s::_execute(%s, { %%opts, %%{%s} });', (__PACKAGE__) x 2, @dumped;
}

sub to_command {
	my $self = shift;
	return [ @{ $self->_command } ];
}

sub execute {
	my ($self, %opts) = @_;
	my @command = @{ $self->to_command };
	return _execute(\@command, \%opts);
}

sub _execute {
	my ($command, $opts) = @_;
	$opts->{logger}->(join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @{$command}) if $opts->{logger} and not $opts->{quiet};
	if (not $opts->{dry_run}) {
		if ($opts->{verbose}) {
			systemx(@{$command});
		}
		else {
			capturex(@{$command});
		}
	}
	return;
}

1;
