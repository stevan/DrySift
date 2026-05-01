#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... List' => sub {
    my $list = $alloc->List( $alloc->Num(10), $alloc->Num(20), $alloc->Num(30) );
    isa_ok($list, 'List');
};

done_testing;
