
use v5.42;
use experimental qw[ class switch ];
use Digest::MD5 ();
use UUID        ();

use Terms;
use Values;

class Allocator {
    field %arena;
    field %heap;

    field $Nil;
    field $True;
    field $False;

    ## -------------------------------------------------------------------------

    method lookup ($hash) { $arena{ $hash } }

    ## -------------------------------------------------------------------------
    ## ... snapshotting and loading

    method snapshot {
        +{
            arena => +[ map $_->to_json_ld, values %arena ],
            heap  => +[ map $_->to_json_ld, values %heap  ],
        }
    }

    sub restore ($class, $snapshot) {
        my @arena = $snapshot->{arena}->@*;
        my %index = map { $_->{'@hash'}, $_ } @arena;
        my $self = $class->new;
        $self->restore_term($_, \%index) foreach @arena;
        return $self;
    }

    method restore_term ($term, $index) {
        given ($term->{'@type'}) {
            when ('Nil')  { $self->Nil }
            when ('Num')  { $self->Num($term->{value}) }
            when ('Str')  { $self->Str($term->{value}) }
            when ('Sym')  { $self->Sym($term->{value}) }
            when ('Bool') {
                $term->{value} eq '#T' ? $self->True : $self->False
            }
            when ('Pair') {
                $self->Pair(
                    $self->lookup( $term->{first}  ) // $self->restore_term( $index->{ $term->{first}  }, $index ),
                    $self->lookup( $term->{second} ) // $self->restore_term( $index->{ $term->{second} }, $index ),
                );
            }
            when ('Cons') {
                $self->Cons(
                    $self->lookup( $term->{head} ) // $self->restore_term( $index->{ $term->{head} }, $index ),
                    $self->lookup( $term->{tail} ) // $self->restore_term( $index->{ $term->{tail} }, $index ),
                );
            }
            when ('Assoc') {
                $self->Assoc(
                    $self->lookup( $term->{head} ) // $self->restore_term( $index->{ $term->{head} }, $index ),
                    $self->lookup( $term->{tail} ) // $self->restore_term( $index->{ $term->{tail} }, $index ),
                );
            }
            when ('Tuple') {
                $self->Tuple(
                    map {
                        $self->lookup( $_ ) // $self->restore_term( $index->{ $_ }, $index ),
                    } $term->{elements}->@*
                );
            }
            when ('Record') {
                $self->Record(
                    map {
                        $_ => $self->lookup( $term->{fields}->{$_} )
                        // $self->restore_term( $index->{ $term->{fields}->{$_} }, $index ),
                    } keys $term->{fields}->%*
                );
            }
        }
    }

    ## -------------------------------------------------------------------------
    ## ... immutable stuff

    method Nil {
        $Nil //= do {
            my $hash = Nil->hash_of('#N');
            $arena{ $hash } = Nil->new(value => '#N', hash => $hash)
        };
    }
    method True {
        $True //= do {
            my $hash = Bool->hash_of('#T');
            $arena{ $hash } = Bool->new(value => '#T', hash => $hash)
        };
    }

    method False {
        $False //= do {
            my $hash = Bool->hash_of('#F');
            $arena{ $hash } = Bool->new(value => '#F', hash => $hash)
        };
    }

    method Num ($value) {
        my $hash = Num->hash_of($value);
        $arena{ $hash } //= Num->new(value => $value, hash => $hash)
    }

    method Str ($value) {
        my $hash = Str->hash_of($value);
        $arena{ $hash } //= Str->new(value => $value, hash => $hash)
    }

    method Sym ($value) {
        my $hash = Sym->hash_of($value);
        $arena{ $hash } //= Sym->new(value => $value, hash => $hash)
    }

    ## -------------------------------------------------------------------------

    method Pair ($first, $second) {
        my $hash = Pair->hash_of($first, $second);
        $arena{ $hash } //= Pair->new(first => $first, second => $second, hash => $hash)
    }

    method Cons ($head, $tail) {
        my $hash = Cons->hash_of($head, $tail);
        $arena{ $hash } //= Cons->new(head => $head, tail => $tail, hash => $hash)
    }

    method Assoc ($head, $tail) {
        my $hash = Assoc->hash_of($head, $tail);
        $arena{ $hash } //= Assoc->new(head => $head, tail => $tail, hash => $hash)
    }

    method Tuple (@elements) {
        my $hash = Tuple->hash_of(@elements);
        $arena{ $hash } //= Tuple->new(elements => \@elements, hash => $hash)
    }

    method Record (%fields) {
        my $hash = Record->hash_of(%fields);
        $arena{ $hash } //= Record->new(fields => \%fields, hash => $hash)
    }

    ## -------------------------------------------------------------------------
    # ... mutable stuff

    method Scalar ($term = $self->Nil) {
        my $uuid = UUID::uuid();
        $heap{ $uuid } = Scalar->new(
            hash    => Scalar->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $term
        )
    }

    method Struct (%fields) {
        my $uuid = UUID::uuid();
        $heap{ $uuid } = Struct->new(
            hash    => Struct->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $self->Record(%fields)
        );
    }

    ## -------------------------------------------------------------------------
    ## ... append only

    method List (@terms) {
        my $list = $self->Nil;
        while (@terms) {
            $list = $self->Cons( shift @terms, $list );
        }
        my $uuid = UUID::uuid();
        $heap{ $uuid } = List->new(
            hash    => List->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $list
        )
    }

    method Map (@pairs) {
        my $assoc = $self->Nil;
        while (@pairs) {
            $assoc = $self->Assoc( shift @pairs, $assoc );
        }
        my $uuid = UUID::uuid();
        $heap{ $uuid } = Map->new(
            hash    => Map->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $assoc
        )
    }

    ## -------------------------------------------------------------------------
    ## ... random access

    method Array (@elements) {
        my $uuid = UUID::uuid();
        $heap{ $uuid } = Array->new(
            hash    => Array->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $self->Tuple(@elements)
        );
    }

    method Hash (%fields) {
        my $uuid = UUID::uuid();
        $heap{ $uuid } = Hash->new(
            hash    => Hash->hash_of($uuid),
            uuid    => $uuid,
            alloc   => $self,
            storage => $self->Record(%fields)
        );
    }

}
