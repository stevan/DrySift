#!perl

use v5.42;
use Test::More;
use Data::Dumper;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

my $tree = $alloc->Cons(
    $alloc->Num(10),
    $alloc->Cons(
        $alloc->Pair($alloc->Sym('y'), $alloc->Num(20)),
        $alloc->Cons(
            $alloc->Tuple(
                $alloc->Num(30),
                $alloc->Num(40),
                $alloc->Assoc(
                    $alloc->Pair($alloc->Sym('y'), $alloc->Num(20)),
                    $alloc->Assoc(
                        $alloc->Pair($alloc->Sym('z'), $alloc->Num(50)),
                        $alloc->Nil
                    )
                )
            ),
            $alloc->Nil
        )
    )
);

my $snapshot = $alloc->snapshot;

#say Dumper $snapshot;

my $alloc2 = Allocator->restore( $snapshot );
isa_ok($alloc2, 'Allocator');

ok($alloc2->lookup( $tree->hash ), '... found the hash');

done_testing;
