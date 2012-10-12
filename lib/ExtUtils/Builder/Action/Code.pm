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

has command => (
	is => 'ro',
	default => sub {
		my $self = shift;

		require B::Deparse;
		my $text = B::Deparse->new->coderef2text($self->code);

		require Devel::FindPerl;
		return [ Devel::FindPerl::find_perl_interpreter(), '-e', $text ];
	}
);

sub listify {
	my $self = shift;
	return @{ $self->command };
}

1;
