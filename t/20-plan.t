#! perl

use strict;
use warnings;

use Test::More 0.89;
use Test::Fatal;

use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Code;

my ($plan, @triggered);
my @actions = map { my $num = $_; ExtUtils::Builder::Action::Code->new(code => sub { push @triggered, $num }) } 1, 2;
is(exception { $plan = ExtUtils::Builder::Plan->new(target => 'foo', dependencies => [ qw/bar baz/ ], actions => \@actions) }, undef, 'Can create new object');

is(exception { $plan->execute }, undef, 'Can execute quiet command');
is_deeply(\@triggered, [ 1, 2 ], 'Both actions ran');
is_deeply([ $plan->flatten ], \@actions, '$plan->actions contains all expected actions');
is(exception { $plan->to_command }, undef, '$plan->to_command doesn\'t give any error');
is($plan->preference, 'flatten', 'Preferred action is "flatten"');

done_testing;
