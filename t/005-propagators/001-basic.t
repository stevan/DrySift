#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $upper  = $alloc->Scalar( $alloc->Str("") );
my $lower  = $alloc->Scalar( $alloc->Str("") );

my %stats;

$machine->connect_unary(
    $upper->deref,
    sub ($str) {
        $stats{toLower}++;
        #say "uc => lc : ".$str->value;
        $alloc->Str( lc $str->value )
    },
    $lower->deref
);

$machine->connect_unary(
    $lower->deref,
    sub ($str) {
        $stats{toUpper}++;
        #say "lc => uc : ".$str->value;
        $alloc->Str( uc $str->value )
    },
    $upper->deref
);

$upper->deref->SET( $alloc->Str("HELLO") );
$machine->execute;

is($lower->deref->GET->value, 'hello', '... got the expected lower value');
is($upper->deref->GET->value, 'HELLO', '... got the expected upper value');

$lower->deref->SET( $alloc->Str("goodbye") );
$machine->execute;

is($lower->deref->GET->value, 'goodbye', '... got the expected lower value');
is($upper->deref->GET->value, 'GOODBYE', '... got the expected upper value');

# these should not trigger anything
$upper->deref->SET( $alloc->Str("GOODBYE") );
$lower->deref->SET( $alloc->Str("goodbye") );

is_deeply(\%stats, { toLower => 2, toUpper => 2 }, '... expected stats');

#diag 'STATS: ', Dumper \%stats;
#diag 'UPPER: ', join ', ' => $upper->deref->HISTORY;
#diag 'LOWER: ', join ', ' => $lower->deref->HISTORY;

done_testing;
