package ExtUtils::Builder::Role::Command;

use strict;
use warnings;
use Package::Variant
	importing => [ 'Moo::Role' ],
	subs => [ qw/has/ ];

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::ActionSet;

sub make_variant {
	my ($class, $target_package, %arguments) = @_;

	has command => (
		is => 'ro',
		required => 1,
	);

	has _arguments => (
		is => 'ro',
		default => sub { [] },
		init_arg => 'arguments',
	);

	has env => (
		is      => 'ro',
		default => sub { {} },
	);

	install 'arguments' => sub {
		my $self = shift;
		return @{ $self->_arguments };
	};

	install $arguments{method}, sub {
		my ($self, @args) = @_;
		use sort 'stable';
		my @argv = map { @{ $_->value } } sort { $a->ranking <=> $b->ranking } $self->arguments(@args);
		my $action = ExtUtils::Builder::Action::Command->new(program => $self->command, arguments => \@argv, env => $self->env);
		return ExtUtils::Builder::ActionSet->new($action);
	};

	install add_argument => sub {
		my ($self, %opts) = @_;
		push @{ $self->_arguments }, ExtUtils::Builder::Argument->new(%opts);
		return;
	};

	install _fix_ranking => sub {
		my ($baseline, $override) = @_;
		return $baseline if not defined $override;
		return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
	};
	return;
}

1;
