#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;
use Propagators;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $upper  = $alloc->Scalar( $alloc->Str("") );
my $lower  = $alloc->Scalar( $alloc->Str("") );
my $output = $alloc->Scalar( $alloc->Str("") );

my %stats;

my $toLower = UnaryPropagator->new(
    input  => $upper,
    output => $lower,
    action => sub ($str) {
        $stats{toLower}++;
        $alloc->Str( lc $str->value )
    }
);

my $toUpper = UnaryPropagator->new(
    input  => $lower,
    output => $upper,
    action => sub ($str) {
        $stats{toUpper}++;
        $alloc->Str( uc $str->value )
    }
);

$toLower->connect($machine);
$toUpper->connect($machine);

$upper->deref->SET( $alloc->Str("HELLO") );
$machine->run;

is($lower->deref->GET->value, 'hello', '... got the expected lower value');
is($upper->deref->GET->value, 'HELLO', '... got the expected upper value');

$lower->deref->SET( $alloc->Str("goodbye") );
$machine->run;

is($lower->deref->GET->value, 'goodbye', '... got the expected lower value');
is($upper->deref->GET->value, 'GOODBYE', '... got the expected upper value');

diag Dumper \%stats;

done_testing;
