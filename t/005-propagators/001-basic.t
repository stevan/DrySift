#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;
use Propagators;

my $repo  = Repository->new;
my $alloc = $repo->alloc;


my $upper  = $alloc->Scalar( $alloc->Str("") );
my $lower  = $alloc->Scalar( $alloc->Str("") );
my $output = $alloc->Scalar( $alloc->Str("") );

my $toLower = UnaryPropagator->new(
    input  => $upper,
    output => $lower,
    action => sub ($str) {
        $alloc->Str( lc $str->value )
    }
);

my $toUpper = UnaryPropagator->new(
    input  => $lower,
    output => $upper,
    action => sub ($str) {
        $alloc->Str( uc $str->value )
    }
);

my $concat = BinaryPropagator->new(
    lhs    => $upper,
    rhs    => $lower,
    output => $output,
    action => sub ($n, $m) {
        $alloc->Str( $n->value . $m->value )
    }
);

my $ran = 0;

$lower->deref->WATCH(sub ($cell) {
    state $times = 0;
    if ($times == 0) {
        is($cell->GET->value, 'hello', '... toLower fired, got the expected value');
    } elsif ($times == 1) {
        is($cell->GET->value, 'goodbye', '... toLower fired, got the expected value');
    }
    $times++;
    $ran++;
});

$output->deref->WATCH(sub ($cell) {
    state $times = 0;
    if ($times == 0) {
        is($cell->GET->value, 'HELLOhello', '... concat fired, got the expected value');
    } elsif ($times == 1) {
        is($cell->GET->value, 'GOODBYEgoodbye', '... concat fired, got the expected value');
    }
    $times++;
    $ran++;
});

$toLower->connect;
$toUpper->connect;
$concat->connect;

$upper->deref->SET( $alloc->Str("HELLO") );

$upper->deref->WATCH(sub ($cell) {
    is($cell->GET->value, 'GOODBYE', '... toUpper fired, got the expected value');
    $ran++;
});

$lower->deref->SET( $alloc->Str("goodbye") );

is($ran, 5, '... the expected number of triggers happened');

done_testing;
