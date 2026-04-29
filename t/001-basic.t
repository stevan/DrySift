#!perl


use v5.42;
use experimental qw[ class ];
use Digest::MD5 ();

class Term {
    use overload '""' => 'to_string';

    field $hash :param :reader;

    sub hash_of ($class, @) { ... }

    method to_string (@) { ... }
}

class Literal :isa(Term) {
    field $value :param :reader;

    sub hash_of ($class, $value) {
        Digest::MD5::md5_hex($class, $value)
    }

    method to_string {
        sprintf '%s[%s]:%s' =>
                __CLASS__, "${value}",
                substr($self->hash, 0, 6)
    }
}

class Nil  :isa(Literal) {}
class Num  :isa(Literal) {}
class Str  :isa(Literal) {}
class Bool :isa(Literal) {}
class Sym  :isa(Literal) {}

class Ref :isa(Term) {
    field $term :param :reader;

    sub hash_of ($class, $term) {
        Digest::MD5::md5_hex($class, $term->hash)
    }

    method to_string {
        sprintf '%s<%s>:%s' =>
                __CLASS__,
                substr($term->hash, 0, 6),
                substr($self->hash, 0, 6)
    }
}

class Pair :isa(Term) {
    field $first  :param :reader;
    field $second :param :reader;

    sub hash_of ($class, $first, $second) {
        Digest::MD5::md5_hex($class, $first->hash, $second->hash)
    }

    method to_string {
        sprintf '( %s . %s ):%s' =>
                "${first}", "${second}",
                substr($self->hash, 0, 6)
    }
}

class Tuple :isa(Term) {
    field $elements :param :reader;

    sub hash_of ($class, @elements) {
        Digest::MD5::md5_hex($class, map $_->hash, @elements)
    }

    method to_string {
        sprintf '[ %s ]:%s' =>
                (join ', ' => map "${_}", @$elements),
                substr($self->hash, 0, 6)
    }
}

class Allocator {
    field %allocated;

    field $Nil;
    field $True;
    field $False;

    method lookup ($hash) { $allocated{ $hash } }

    method Nil {
        $Nil //= do {
            my $hash = Nil->hash_of('#N');
            $allocated{ $hash } = Nil->new(value => '#N', hash => $hash)
        };
    }
    method True {
        $True //= do {
            my $hash = Bool->hash_of('#T');
            $allocated{ $hash } = Bool->new(value => '#T', hash => $hash)
        };
    }

    method False {
        $False //= do {
            my $hash = Bool->hash_of('#F');
            $allocated{ $hash } = Bool->new(value => '#F', hash => $hash)
        };
    }

    method Num ($value) {
        my $hash = Num->hash_of($value);
        $allocated{ $hash } //= Num->new(value => $value, hash => $hash)
    }

    method Str ($value) {
        my $hash = Str->hash_of($value);
        $allocated{ $hash } //= Str->new(value => $value, hash => $hash)
    }

    method Sym ($value) {
        my $hash = Sym->hash_of($value);
        $allocated{ $hash } //= Sym->new(value => $value, hash => $hash)
    }

    method Ref ($term) {
        my $hash = Ref->hash_of($term);
        $allocated{ $hash } //= Ref->new(term => $term, hash => $hash)
    }

    method Pair ($first, $second) {
        my $hash = Pair->hash_of($first, $second);
        $allocated{ $hash } //= Pair->new(first => $first, second => $second, hash => $hash)
    }

    method Tuple (@elements) {
        my $hash = Tuple->hash_of(@elements);
        $allocated{ $hash } //= Tuple->new(elements => \@elements, hash => $hash)
    }
}

class Scalar {
    field $alloc :param :reader;

    field $storage :reader;
    field @history :reader;

    ADJUST {
        $storage = $alloc->Nil;
    }

    method generation { scalar @history }

    method get { $storage }

    method set ($value) {
        unshift @history => $storage->hash;
        $storage = $value;
        return;
    }

    method DEBUG {
        say 'SCALAR:';
        say "    ",$storage->to_string;
        say '  history:';
        say "    - ", join "\n    - " => map $alloc->lookup($_), @history;
    }
}

class Array {
    field $alloc :param :reader;

    field $storage :reader;
    field @history :reader;

    ADJUST {
        $storage = $alloc->Tuple();
    }

    method generation { scalar @history }

    method push ($term) {
        unshift @history => $storage->hash;
        $storage = $alloc->Tuple( $storage->elements->@*, $term );
        return;
    }

    method pop {
        unshift @history => $storage->hash;
        my @elements = $storage->elements->@*;
        my $popped   = pop @elements;
        $storage = $alloc->Tuple( @elements );
        return $popped;
    }

    method DEBUG {
        say 'ARRAY:';
        say "    ",$storage->to_string;
        say '  history:';
        say "    - ", join "\n    - " => map $alloc->lookup($_), @history;
    }
}


my $alloc = Allocator->new;

my $scalar = Scalar->new( alloc => $alloc );

$scalar->set( $alloc->Num(10) );
$scalar->DEBUG;

$scalar->set( $alloc->Num(20) );
$scalar->DEBUG;

$scalar->set( $alloc->Num(30) );
$scalar->DEBUG;

__END__

my $array = Array->new( alloc => $alloc );
$array->push( $alloc->Num(10) );
$array->push( $alloc->Num(20) );
$array->push( $alloc->Num(30) );
$array->DEBUG;
say "POP! ", $array->pop;
$array->DEBUG;

__END__


say join "\n" => (
    $alloc->Num(10),
    $alloc->Num(20),
    $alloc->Str('Foo'),
    $alloc->True,
    $alloc->False,
    $alloc->Nil,
    $alloc->Pair($alloc->Num(30), $alloc->Nil),
    $alloc->Ref($alloc->Num(30)),
    $alloc->Pair(
        $alloc->Sym('$foo'),
        $alloc->Pair(
            $alloc->Num(20),
            $alloc->Pair(
                $alloc->Num(30),
                $alloc->Nil
            )
        )
    ),
    $alloc->Tuple(
        $alloc->Str("one"),
        $alloc->Num(1),
        $alloc->True,
        $alloc->Pair($alloc->Ref($alloc->Num(30)), $alloc->Nil),
    ),
);





