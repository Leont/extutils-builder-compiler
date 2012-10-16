package ExtUtils::Builder::Action::Code;

use Moo;

with 'ExtUtils::Builder::Role::Action';

has code => (
	is => 'ro',
	required => 1,
);

sub execute {
	my ($self, @args) = @_;
	$self->code->(@args);
	return;
}

has serialized => (
	is => 'lazy',
	default => sub {
		my $self = shift;

		require B::Deparse;
		return B::Deparse->new->coderef2text($self->code);
	}
);

has _modules => (
	is => 'ro',
	init_arg => 'modules',
	default => sub { [] },
);

sub _get_perl {
	my %args = @_;
	return $args{perl} if $args{perl};
	require Devel::FindPerl;
	return Devel::FindPerl::find_perl_interpreter($args{config});
}

sub serialize {
	my ($self, %args) = @_;
	my $text = $self->serialized;
	my $perl = _get_perl(%args);
	my @modules = map { "-M$_" } @{ $self->_modules };
	return ($perl, @modules, '-e', $text);
}

1;
