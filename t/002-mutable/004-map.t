#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Map' => sub {
    my $map = $alloc->Map(
        $alloc->Pair( $alloc->Sym('foo'), $alloc->Num(10) ),
        $alloc->Pair( $alloc->Sym('bar'), $alloc->Num(20) ),
        $alloc->Pair( $alloc->Sym('baz'), $alloc->Num(30) ),
    )->deref;
    isa_ok($map, 'Map');
};

done_testing;
