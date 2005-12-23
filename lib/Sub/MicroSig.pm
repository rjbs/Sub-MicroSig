package Sub::MicroSig;

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT = qw(MODIFY_CODE_ATTRIBUTES);

use Carp ();
use Data::Dump::Streamer;

use Hook::LexWrap;
use Params::Validate::Micro qw(micro_validate);
use Sub::Identify qw(sub_fullname);

=head1 NAME

Sub::MicroSig - The fantastic new Sub::MicroSig!

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Sub::MicroSig;

    sub pow :sig($x $pow; $trunc) {
      my $arg = shift;
      my $value = $arg->{x} ** $arg->{pow};

      $value = int $value if $arg->{trunc};
    }
    
    ...

    pow({ pow => 2, x => 4 }); # 64
    pow([ 2, 0.5, 1 ]);        #  1 # int(sqrt(2))

=head1 DESCRIPTION

This module allows you to give subroutine a signature using
Params::Validate::Micro.

=head1 FUNCTIONS

=head2 wrap_sub_with_sig

=cut

my @code_to_sig;

sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $code, @attr) = @_;
  my $signature;
  my @leftovers;

  while (my $attr = shift @attr) {
    if ($attr =~ /\A Sig\(([^)]+)\) \z/x) {
      $signature = $1;
      last;
    } else {
      push @leftovers, $attr;
    }
  }
  push @leftovers, @attr;

  push @code_to_sig, [ $code, $signature ];

  return @leftovers;
}

sub pre_wrapper {
  my ($signature) = @_;
  
  sub {
    my $magick = pop;
    Carp::croak "args to microsig'd sub must be a single array or hash ref"
      if @_ > 1
      or ! ref $_[0]
      or ref $_[0] ne 'HASH' and ref $_[0] ne 'ARRAY';
    $_[0] = micro_validate($_[0], $signature);
  }
}

CHECK {
  for (@code_to_sig) {
    my $wrapper = pre_wrapper($_->[1]);
    wrap sub_fullname($_->[0]), pre => $wrapper;
  }
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sub-microsig@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
