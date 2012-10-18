package ExtUtils::Builder::Linker::GCC::Darwin;

use Moo;

extends 'ExtUtils::Builder::Linker::GCC';

my %flag_for = (
	'loadable-object' => '-bundle',
	'shared-library' => '-dynamiclib',
);

around 'linker_flags' => sub {
	my ($orig, $self, %opts) = @_;
	my @ret = $self->$orig(%opts);
	unshift @ret, $flag_for{ $self->type } if $flag_for{ $self->type };
	return @ret;
};

1;
