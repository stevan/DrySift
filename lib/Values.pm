
use v5.42;
use experimental qw[ class ];

class Cell :isa(Term) {
    field $uuid    :param :reader;
    field $alloc   :param :reader;
    field $storage :param;

    field @history  :reader(HISTORY);
    field @watchers :reader(WATCHERS);

    method WATCH ($f) { push @watchers => $f }

    method NOTIFY { $_->($self) foreach @watchers }

    method GET { $storage }
    method SET ($value) {
        unshift @history => $storage->hash if defined $storage;
        $storage = $value;
        $self->NOTIFY;
        return;
    }

    method GENERATION { scalar @history }

    method DEBUG {
        say __CLASS__," => ",$storage->to_string;
        say '# history:';
        say "#   - ", join "\n#   - " => map $alloc->lookup($_), @history;
    }

    sub hash_of ($class, $uuid) {
        Digest::MD5::md5_hex($class, $uuid)
    }

    method to_string (@) { sprintf '%s:%s -> %s' => __CLASS__, substr($self->hash, 0, 6), $storage->to_string }
}

## Single Value

class Scalar :isa(Cell) {
    method get { $self->GET }
    method set ($value) {
        $self->SET($value);
        return $value;
    }

    method is_nil { $self->GET->is_nil }
}

class Struct :isa(Cell) {
    method get ($name) {
        die "INVALID FIELD: ${name} is not a value field name"
            unless exists $self->GET->fields->{$name};
        return $self->GET->get($name);
    }

    method set ($name, $value) {
        die "INVALID FIELD: ${name} is not a value field name"
            unless exists $self->GET->fields->{$name};
        my %fields = $self->GET->fields->%*;
        $fields{ $name } = $value;
        $self->SET( $self->alloc->Record( %fields ) );
        return;
    }
}

## Append Only

class List :isa(Cell) {
    method head { $self->GET->head }
    method tail { $self->GET->tail }

    method append ($term) {
        $self->SET( $self->alloc->Cons( $term, $self->GET ))
    }
}

class Map :isa(Cell) {
    method get ($key) {
        return if $self->GET->is_nil;
        $key = $self->alloc->Sym($key) unless blessed $key;
        return $self->GET->lookup( $key );
    }

    method set ($key, $term) {
        $key = $self->alloc->Sym($key) unless blessed $key;
        $self->SET(
            $self->alloc->Assoc(
                $self->alloc->Pair($key, $term),
                $self->GET,
            )
        )
    }
}

## Random Access

class Array :isa(Cell) {
    method length { $self->GET->length }

    method at ($index) {
        die "OUT-OF-BOUNDS: ${index} is out of bounds" if $index > ($self->GET->length - 1);
        $self->GET->elements->[ $index ]
    }

    method set ($index, $value) {
        die "OUT-OF-BOUNDS: ${index} is out of bounds" if $index > ($self->GET->length - 1);
        my @elements = $self->GET->elements->@*;
        $elements[ $index ] = $value;
        $self->SET( $self->alloc->Tuple( @elements ) );
        return;
    }

    method unshift ($term) {
        $self->SET( $self->alloc->Tuple( $term, $self->GET->elements->@* ) );
        return;
    }

    method push ($term) {
        $self->SET( $self->alloc->Tuple( $self->GET->elements->@*, $term ) );
        return;
    }

    method shift {
        my @elements = $self->GET->elements->@*;
        my $shifted  = shift @elements;
        $self->SET( $self->alloc->Tuple( @elements ) );
        return $shifted;
    }

    method pop {
        my @elements = $self->GET->elements->@*;
        my $popped   = pop @elements;
        $self->SET( $self->alloc->Tuple( @elements ) );
        return $popped;
    }
}

class Hash :isa(Cell) {
    method has ($key) {
        exists $self->GET->fields->{ $key }
    }

    method get ($key) {
        die "UNKNOWN-KEY: ${key} is not found"
            unless exists $self->GET->fields->{ $key };
        $self->GET->fields->{ $key };
    }

    method set ($key, $value) {
        my %fields = $self->GET->fields->%*;
        $fields{ $key } = $value;
        $self->SET( $self->alloc->Record( %fields ) );
        return;
    }

    method delete ($key) {
        my %fields = $self->GET->fields->%*;
        die "UNKNOWN-KEY: ${key} is not found"
            unless exists $fields{ $key };
        my $deleted = delete $fields{ $key };
        $self->SET( $self->alloc->Record( %fields ) );
        return $deleted;
    }

    method keys   { $self->GET->keys }
    method values { $self->GET->values }
}

