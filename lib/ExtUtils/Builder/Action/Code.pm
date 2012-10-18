package ExtUtils::Builder::Action::Code;

use Moo;

with 'ExtUtils::Builder::Role::Action';

has code => (
	is => 'ro',
	required => 1,
);

sub execute {
	my ($self, %opts) = @_;
	$self->code->(%{ $self->arguments }, %opts);
	return;
}

has serialized => (
	is => 'lazy',
	default => sub {
		my $self = shift;

		require B::Deparse;
		my $core = B::Deparse->new('-sCi0')->coderef2text($self->code);
		$core =~ s/ \A { \n? (.*?) ;? \n? } \z /{ $1 }/mx;
		my $args = $self->arguments;
		if (keys %{$args}) {
			require Data::Dumper;
			my $args = Data::Dumper->new([ $args ])->Terse(1)->Indent(0)->Dump;
			return "(sub $core)->(%{ $args }, \@ARGV)";
		}
		else {
			return "(sub $core)->(\@ARGV)";
		}
	},
	predicate => '_has_serialized',
);

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
	my $text = $self->serialized;
	my $perl = _get_perl(%opts);
	my @modules = map { "-M$_" } @{ $self->_modules };
	return ($perl, @modules, '-e', $text);
}

1;
