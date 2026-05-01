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
    );
    isa_ok($struct, 'Struct');
};

done_testing;
