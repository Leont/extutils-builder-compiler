package ExtUtils::Builder::Role::Action;

use Moo::Role;

requires qw/_preference_map execute to_code to_command/;

use Carp ();

my %valid_preference = map { $_ => 1 } qw/code command flatten/;
my $error = 'preference must be one of ' . join ', ', keys %valid_preference;

sub preference {
	my ($self, @possibilities) = @_;
	my $map = $self->_preference_map;
	my @keys = @possibilities ? @possibilities : keys %{$map};
	my ($ret) = reverse sort { $map->{$a} <=> $map->{$b} } @keys;
	return $ret;
}

sub flatten {
	my $self = shift;
	return $self;
}

1;
