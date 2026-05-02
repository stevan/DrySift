#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Scalar' => sub {
    my $ref = $alloc->Scalar( $alloc->Num(10) );
    isa_ok($ref, 'Ref');

    my $scalar = $ref->deref;
    isa_ok($scalar, 'Scalar');
    isa_ok($scalar->get, 'Num');

    is($ref->hash, $scalar->REF->hash, '... got the same reference');

    is($scalar->get->hash, $alloc->Num(10)->hash, '... same thing');

    $scalar->set( $alloc->Num(20) );
    isnt($scalar->get->hash, $alloc->Num(10)->hash, '... no longer the same thing');
    is($scalar->get->hash, $alloc->Num(20)->hash, '... same thing');

    my ($old) = $scalar->HISTORY;
    is($old, $alloc->Num(10)->hash, '... got the expected hash in the history');
};

done_testing;
