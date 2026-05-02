
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
    method deref  ($uuid) {  $heap{ $uuid } }

    ## -------------------------------------------------------------------------
    ## ... snapshotting and loading

    method snapshot {
        my @arena = map $_->to_json_ld, values %arena;
        my @heap  = map $_->to_json_ld, values %heap;
        +{
            '@type' => __CLASS__,
            '@hash' => Digest::MD5::md5_hex(__CLASS__, (map $_->{'@hash'}, @arena), (map $_->{'@uuid'}, @heap)),
            arena   => \@arena,
            heap    => \@heap,
        }
    }

    sub restore ($class, $snapshot) {
        my @arena = $snapshot->{arena}->@*;
        my @heap  = $snapshot->{heap}->@*;

        my %arena_index = map { $_->{'@hash'}, $_ } @arena;
        my %heap_index  = map { $_->{'@uuid'}, $_ } @heap;

        my $self = $class->new;
        $self->restore_terms($_, \%arena_index, \%heap_index) foreach @arena;
        return $self;
    }

    method restore_cells ($uuid, $arena_index, $heap_index) {
        my $cell = $heap_index->{ $uuid }
                // die "Unable to find cell(${uuid}) in the heap";

        my $term = $arena_index->{ $cell->{storage} }
                // die "Unable to find term(".$cell->{storage}.") in arena";

        my $storage = $self->restore_terms($term, $arena_index, $heap_index);

        given ($cell->{'@type'}) {
            when ('Scalar') { $heap{ $uuid } = Scalar ->new(alloc => $self, uuid => $uuid, storage => $storage) }
            when ('Struct') { $heap{ $uuid } = Struct ->new(alloc => $self, uuid => $uuid, storage => $storage) }
            when ('List')   { $heap{ $uuid } = List   ->new(alloc => $self, uuid => $uuid, storage => $storage) }
            when ('Map')    { $heap{ $uuid } = Map    ->new(alloc => $self, uuid => $uuid, storage => $storage) }
            when ('Array')  { $heap{ $uuid } = Array  ->new(alloc => $self, uuid => $uuid, storage => $storage) }
            when ('Hash')   { $heap{ $uuid } = Hash   ->new(alloc => $self, uuid => $uuid, storage => $storage) }
        }
    }

    method restore_terms ($term, $arena_index, $heap_index) {
        given ($term->{'@type'}) {
            when ('Nil')  { $self->Nil }
            when ('Num')  { $self->Num($term->{value}) }
            when ('Str')  { $self->Str($term->{value}) }
            when ('Sym')  { $self->Sym($term->{value}) }
            when ('Bool') {
                $term->{value} eq '#T' ? $self->True : $self->False
            }
            when ('Ref') {
                $self->Ref( $self->restore_cells( $term->{uuid}, $arena_index, $heap_index ) );
            }
            when ('Pair') {
                $self->Pair(
                    $self->lookup( $term->{first}  )
                        // $self->restore_terms( $arena_index->{ $term->{first}  }, $arena_index, $heap_index ),
                    $self->lookup( $term->{second} )
                        // $self->restore_terms( $arena_index->{ $term->{second} }, $arena_index, $heap_index ),
                );
            }
            when ('Cons') {
                $self->Cons(
                    $self->lookup( $term->{head} )
                        // $self->restore_terms( $arena_index->{ $term->{head} }, $arena_index, $heap_index ),
                    $self->lookup( $term->{tail} )
                        // $self->restore_terms( $arena_index->{ $term->{tail} }, $arena_index, $heap_index ),
                );
            }
            when ('Assoc') {
                $self->Assoc(
                    $self->lookup( $term->{head} )
                        // $self->restore_terms( $arena_index->{ $term->{head} }, $arena_index, $heap_index ),
                    $self->lookup( $term->{tail} )
                        // $self->restore_terms( $arena_index->{ $term->{tail} }, $arena_index, $heap_index ),
                );
            }
            when ('Tuple') {
                $self->Tuple(
                    map {
                        $self->lookup( $_ )
                            // $self->restore_terms( $arena_index->{ $_ }, $arena_index, $heap_index ),
                    } $term->{elements}->@*
                );
            }
            when ('Record') {
                $self->Record(
                    map {
                        $_ => $self->lookup( $term->{fields}->{$_} )
                        // $self->restore_terms( $arena_index->{ $term->{fields}->{$_} }, $arena_index, $heap_index ),
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

    method Ref ($cell) {
        my $hash = Ref->hash_of($cell);
        $arena{ $hash } //= Ref->new(cell => $cell, hash => $hash)
    }

    ## -------------------------------------------------------------------------
    # ... mutable stuff

    method Scalar ($term = $self->Nil) {
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = Scalar->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $term
        ))
    }

    method Struct (@args) {
        my $storage;
        if (scalar @args == 1 && blessed $args[0]) {
            $storage = $args[0];
        } else {
            $storage = $self->Record(@args);
        }
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = Struct->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $storage
        ))
    }

    ## -------------------------------------------------------------------------
    ## ... append only

    method List (@args) {
        my $storage;
        if (scalar @args == 1 && blessed $args[0]) {
            $storage = $args[0];
        } else {
            my $storage = $self->Nil;
            while (@args) {
                $storage = $self->Cons( shift @args, $storage );
            }
        }
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = List->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $storage
        ))
    }

    method Map (@args) {
        my $storage;
        if (scalar @args == 1 && blessed $args[0]) {
            $storage = $args[0];
        } else {
            my $storage = $self->Nil;
            while (@args) {
                $storage = $self->Assoc( shift @args, $storage );
            }
        }
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = Map->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $storage
        ))
    }

    ## -------------------------------------------------------------------------
    ## ... random access

    method Array (@args) {
        my $storage;
        if (scalar @args == 1 && blessed $args[0]) {
            $storage = $args[0];
        } else {
            $storage = $self->Tuple(@args);
        }
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = Array->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $storage
        ))
    }

    method Hash (@args) {
        my $storage;
        if (scalar @args == 1 && blessed $args[0]) {
            $storage = $args[0];
        } else {
            $storage = $self->Record(@args);
        }
        my $uuid = UUID::uuid();
        return $self->Ref( $heap{ $uuid } = Hash->new(
            uuid    => $uuid,
            alloc   => $self,
            storage => $storage
        ))
    }

}
