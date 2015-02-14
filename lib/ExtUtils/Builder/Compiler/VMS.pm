package ExtUtils::Builder::Compiler::VMS;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

use Carp ();

sub _build_cc {
	return ['CC/DECC'];
}

# The VMS compiler can only have one define and one include qualifier, so we need to juggle here

around 'add_argument' => sub {
	my ($orig, $self, %opts) = @_;
	my @value;
	for my $elem (@{ delete $opts{value} }) {
		if ($elem =~ m{ / def [^=]+ =+ (\()? ( [^/\)]* ) (?(1) \) ) }xi) {
			my @defines = $2 =~ m/ ( \w+ | "[^"]+" ) /gx;
			push @{ $self->_defines }, @defines;
		}
		elsif ($elem =~ m{ / inc [^=]+ =+ (\()?  ( [^/\)]* ) (?(1) \) ) }xi) {
			$self->add_include_dir([$2]);
		}
		else {
			push @value, $elem;
		}
	}
	$self->$orig(%opts, value => \@value);
	return;
};

sub compile_flags {
	my ($self, $from, $to) = @_;

	my @ret;
	my @include_dirs = map { $_->{value} } @{ $self->_include_dirs };
	my @defines = map { defined $_->{value} ? $_->{value} ne '' ? qq/"$_->{key}=$_->{value}"/ : qq{"$_->{key}"} : Carp::croak("Can't undefine '$key'") } @{ $self->_defines };
	push @ret, $self->new_argument(ranking => 30, value => [ '/include=' . join ',', @include_dirs) if @include_dirs;
	push @ret, $self->new_argument(ranking => 40, value => [ '/define=' . join ',', @defines)     if @defines;
	push @ret, $self->new_argument(ranking => 75, value => [ "/obj=$to", $from ]);
	return @ret;
}

1;

