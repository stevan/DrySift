#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo  = Repository->new;
my $alloc = $repo->alloc;

my $tree = $repo->bind('$tree' => $alloc->Cons(
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
));

my $scalar = $repo->bind('$scalar' => $alloc->Scalar( $alloc->Num(10) ) );
isa_ok($scalar, 'Ref');
isa_ok($scalar->deref, 'Scalar');
isa_ok($scalar->deref->GET, 'Num');

my $snapshot = $repo->snapshot;

#say Dumper $snapshot;

my $repo2 = Repository->restore( $snapshot );
isa_ok($repo2, 'Repository');

is($repo->resolve('$tree')->hash, $repo2->resolve('$tree')->hash, '... got the same $tree in both');
is($repo->resolve('$scalar')->hash, $repo2->resolve('$scalar')->hash, '... got the same $scalar in both');

done_testing;
