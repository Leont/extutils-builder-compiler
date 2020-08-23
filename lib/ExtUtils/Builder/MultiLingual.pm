package ExtUtils::Builder::MultiLingual;

use strict;
use warnings;

use Carp ();

sub _init {
	my ($self, %args) = @_;
	$self->{language} = $args{language} or Carp::croak('language missing');
	return;
}

sub language {
	my $self = shift;
	return $self->{language};
}

1;
