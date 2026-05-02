#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Struct' => sub {
    my $struct = $alloc->Struct(
        foo => $alloc->Num(10),
        bar => $alloc->Num(20)
    )->deref;
    isa_ok($struct, 'Struct');

    my $struct2 = $alloc->Struct(
        foo => $alloc->Num(10),
        bar => $alloc->Num(20)
    )->deref;
    isa_ok($struct2, 'Struct');

    is($struct->GET->hash, $struct2->GET->hash, '... internally the same');
    isnt($struct->uuid, $struct2->uuid, '... but unique references');

    $struct2->set(foo => $alloc->Num(100));
    isnt($struct->GET->hash, $struct2->GET->hash, '... internally no longer the same');

};

done_testing;
