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
my $output = $alloc->Scalar( $alloc->Str("") )->deref;

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

$machine->connect_binary(
    $upper,
    $lower,
    sub ($n, $m) {
        $stats{concat}++;
        #say "YO! -->>> ", $n->value . $m->value;
        $alloc->Str( $n->value . $m->value )
    },
    $output
);

$upper->SET( $alloc->Str("HELLO") );
$machine->execute;

is($lower->GET->value, 'hello', '... got the expected lower value');
is($upper->GET->value, 'HELLO', '... got the expected upper value');
is($output->GET->value, 'HELLOhello', '... got the expected concat value');

$lower->SET( $alloc->Str("goodbye") );
$machine->execute;

is($lower->GET->value, 'goodbye', '... got the expected lower value');
is($upper->GET->value, 'GOODBYE', '... got the expected upper value');
is($output->GET->value, 'GOODBYEgoodbye', '... got the expected concat value');

# these should not do anything
$lower->SET( $alloc->Str("goodbye") );
$upper->SET( $alloc->Str("GOODBYE") );

is_deeply(\%stats, { toLower => 2, toUpper => 2, concat => 2 }, '... expected stats');

#diag 'STATS: ', Dumper \%stats;
#diag 'UPPER: ', join ', '  => $upper->HISTORY;
#diag 'LOWER: ', join ', '  => $lower->HISTORY;
#diag 'OUTPUT: ', join ', ' => $output->HISTORY;

done_testing;

