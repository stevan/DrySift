#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $lhs    = $alloc->Scalar( $alloc->Nil )->deref;
my $rhs    = $alloc->Scalar( $alloc->Nil )->deref;
my $output = $alloc->Scalar( $alloc->Nil )->deref;

my %stats;

$machine->connect(
    BinaryPropagator->new(
        lhs    => $lhs,
        rhs    => $alloc->Num(20),
        action => sub ($n, $m) {
            $stats{add}++;
            $alloc->Num( $n->value + $m->value )
        },
        output => $output
    )
);

$lhs->SET( $alloc->Num(10) );
$machine->execute;

is($output->GET->value, 30, '... got the expected value');

diag Dumper \%stats;

done_testing;

