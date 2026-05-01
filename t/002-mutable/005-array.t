#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Array' => sub {
    my $array = $alloc->Array( $alloc->Num(10), $alloc->Num(20), $alloc->Num(30) );
    isa_ok($array, 'Array');
};

done_testing;
