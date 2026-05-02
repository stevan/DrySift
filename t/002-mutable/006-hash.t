#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Hash' => sub {
    my $hash = $alloc->Hash(
        foo => $alloc->Num(10),
        bar => $alloc->Num(20),
        baz => $alloc->Num(30),
    )->deref;
    isa_ok($hash, 'Hash');
};

done_testing;
