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
my $output = $alloc->Scalar( $alloc->Str("") );

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

$machine->connect_binary(
    $upper->deref,
    $lower->deref,
    sub ($n, $m) {
        $stats{concat}++;
        #say "YO! -->>> ", $n->value . $m->value;
        $alloc->Str( $n->value . $m->value )
    },
    $output->deref
);

$upper->deref->SET( $alloc->Str("HELLO") );
$machine->execute;

is($lower->deref->GET->value, 'hello', '... got the expected lower value');
is($upper->deref->GET->value, 'HELLO', '... got the expected upper value');
is($output->deref->GET->value, 'HELLOhello', '... got the expected concat value');

$lower->deref->SET( $alloc->Str("goodbye") );
$machine->execute;

is($lower->deref->GET->value, 'goodbye', '... got the expected lower value');
is($upper->deref->GET->value, 'GOODBYE', '... got the expected upper value');
is($output->deref->GET->value, 'GOODBYEgoodbye', '... got the expected concat value');

# these should not do anything
$lower->deref->SET( $alloc->Str("goodbye") );
$upper->deref->SET( $alloc->Str("GOODBYE") );

is_deeply(\%stats, { toLower => 2, toUpper => 2, concat => 2 }, '... expected stats');

#diag 'STATS: ', Dumper \%stats;
#diag 'UPPER: ', join ', '  => $upper->deref->HISTORY;
#diag 'LOWER: ', join ', '  => $lower->deref->HISTORY;
#diag 'OUTPUT: ', join ', ' => $output->deref->HISTORY;

done_testing;

