#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $upper  = $alloc->Scalar( $alloc->Nil )->deref;
my $lower  = $alloc->Scalar( $alloc->Nil )->deref;

my %stats;

$machine->connect(
    UnaryPropagator->new(
        input  => $upper,
        action => sub ($str) {
            $stats{toLower}++;
            #say "uc => lc : ".$str->value;
            $alloc->Str( lc $str->value )
        },
        output => $lower
    ),
    UnaryPropagator->new(
        input  => $lower,
        action => sub ($str) {
            $stats{toUpper}++;
            #say "lc => uc : ".$str->value;
            $alloc->Str( uc $str->value )
        },
        output => $upper
    )
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
