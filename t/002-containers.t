#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Pair' => sub {
    my $lhs = $alloc->Num(10);
    isa_ok($lhs, 'Num');

    my $rhs = $alloc->Num(10);
    isa_ok($rhs, 'Num');

    my $pair = $alloc->Pair($lhs, $rhs);
    isa_ok($pair, 'Pair');

    my $pair2 = $alloc->Pair($lhs, $rhs);
    isa_ok($pair2, 'Pair');

    is($pair->hash, $pair2->hash, '... same thing (hashed)');
    is(refaddr $pair, refaddr $pair2, '... same thing (refaddr)');

    is($pair->first->hash, $pair2->first->hash, '... same first (hashed)');
    is($pair->second->hash, $pair2->second->hash, '... same second (hashed)');
};

subtest '... Cons' => sub {
    my $list = $alloc->Cons( $alloc->Num(10), $alloc->Nil );
    isa_ok($list, 'Cons');
    my $list2 = $alloc->Cons( $alloc->Num(10), $alloc->Nil );
    isa_ok($list2, 'Cons');

    is($list->hash, $list2->hash, '... same thing (hashed)');
    is(refaddr $list, refaddr $list2, '... same thing (refaddr)');

    my $list3 = $alloc->Cons( $alloc->Num(20), $alloc->Cons( $alloc->Num(10), $alloc->Nil ) );
    isa_ok($list3, 'Cons');

    is($list3->tail->hash, $list->hash, '... same thing for tail (hashed)');
};

subtest '... Assoc' => sub {
    my $assoc = $alloc->Assoc( $alloc->Pair( $alloc->Sym('Foo'), $alloc->Num(10) ), $alloc->Nil );
    isa_ok($assoc, 'Assoc');
    my $assoc2 = $alloc->Assoc( $alloc->Pair( $alloc->Sym('Foo'), $alloc->Num(10) ), $alloc->Nil );
    isa_ok($assoc2, 'Assoc');

    is($assoc->hash, $assoc2->hash, '... same thing (hashed)');
    is(refaddr $assoc, refaddr $assoc2, '... same thing (refaddr)');

    my $assoc3 = $alloc->Assoc(
        $alloc->Pair( $alloc->Sym('Bar'), $alloc->Num(20) ),
        $alloc->Assoc(
            $alloc->Pair( $alloc->Sym('Foo'), $alloc->Num(10) ),
            $alloc->Nil
        )
    );
    isa_ok($assoc3, 'Assoc');

    my $key = $alloc->Sym('Foo');
    is($assoc3->lookup($key)->hash, $assoc->lookup($key)->hash, '... same thing for lookup (hashed)');
};

subtest '... Tuple' => sub {
    my $tuple = $alloc->Tuple( $alloc->Num(10), $alloc->Num(20), $alloc->Str("Foo") );
    isa_ok($tuple, 'Tuple');
    my $tuple2 = $alloc->Tuple( $alloc->Num(10), $alloc->Num(20), $alloc->Str("Foo") );
    isa_ok($tuple2, 'Tuple');

    is($tuple->length, 3, '... got the right length');

    is($tuple->hash, $tuple2->hash, '... same thing (hashed)');
    is(refaddr $tuple, refaddr $tuple2, '... same thing (refaddr)');
};

subtest '... Record' => sub {
    my $record = $alloc->Record( foo => $alloc->Num(10), bar => $alloc->Num(20), baz => $alloc->Str("Foo") );
    isa_ok($record, 'Record');
    my $record2 = $alloc->Record( foo => $alloc->Num(10), bar => $alloc->Num(20), baz => $alloc->Str("Foo") );
    isa_ok($record2, 'Record');

    is($record->size, 3, '... got the right size');

    is($record->hash, $record2->hash, '... same thing (hashed)');
    is(refaddr $record, refaddr $record2, '... same thing (refaddr)');
};


done_testing;
