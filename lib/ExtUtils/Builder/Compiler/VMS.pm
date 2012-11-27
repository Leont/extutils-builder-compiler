package ExtUtils::Builder::Compiler::VMS;

use Moo;

with 'ExtUtils::Builder::Role::Compiler';

use Carp ();
use ExtUtils::Builder::Argument;

has '+command' => (
	default => sub { ['CC/DECC'] },
);

has _include_dirs => (
	is => 'ro',
	init_arg => undef,
	default => sub { [] },
);

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	push @{ $self->_include_dirs }, @{$dirs};
	return;
}

has _defines => (
	is => 'ro',
	init_arg => undef,
	default => sub { [] },
);

sub add_defines {
	my ($self, $defines, %opts) = @_;
	for my $key (keys %{$defines}) {
		push @{ $self->_defines }, defined $defines->{$key} ? $defines->{$key} ne '' ? qq/"$key=$defines->{$key}"/ : qq{"$key"} : Carp::croak("Can't undefine '$key'");
	}
	return;
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

around 'arguments' => sub {
	my ($orig, $self, @arguments) = @_;
	my @ret = $self->$orig(@arguments);
	push @ret, ExtUtils::Builder::Arguments(ranking => 30, value => $self->_include_dirs) if @{ $self->_include_dirs };
	push @ret, ExtUtils::Builder::Arguments(ranking => 40, value => $self->_defines) if @{ $self->_defines };
	return @ret;
};

sub compile_flags {
	my ($self, $from, $to) = @_;

	return ExtUtils::Builder::Argument->new(ranking => 75, value => [ "/obj=$to", $from ]);
}

sub language_flags {
}

1;

