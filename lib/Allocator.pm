
use v5.42;
use experimental qw[ class ];
use Digest::MD5 ();

use Terms;
use Values;

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

    method Pair ($first, $second) {
        my $hash = Pair->hash_of($first, $second);
        $allocated{ $hash } //= Pair->new(first => $first, second => $second, hash => $hash)
    }

    method Cons ($head, $tail) {
        my $hash = Cons->hash_of($head, $tail);
        $allocated{ $hash } //= Cons->new(head => $head, tail => $tail, hash => $hash)
    }

    method Assoc ($head, $tail) {
        my $hash = Assoc->hash_of($head, $tail);
        $allocated{ $hash } //= Assoc->new(head => $head, tail => $tail, hash => $hash)
    }

    method Tuple (@elements) {
        my $hash = Tuple->hash_of(@elements);
        $allocated{ $hash } //= Tuple->new(elements => \@elements, hash => $hash)
    }

    method Record (%fields) {
        my $hash = Record->hash_of(%fields);
        $allocated{ $hash } //= Record->new(fields => \%fields, hash => $hash)
    }

    # ... mutable stuff

    method Scalar ($term = $self->Nil) {
        return Scalar->new( alloc => $self, storage => $term )
    }

    method Struct (%fields) {
        return Struct->new( alloc => $self, storage => $self->Record(%fields) );
    }

    method List (@terms) {
        my $list = $self->Nil;
        while (@terms) {
            $list = $self->Cons( shift @terms, $list );
        }
        return List->new( alloc => $self, storage => $list )
    }

    method Map (@pairs) {
        my $assoc = $self->Nil;
        while (@pairs) {
            $assoc = $self->Assoc( shift @pairs, $assoc );
        }
        return Map->new( alloc => $self, storage => $assoc )
    }

    method Array (@elements) {
        return Array->new( alloc => $self, storage => $self->Tuple(@elements) );
    }

    method Hash (%fields) {
        return Hash->new( alloc => $self, storage => $self->Record(%fields) );
    }

}
