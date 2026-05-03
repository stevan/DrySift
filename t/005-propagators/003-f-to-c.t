#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $F = $alloc->Scalar( $alloc->Nil )->deref;
my $C = $alloc->Scalar( $alloc->Nil )->deref;

my $_f_32 = $alloc->Scalar( $alloc->Nil )->deref;
my $_c_9  = $alloc->Scalar( $alloc->Nil )->deref;

my %stats;

# c = (f - 32) * 5 / 9
my @to_C = (
    BinaryPropagator->new(
        lhs    => $F,
        rhs    => $alloc->Num(32),
        action => sub ($n, $m) {
            $stats{'f - 32'}++;
            say "F->C @ 1. $n - $m";
            $alloc->Num( $n->value - $m->value )
        },
        output => $_f_32
    ),
    BinaryPropagator->new(
        lhs    => $_f_32,
        rhs    => $alloc->Num(5),
        action => sub ($n, $m) {
            $stats{'(f - 32) * 5'}++;
            say "F->C @ 2. $n * $m";
            $alloc->Num( $n->value * $m->value )
        },
        output => $_c_9
    ),
    BinaryPropagator->new(
        lhs    => $_c_9,
        rhs    => $alloc->Num(9),
        action => sub ($n, $m) {
            $stats{'(f - 32) * 5 / 9'}++;
            say "F->C @ 3. $n / $m";
            $alloc->Num( $n->value / $m->value )
        },
        output => $C
    )
);

# f = c * 5 / 9 + 32
my @to_F = (
    BinaryPropagator->new(
        lhs    => $C,
        rhs    => $alloc->Num(9),
        action => sub ($n, $m) {
            $stats{'C * 9'}++;
            say "C->F @ 1. $n * $m";
            $alloc->Num( $n->value * $m->value )
        },
        output => $_c_9
    ),
    BinaryPropagator->new(
        lhs    => $_c_9,
        rhs    => $alloc->Num(5),
        action => sub ($n, $m) {
            $stats{'C * 5 / 9'}++;
            say "C->F @ 2. $n + $m";
            $alloc->Num( $n->value / $m->value )
        },
        output => $_f_32
    ),
    BinaryPropagator->new(
        lhs    => $_f_32,
        rhs    => $alloc->Num(32),
        action => sub ($n, $m) {
            $stats{'C * 9 / 5 + 32'}++;
            say "C->F @ 3. $n / $m";
            $alloc->Num( $n->value + $m->value )
        },
        output => $F,
    )
);

$machine->connect( @to_C );
$machine->connect( @to_F );

$F->SET( $alloc->Num(212) );
$machine->execute;

# say ">>> F        : ", $F->GET;
# say ">>> (f - 32) : ", $_f_32->GET;
# say ">>> (c * 9)  : ", $_c_9->GET;
# say ">>> C        : ", $C->GET;

is($C->GET->value, 100, '... got the right C');

$C->SET( $alloc->Num(0) );
$machine->execute;

# say ">>> F        : ", $F->GET;
# say ">>> (f - 32) : ", $_f_32->GET;
# say ">>> (c * 9)  : ", $_c_9->GET;
# say ">>> C        : ", $C->GET;

is($F->GET->value, 32, '... got the right F');

$F->SET( $alloc->Num(77) );
$C->SET( $alloc->Num(25) );
$machine->execute;

# say ">>> F        : ", $F->GET;
# say ">>> (f - 32) : ", $_f_32->GET;
# say ">>> (c * 9)  : ", $_c_9->GET;
# say ">>> C        : ", $C->GET;

is($C->GET->value, 25, '... got the right C');

$C->SET( $alloc->Num(25) );
$machine->execute;

#diag 'STATS: ', Dumper \%stats;
#diag 'F        : ', join ', ' => $F->HISTORY;
#diag '(f - 32) : ', join ', ' => $_f_32->HISTORY;
#diag '(c * 9)  : ', join ', ' => $_c_9->HISTORY;
#diag 'C        : ', join ', ' => $C->HISTORY;

done_testing;

