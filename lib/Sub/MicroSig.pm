package Sub::MicroSig;

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT = qw(MODIFY_CODE_ATTRIBUTES); ## no critic Export

use Carp ();

use Hook::LexWrap;
use Params::Validate::Micro qw(micro_validate);
use Sub::Identify qw(sub_fullname);

=head1 NAME

Sub::MicroSig - microsigs for microvalidation of sub arguments

=head1 VERSION

version 0.031

 $Id$

=cut

our $VERSION = '0.031';

=head1 SYNOPSIS

  use Sub::MicroSig;

  sub pow :Sig($x $pow; $trunc) {
    my $arg = shift;
    my $value = $arg->{x} ** $arg->{pow};

    $value = int $value if $arg->{trunc};
  }
  
  ...

  pow({ pow => 2, x => 4 }); # 64
  pow([ 2, 0.5, 1 ]);        #  1 # int(sqrt(2))

=head1 DESCRIPTION

This module allows you to give subroutine a signature using
L<Params::Validate::Micro>.

=head1 USAGE

To provide a signature to a subroutine, provide the attribute C<:Sig()>,
enclosing in the parentheses a valid L<Params::Validate::Micro> argument
string.

The routine will be wrapped so that its parameters are rewritten into the
result of calling C<micro_validate> on its passed arguments.  If more than one
argument is passed, or if the one passed argument is not an array or hash
reference, an exception is thrown by Sub::MicroSig.

The the given arguments cannot be validated according to the micro-argument
string, Params::Validate throws an exception.

To attach a signature to a method, use the C<:MethodSig()> attribute.  It will
check that the invocant (C<$_[0]>) is something on which a method could be
called and then pass the rest of the stack on for normal micro-validation.

=cut

my @code_to_sig;

sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $code, @attr) = @_;
  my ($signature, $is_method);
  my @leftovers;

  while (my $attr = shift @attr) {
    if ($attr =~ /\A Sig\(([^)]*)\) \z/x) {
      $signature = $1;
      last;
    } elsif ($attr =~ /\A Meth(?:od)?Sig\(([^)]*)\) \z/x) {
      $signature = $1;
      $is_method = 1;
      last;
    } else {
      push @leftovers, $attr;
    }
  }
  push @leftovers, @attr;

  push @code_to_sig, [ $code, $signature, $is_method ];

  return @leftovers;
}

sub _pre_wrapper {
  my ($signature, $is_method) = @_;

  my $arg_index = $is_method ? 1 : 0;
  my $this      = $is_method ? 'method' : 'sub';
  
  sub {
    pop; # We're removing $magick so that it doesn't interfere with validation.
    
    # in other words, if $_[0] can't support methods, you may not call a
    # microsig'd method on it. jeez!
    Carp::croak "microsig'd method not called on a valid invocant"
      if $is_method
      and not eval { $_[0]->can('can'); };

    # In other words, only if an argument was given:
    if ($#_ >= $arg_index) {
#     warn "checking $_[$arg_index]\n";
      Carp::croak "args to microsig'd $this must be a single array or hash ref"
        if @_ > ($arg_index+1)
        or not(ref $_[$arg_index])
        or ref $_[$arg_index] ne 'HASH' and ref $_[$arg_index] ne 'ARRAY';
#   } else {
#     warn "checking ()\n";
    }

    $_[$arg_index] = micro_validate($_[$arg_index], $signature);
  }
}

CHECK {
  for (@code_to_sig) {
    my $wrapper = _pre_wrapper(@$_[1,2]);
    wrap sub_fullname($_->[0]), pre => $wrapper;
  }
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head2 THANKS

Thanks, Hans Dieter Pearcey!  You wrote Params::Validate::Micro, and refrained
from wincing when I suggested this would be a nice use of it.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sub-microsig@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over

=item * L<Params::Validate::Micro>

=item * L<Params::Validate>

=back

=head1 COPYRIGHT

Copyright 2005-2006 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself. 

=cut

1;
