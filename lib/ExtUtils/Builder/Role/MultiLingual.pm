package ExtUtils::Builder::Role::MultiLingual;

use Moo::Role;

has language => (
	is       => 'ro',
	required => 1,
);

1;
