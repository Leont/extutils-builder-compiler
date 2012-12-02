package ExtUtils::Builder::Role::Action;

use Moo::Role;

requires qw/execute serialize/;

sub flatten {
	my $self = shift;
	return $self;
}

1;
