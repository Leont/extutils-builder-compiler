package ExtUtils::Builder::Action::Code;

use Moo;

with 'ExtUtils::Builder::Role::Action::Logging';

use Carp ();
use Module::Runtime ();

has code => (
	is => 'lazy',
	default => sub {
		my $self = shift;
		return eval(sprintf 'sub { %s }', $self->serialized) || Carp::croak("Couldn't evaluate serialized: $@");
	},
	predicate => '_has_code',
);

has message => (
	is => 'ro',
	predicate => '_has_message'
);

sub execute {
	my ($self, %opts) = @_;
	Module::Runtime::require_module($_) for @{ $self->_modules };
	($opts{logger} || $self->logger)->($self->message) if $self->_has_message && !$opts{quiet};
	$self->code->(%{ $self->arguments }, %opts);
	return;
}

has serialized => (
	is => 'lazy',
	default => sub {
		my $self = shift;

		require B::Deparse;
		my $core = B::Deparse->new('-sCi0')->coderef2text($self->code);
		$core =~ s/ \A { ( .* ) } \z /$1/msx;
		$core =~ s/ \A \n? (.*?) ;? \n? \z /$1/mx;
		return $core;
	},
	predicate => '_has_serialized',
);

sub BUILD {
	my $self = shift;
	Carp::croak('Need to define at least one of code or serialized') if !$self->_has_code && !$self->_has_serialized;
	return;
}

has arguments => (
	is => 'ro',
	default => sub { {} },
);

has _modules => (
	is => 'ro',
	init_arg => 'modules',
	default => sub { [] },
);

sub _get_perl {
	my %opts = @_;
	return $opts{perl} if $opts{perl};
	require Devel::FindPerl;
	return Devel::FindPerl::find_perl_interpreter($opts{config});
}

sub serialize {
	my ($self, %opts) = @_;
	my $serialized = $self->serialized;
	my $args = %{ $self->arguments } ? do { 
		require Data::Dumper;
		sprintf '%%{ %s }, @ARGV', Data::Dumper->new([ $self->arguments ])->Terse(1)->Indent(0)->Dump;
	} : '@ARGV';
	my $perl = _get_perl(%opts);
	my @modules = map { "-M$_" } @{ $self->_modules };
	return [ $perl, @modules, '-e', "(sub { $serialized })->($args)" ];
}

1;
