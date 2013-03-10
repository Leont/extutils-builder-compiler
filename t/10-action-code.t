#! perl

use strict;
use warnings;

use Config;
use Test::More 0.89;

use ExtUtils::Builder::Action::Code;
use Test::Fatal;

{
	my $action;
	our $callback = sub {};
	my %args = (
		code => sub { $callback->(@_) },
		serialized => '$callback->(@_)',
		message => 'callback',
	);
	is(exception { $action = ExtUtils::Builder::Action::Code->new(%args) }, undef, 'Can create new object');

	{
		my @actions;
		local $callback = sub { push @actions, @_ };

		is(exception { $action->execute(quiet => 1) }, undef, 'Can execute command');
	}

	{
		my (@actions, @messages);
		local $callback = sub { push @actions, @_ };

		is(exception { $action->execute(logger => sub { push @messages, @_ }) }, undef, 'Can execute command');

		is_deeply(\@messages, [ 'callback' ], 'Got the message');
	}

	my @serialized = $action->to_command;
	is(scalar(@serialized), 1, 'Got one command');
	my ($command, @arguments) = @{ +shift @serialized };
	is($command, $Config{perlpath}, "Command is $Config{perlpath}");
	is($action->to_code, "sub { $args{serialized} }", 'to_code is "sub { $input }"');

	is($action->preference, 'execute', 'Prefered means is "execute"');
	is($action->preference(qw/code command/), 'code', 'Prefered means between "code" and "command" is "code"');
}

done_testing;
