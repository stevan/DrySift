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
isa_ok($tree, 'Cons');

my $ref = $alloc->Scalar( $alloc->Num(10) );
isa_ok($ref, 'Ref');

my $scalar = $ref->deref;
isa_ok($scalar, 'Scalar');

my $snapshot = $alloc->snapshot;

my $alloc2 = Allocator->restore( $snapshot );
isa_ok($alloc2, 'Allocator');

ok($alloc2->lookup( $tree->hash ), '... found the tree hash');
ok($alloc2->lookup( $ref->hash ), '... found the ref hash');

my $scalar2 = $alloc2->deref( $ref->uuid );
ok(defined $scalar2, '... found the Scalar uuid');
is($scalar2->uuid, $scalar->uuid, '... UUIDS match');

isnt(refaddr $scalar2, refaddr $scalar, '... different instances match');

done_testing;
