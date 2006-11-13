#!perl -T
use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('Sub::MicroSig'); }

sub method_with_params :MethodSig(foo) {
  shift;
  return @_;
}

is_deeply(
  main->method_with_params({ foo => 20 }),
  { foo => 20 },
  "named params to simple sig"
);

is_deeply(
  main->method_with_params([ 20 ]),
  { foo => 20 },
  "positional params to simple sig"
);

eval { main::method_with_params(undef, [ 20 ]); };
like($@, qr/valid invocant/, "a method must have a valid invocant");

eval { main->method_with_params(10); };
like($@, qr/args to microsig'd method/, "a plain scalar isn't an OK arg");

eval { main->method_with_params([1], [2]); };
like($@, qr/args to microsig'd method/, "you can only give one arg");

eval { main->method_with_params([1, 2]); };
like($@, qr/too many arguments/, "error propagated up from P::V");
