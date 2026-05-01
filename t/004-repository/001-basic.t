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

my $snapshot = $repo->snapshot;

say Dumper $snapshot;

my $repo2 = Repository->restore( $snapshot );
isa_ok($repo2, 'Repository');

is($repo->resolve('$tree')->hash, $repo2->resolve('$tree')->hash, '... got the same in both');

done_testing;
