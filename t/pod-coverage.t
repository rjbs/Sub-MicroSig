use Test::More;
eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
	if $@;

use Sub::MicroSig;

all_pod_coverage_ok({ also_private => [ qr/\AMODIFY_CODE/ ] });
