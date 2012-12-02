package ExtUtils::Builder::Role::Action::Logging;

use Moo::Role;

with 'ExtUtils::Builder::Role::Action';

has logger => (
	is      => 'ro',
	default => sub { \*STDOUT },
	coerce  => sub {
		my $log = shift;
		return
			  ref($log) eq 'CODE' ? $log
			: ref($log) eq 'GLOB' ? sub { print {$log} @_, "\n" }
			: Carp::croak('Invalid logger');
	},
);

1;
