#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $F = $alloc->Scalar( $alloc->Num(0) );
my $C = $alloc->Scalar( $alloc->Num(0) );

my $_f_32 = $alloc->Scalar( $alloc->Num(0) );
my $_c_9  = $alloc->Scalar( $alloc->Num(0) );
my $_c_5  = $alloc->Scalar( $alloc->Num(0) );

my %stats;

# c = (f - 32) * 5 / 9

$machine->connect_unary(
    $F->deref,
    sub ($n) {
        $stats{'f - 32'}++;
        say "HEY $n - 32";
        $alloc->Num( $n->value - 32 )
    },
    $_f_32->deref
);

$machine->connect_unary(
    $_f_32->deref,
    sub ($n) {
        $stats{'(f - 32) * 5'}++;
        say "HEY $n * 5";
        $alloc->Num( $n->value * 5 )
    },
    $_c_9->deref
);

$machine->connect_unary(
    $_c_9->deref,
    sub ($n) {
        $stats{'(f - 32) * 5 / 9'}++;
        say "HEY $n / 9";
        $alloc->Num( $n->value / 9 )
    },
    $C->deref
);

# f = c * 5 / 9 + 32

$machine->connect_unary(
    $C->deref,
    sub ($n) {
        $stats{'C * 9'}++;
        say "HO $n * 9";
        $alloc->Num( $n->value * 9 )
    },
    $_c_9->deref
);

$machine->connect_unary(
    $_c_9->deref,
    sub ($n) {
        $stats{'C * 5 / 9'}++;
        say "HO $n + 32";
        $alloc->Num( $n->value / 5 )
    },
    $_c_5->deref
);

$machine->connect_unary(
    $_c_5->deref,
    sub ($n) {
        $stats{'C * 9 / 5 + 32'}++;
        say "HO $n / 5";
        $alloc->Num( $n->value + 32 )
    },
    $F->deref,
);


$F->deref->SET( $alloc->Num(212) );
$machine->execute;

say ">>> F        : ", $F->deref->GET;
say ">>> (f - 32) : ", $_f_32->deref->GET;
say ">>> (c * 9)  : ", $_c_9->deref->GET;
say ">>> (c * 5)  : ", $_c_5->deref->GET;
say ">>> C        : ", $C->deref->GET;

is($C->deref->GET->value, 100, '... got the right C');

$C->deref->SET( $alloc->Num(0) );
$machine->execute;

say ">>> F        : ", $F->deref->GET;
say ">>> (f - 32) : ", $_f_32->deref->GET;
say ">>> (c * 9)  : ", $_c_9->deref->GET;
say ">>> (c * 5)  : ", $_c_5->deref->GET;
say ">>> C        : ", $C->deref->GET;

is($F->deref->GET->value, 32, '... got the right F');

$F->deref->SET( $alloc->Num(77) );
$C->deref->SET( $alloc->Num(25) );
$machine->execute;

say ">>> F        : ", $F->deref->GET;
say ">>> (f - 32) : ", $_f_32->deref->GET;
say ">>> (c * 9)  : ", $_c_9->deref->GET;
say ">>> (c * 5)  : ", $_c_5->deref->GET;
say ">>> C        : ", $C->deref->GET;

is($C->deref->GET->value, 25, '... got the right C');

$C->deref->SET( $alloc->Num(25) );
$machine->execute;

#diag 'STATS: ', Dumper \%stats;
#diag 'F: ', join ', '  => $F->deref->HISTORY;
#diag 'C: ', join ', '  => $C->deref->HISTORY;

done_testing;

