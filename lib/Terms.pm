
use v5.42;
use experimental qw[ class ];
use Digest::MD5 ();

class Term {
    use overload '""' => 'to_string';

    field $hash :param :reader;

    sub hash_of ($class, @) { ... }

    method is_nil { false }

    method to_string (@) { ... }

    method to_json_ld { ... }
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

    method to_json_ld {
        +{
            '@type' => __CLASS__,
            '@hash' => $self->hash,
            'value' => $value
        }
    }
}

class Nil  :isa(Literal) { method is_nil { true } }
class Num  :isa(Literal) {}
class Str  :isa(Literal) {}
class Bool :isa(Literal) {}
class Sym  :isa(Literal) {}

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

    method to_json_ld {
        +{
            '@type'  => __CLASS__,
            '@hash'  => $self->hash,
            'first'  => $first->hash,
            'second' => $second->hash,
        }
    }
}

class Cons :isa(Term) {
    field $head :param :reader;
    field $tail :param :reader;

    sub hash_of ($class, $head, $tail) {
        Digest::MD5::md5_hex($class, $head->hash, $tail->hash)
    }

    method to_string {
        sprintf '( %s %s ):%s' =>
                "${head}", "${tail}",
                substr($self->hash, 0, 6)
    }

    method to_json_ld {
        +{
            '@type' => __CLASS__,
            '@hash' => $self->hash,
            'head'  => $head->hash,
            'tail'  => $tail->hash,
        }
    }
}

class Assoc :isa(Cons) {
    method lookup ($key) {
        return $self->head->second if $key->hash eq $self->head->first->hash;
        return undef               if $self->tail->is_nil;
        return $self->tail->lookup($key);
    }
}

class Tuple :isa(Term) {
    field $elements :param :reader;

    method length { scalar @$elements }

    method at ($index) { $elements->[ $index ] }

    sub hash_of ($class, @elements) {
        Digest::MD5::md5_hex($class, map $_->hash, @elements)
    }

    method to_string {
        sprintf '[ %s ]:%s' =>
                (join ', ' => map "${_}", @$elements),
                substr($self->hash, 0, 6)
    }

    method to_json_ld {
        +{
            '@type'    => __CLASS__,
            '@hash'    => $self->hash,
            'elements' => [ map $_->hash, @$elements ]
        }
    }
}

class Record :isa(Term) {
    field $fields :param :reader;

    sub hash_of ($class, %fields) {
        Digest::MD5::md5_hex(
            $class, map {
                $_, $fields{$_}->hash
            } sort {
                $a cmp $b
            } keys %fields
        )
    }

    method size { scalar keys %$fields }

    method get ($key) { $fields->{$key} }

    method keys   { sort { $a cmp $b } keys %$fields }
    method values { map $fields->{$_}, sort { $a cmp $b } keys %$fields }

    method to_string {
        sprintf '{ %s }:%s' =>
                (join ', ' => map {
                    sprintf '%s: %s' => $_, $fields->{$_}->to_string
                } $self->keys),
                substr($self->hash, 0, 6)
    }

    method to_json_ld {
        +{
            '@type'  => __CLASS__,
            '@hash'  => $self->hash,
            'fields' => +{ map { $_ => $_->hash } $self->keys }
        }
    }
}
