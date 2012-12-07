package ExtUtils::Builder::Role::Command;

use strict;
use warnings;
use Package::Variant
	importing => [ 'Moo::Role' ],
	subs => [ qw/has/ ];

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Plan;

use Carp ();

my %converter_for = (
	single   => sub {
		my ($source, $target, %opts) = @_;
		return ( $target, [ $source, @{ $opts{dependencies} || [] } ]);
	},
	multiple => sub {
		my ($source, $target, %opts) = @_;
		return ( $target, [ @{$source}, @{ $opts{dependencies} || [] } ]);
	},
);

sub make_variant {
	my ($class, $target_package, %arguments) = @_;

	my $method = $arguments{method} || Carp::croak('No method name given');
	my $policy_name = $arguments{source} || Carp::croak('No source type given');
	my $policy = ref $policy_name ? $policy_name : $converter_for{$policy_name};
	Carp::croak("Unknown policy '$policy_name'") if not $policy;

	has command => (
		is => 'ro',
		required => 1,
		coerce => sub {
			return ref $_[0] ? $_[0] : [ $_[0] ];
		}
	);

	has _arguments => (
		is => 'ro',
		default => sub { [] },
		init_arg => 'arguments',
	);

	install arguments => sub {
		my $self = shift;
		return @{ $self->_arguments };
	};

	install $_ => sub {} for qw/pre_action post_action/;

	has _option_filters => (
		is => 'ro',
		default => sub { [] },
	);
	install add_option_filter => sub {
		my ($self, $filter) = @_;
		push @{ $self->_option_filters }, $filter;
		return;
	};

	install $method, sub {
		my ($self, @args) = @_;
		@args = $self->$_(@args) for @{ $self->_option_filters };
		use sort 'stable';
		my @argv = map { @{ $_->value } } sort { $a->ranking <=> $b->ranking } $self->arguments(@args);
		my $main = ExtUtils::Builder::Action::Command->new(command => [ @{ $self->command }, @argv ]);
		my @actions = ($self->pre_action(@args), $main, $self->post_action(@args));
		my ($target, $deps) = $policy->(@args);
		return ExtUtils::Builder::Plan->new(target => $target, dependencies => $deps, actions => \@actions);
	};

	install add_argument => sub {
		my ($self, %opts) = @_;
		push @{ $self->_arguments }, ExtUtils::Builder::Argument->new(%opts);
		return;
	};

	install fix_ranking => sub {
		my (undef, $baseline, $override) = @_;
		return $baseline if not defined $override;
		return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
	};
	return;
}

1;
