package ExtUtils::Builder::Role::MultiLingual;

use Moo::Role;

has language => (
	is       => 'ro',
	default  => sub { 'C' },
);

1;
