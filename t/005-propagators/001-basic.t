#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $upper  = $alloc->Scalar( $alloc->Str("") )->deref;
my $lower  = $alloc->Scalar( $alloc->Str("") )->deref;

my %stats;

$machine->connect_unary(
    $upper,
    sub ($str) {
        $stats{toLower}++;
        #say "uc => lc : ".$str->value;
        $alloc->Str( lc $str->value )
    },
    $lower
);

$machine->connect_unary(
    $lower,
    sub ($str) {
        $stats{toUpper}++;
        #say "lc => uc : ".$str->value;
        $alloc->Str( uc $str->value )
    },
    $upper
);

$upper->SET( $alloc->Str("HELLO") );
$machine->execute;

is($lower->GET->value, 'hello', '... got the expected lower value');
is($upper->GET->value, 'HELLO', '... got the expected upper value');

$lower->SET( $alloc->Str("goodbye") );
$machine->execute;

is($lower->GET->value, 'goodbye', '... got the expected lower value');
is($upper->GET->value, 'GOODBYE', '... got the expected upper value');

# these should not trigger anything
$upper->SET( $alloc->Str("GOODBYE") );
$lower->SET( $alloc->Str("goodbye") );

is_deeply(\%stats, { toLower => 2, toUpper => 2 }, '... expected stats');

#diag 'STATS: ', Dumper \%stats;
#diag 'UPPER: ', join ', ' => $upper->HISTORY;
#diag 'LOWER: ', join ', ' => $lower->HISTORY;

done_testing;
