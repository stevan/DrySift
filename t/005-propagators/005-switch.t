#!perl

use v5.42;
use experimental qw[ class ];
use Test::More;
use Data::Dumper;

use Repository;

my $repo    = Repository->new;
my $alloc   = $repo->alloc;
my $machine = $repo->machine;

my $control  = $alloc->Scalar( $alloc->Nil )->deref;
my $input    = $alloc->Scalar( $alloc->Nil )->deref;
my $if_true  = $alloc->Scalar( $alloc->Nil )->deref;
my $if_false = $alloc->Scalar( $alloc->Nil )->deref;

my %stats;

$machine->connect(
    SwitchPropagator->new(
        control  => $control,
        input    => $input,
        if_true  => $if_true,
        if_false => $if_false,
    )
);

$input->SET( $alloc->Num(30) );
#say "SET INPUT";
#say "  CONTROL  : ",$control->GET;
#say "  INPUT    : ",$input->GET;
#say "  IF TRUE  : ",$if_true->GET;
#say "  IF FALSE : ",$if_false->GET;

ok($if_true->GET->is_nil, '... nothing triggered');
ok($if_false->GET->is_nil, '... nothing triggered');

$control->SET( $alloc->True );
#say "SET CONTROL";
#say "  CONTROL  : ",$control->GET;
#say "  INPUT    : ",$input->GET;
#say "  IF TRUE  : ",$if_true->GET;
#say "  IF FALSE : ",$if_false->GET;

ok($if_true->GET->is_nil, '... nothing triggered');
ok($if_false->GET->is_nil, '... nothing triggered');

$machine->execute;
#say "EXECUTED";
#say "  CONTROL  : ",$control->GET;
#say "  INPUT    : ",$input->GET;
#say "  IF TRUE  : ",$if_true->GET;
#say "  IF FALSE : ",$if_false->GET;

is($if_true->GET->value,  30, '... got the expected value');
ok($if_false->GET->is_nil, '... got the expected value');

$control->SET( $alloc->False );
#say "SET CONTROL";
#say "  CONTROL  : ",$control->GET;
#say "  INPUT    : ",$input->GET;
#say "  IF TRUE  : ",$if_true->GET;
#say "  IF FALSE : ",$if_false->GET;

$machine->execute;
#say "EXECUTED";
#say "  CONTROL  : ",$control->GET;
#say "  INPUT    : ",$input->GET;
#say "  IF TRUE  : ",$if_true->GET;
#say "  IF FALSE : ",$if_false->GET;

is($if_true->GET->value,   30, '... got the expected value');
is($if_false->GET->value,  30, '... got the expected value');

#diag Dumper \%stats;

done_testing;

