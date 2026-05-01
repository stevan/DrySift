#!perl

use v5.42;
use Test::More;

use Allocator;

my $alloc = Allocator->new;
isa_ok($alloc, 'Allocator');

subtest '... Num' => sub {
    my $num = $alloc->Num(10);
    isa_ok($num, 'Num');
    is($num->value, 10, '... expected value');

    my $num2 = $alloc->Num(10);
    is($num->hash, $num2->hash, '... same thing (hashed)');
    is(refaddr $num, refaddr $num2, '... same thing (refaddr)');
};

subtest '... Str' => sub {
    my $str = $alloc->Str("FOO");
    isa_ok($str, 'Str');
    is($str->value, "FOO", '... expected value');

    my $str2 = $alloc->Str("FOO");
    is($str->hash, $str2->hash, '... same thing (hashed)');
    is(refaddr $str, refaddr $str2, '... same thing (refaddr)');
};

subtest '... Bool/True' => sub {
    my $bool = $alloc->True;
    isa_ok($bool, 'Bool');
    my $bool2 = $alloc->True;
    is($bool->hash, $bool2->hash, '... same thing (hashed)');
    is(refaddr $bool, refaddr $bool2, '... same thing (refaddr)');
};

subtest '... Bool/False' => sub {
    my $bool = $alloc->False;
    isa_ok($bool, 'Bool');
    my $bool2 = $alloc->False;
    is($bool->hash, $bool2->hash, '... same thing (hashed)');
    is(refaddr $bool, refaddr $bool2, '... same thing (refaddr)');
};

subtest '... Nil' => sub {
    my $nil = $alloc->Nil;
    isa_ok($nil, 'Bool');
    my $nil2 = $alloc->Nil;
    is($nil->hash, $nil2->hash, '... same thing (hashed)');
    is(refaddr $nil, refaddr $nil2, '... same thing (refaddr)');
};

subtest '... Sym' => sub {
    my $sym = $alloc->Sym("FOO");
    isa_ok($sym, 'Sym');
    is($sym->value, "FOO", '... expected value');

    my $sym2 = $alloc->Sym("FOO");
    is($sym->hash, $sym2->hash, '... same thing (hashed)');
    is(refaddr $sym, refaddr $sym2, '... same thing (refaddr)');
};

done_testing;
