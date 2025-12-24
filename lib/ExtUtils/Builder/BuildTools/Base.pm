package ExtUtils::Builder::BuildTools::Base;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use File::Spec::Functions 'catfile';

sub add_methods {
	my ($class, $planner, %opts) = @_;

	$opts{type} //= 'executable';

	my $compiler_as = delete $opts{compiler_as} // 'compile';
	$planner->add_delegate($compiler_as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);

		my $compiler = $class->make_compiler(\%args);

		$args{profiles} = [ delete $args{profile} ] if $args{profile} and not $args{profiles};
		for my $profile (@{ $args{profiles} // [] }) {
			$compiler->add_profile($profile, %args);
		}

		if (my $include_dirs = $args{include_dirs}) {
			$compiler->add_include_dirs($include_dirs);
		}
		if (my $defines = $args{defines}) {
			$compiler->add_defines($defines);
		}
		if (my $extra = $args{extra_args}) {
			$compiler->add_argument(value => $extra);
		}
		if (my $standard = $args{standard}) {
			$compiler->set_standard($standard);
		}

		my $node = $compiler->compile($from, $to, %args);
		return $planner->add_node($node);
	});

	my $linker_as = delete $opts{linker_as} // 'link';
	$planner->add_delegate($linker_as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);

		my $linker = $class->make_linker(\%args);

		$args{profiles} = [ delete $args{profile} ] if $args{profile} and not $args{profiles};
		for my $profile (@{ $args{profiles} // [] }) {
			$linker->add_profile($profile, %args);
		}

		if (my $library_dirs = $args{library_dirs}) {
			$linker->add_library_dirs($library_dirs);
		}
		if (my $libraries = $args{libraries}) {
			$linker->add_libraries($libraries);
		}
		if (my $extra_args = $args{extra_args}) {
			$linker->add_argument(ranking => 85, value => [ @{$extra_args} ]);
		}

		my $node = $linker->link($from, $to, %args);
		return $planner->add_node($node);
	});

	for my $name (qw/object_file library_file static_library_file loadable_file executable_file/) {
		my $format = $opts{$name} // croak "No known extension for $name";
		$planner->add_delegate($name, sub {
			my ($planner, $file, $dir) = @_;
			my $filename = sprintf $format, $file;
			return defined $dir ? catfile($dir, $filename) : $filename;
		});
	}
}

1;

# ABSTRACT: A base class for BuildTools implementations.

=head1 DESCRIPTION

This is a base-class for providers of compiler configuration. It defines the following delegates:

=head2 compile($source, $target, %options)

This compiles C<$source> to C<$target>. It takes the following optional arguments:

=over 4

=item type

The type of the final product. This must be one of:

=over 4

=item * executable

An executable to be run. This is the default.

=item * static-library

A static library to link against.

=item * dynamic-library

A dynamic library to link against.

=item * loadable-object

A loadable extension. On most platforms this is the same as a dynamic library, but some (Mac) make a distinction between these two.

=back

=item profiles

A list of profile that can be used when compiling and linking. One profile comes with this distribution: C<'@Perl'>, which sets up the appropriate things to compile/link with C<libperl>.

=item include_dirs

A list of directories to add to the include path, e.g. C<['include', '.']>.

=item define

A hash of preprocessor defines, e.g. C<< {DEBUG => 1, HAVE_FEATURE => 0 } >>

=item language

The language to use for compilation. Valid values are C<"C"> or C<"C++">.

=item standard

The language standard to use, e.g. C<"c99">, C<"c11">.

=item extra_args

A list of additional arguments to the compiler.

=back

=head2 link(\@sources, $target, %options)

=over 4

=item type

This works the same as with C<compile>.

=item profile

This works the same as with C<compile>.

=item language

This works the same as with C<compile>.

=item libraries

A list of libraries to link to. E.g. C<['z']>.

=item library_dirs

A list of directories to find libraries in. E.g. C<['/opt/my-app/lib/']>.

=item extra_args

A list of additional arguments to the linker.

=back

=head2 object_file($basename, $dir = undef)

Given a basename this will return the matching object file name.

=head2 library_file($basename, $dir = undef)

Given a basename this will return the matching shared library file name.

=head2 static_library_file($basename, $dir = undef)

Given a basename this will return the matching static library file name.

=head2 loadable_file($basename, $dir = undef)

Given a basename this will return the matching loadable library file name.

=head2 executable_file($basename, $dir = undef)

Given a basename this will return the matching executable file name.
