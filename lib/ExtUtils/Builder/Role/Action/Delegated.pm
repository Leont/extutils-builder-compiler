package ExtUtils::Builder::Role::Action::Delegated;

use Moo::Role;

use ExtUtils::Builder::Role::Action;

has action   => (
	is       => 'ro',
	required => 1,
	isa      => sub { $_[0]->does('ExtUtils::Builder::Role::Action') },
	handles  => 'ExtUtils::Builder::Role::Action',
);

with 'ExtUtils::Builder::Role::Action';

1;
