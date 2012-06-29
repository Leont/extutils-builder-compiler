package ExtUtils::Builder::Role::Compiler;

use Moo::Role;

with 'ExtUtils::Builder::Role::ToolchainCommand';

requires qw/add_include_dirs add_defines language_flags compile_flags/;

sub compile {
	my ($self, $from, $to, %opts) = @_;

	my @arguments = ($self->arguments, $self->language_flags, $self->compile_flags($from, $to));

	my $action = ExtUtils::Builder::Action::Command->new(program => $self->command, arguments => \@arguments);
	return ExtUtils::Builder::ActionSet->new($action);
}
1;
