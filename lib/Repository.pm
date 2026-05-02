
use v5.42;
use experimental qw[ class switch ];
use Digest::MD5 ();

use Terms;
use Values;
use Allocator;
use Machine;

class Repository {
    field $alloc   :reader :param(restore_alloc)   = undef;
    field $machine :reader :param(restore_machine) = undef;
    field $head    :reader :param(restore_head)    = undef;

    ADJUST {
        $alloc   //= Allocator->new;
        $machine //= Machine->new;
        $head    //= +{};
    }

    method bind ($name, $value) {
        $head->{$name} = $value->hash;
        return $value;
    }

    method resolve ($name) {
        return undef unless exists $head->{$name};
        return $alloc->lookup( $head->{$name} );
    }

    method snapshot {
        my $snapshot = $alloc->snapshot;
        +{
            head     => +{ $head->%* },
            snapshot => $snapshot,
            '@type'  => __CLASS__,
            '@hash'  => Digest::MD5::md5_hex(
                __CLASS__,
                (join ':' => 'HEAD', map { $_, $head->{$_} } sort { $a cmp $b } keys %$head),
                $snapshot->{'@hash'},
            )
        }
    }

    sub restore ($class, $snapshot) {
        # TODO: integrity checks ...
        return $class->new(
            restore_alloc => Allocator->restore( $snapshot->{snapshot} ),
            restore_head  => $snapshot->{head}
        )
    }
}
