
use v5.42;
use experimental qw[ class switch ];

use Machine::Opcodes;

## -----------------------------------------------------------------------------
## Propagators
## -----------------------------------------------------------------------------

class UnaryPropagator {
    field $input   :param :reader;
    field $output  :param :reader;
    field $action  :param :reader;
    field $watcher :param :reader = undef;

    ADJUST {
        $watcher = UnaryWatcher->new( cell => $input );
    }

    method connect ($m) {
        $watcher->watch( $m, $self );
    }

    method execute ($machine, $cell) {
        $machine->enqueue(
            Machine::Opcode::UNOP->new(
                input  => $cell,
                output => $output,
                action => $action
            )
        )
    }
}

class BinaryPropagator {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;
    field $action :param :reader;
    field $watcher :param :reader = undef;

    ADJUST {
        $watcher = BinaryWatcher->new( lhs => $lhs, rhs => $rhs );
    }

    method connect ($m) {
        $watcher->watch( $m, $self );
    }

    method execute ($machine, $n, $m) {
        $machine->enqueue(
            Machine::Opcode::BINOP->new(
                lhs    => $n,
                rhs    => $m,
                output => $output,
                action => $action
            )
        )
    }
}

class SwitchPropagator {
    field $control  :param :reader;
    field $input    :param :reader;
    field $if_true  :param :reader;
    field $if_false :param :reader;
    field $watcher  :param :reader = undef;

    ADJUST {
        $watcher = BinaryWatcher->new( lhs => $control, rhs => $input );
    }

    method connect ($m) {
        $watcher->watch( $m, $self );
    }

    method execute ($machine, $c, $i) {
        $machine->enqueue(
            Machine::Opcode::COND->new(
                cond     => $c,
                input    => $i,
                if_true  => $if_true,
                if_false => $if_false
            )
        )
    }
}

## -----------------------------------------------------------------------------
## watchers
## -----------------------------------------------------------------------------

class UnaryWatcher {
    field $cell :param :reader;

    method watch ($machine, $propagator) {
        if ($cell isa Term) {
            $propagator->execute( $machine, $cell );
        } else {
            $cell->WATCH( sub ($c) { $propagator->execute( $machine, $c->GET ) } );
        }
    }
}

class BinaryWatcher {
    field $lhs :param :reader;
    field $rhs :param :reader;

    field $seen_lhs;
    field $seen_rhs;

    ADJUST {
        $seen_lhs = $lhs if $lhs isa Term;
        $seen_rhs = $rhs if $rhs isa Term;
    }

    method watch ($machine, $propagator) {
        if (defined $seen_lhs && defined $seen_rhs) {
            $propagator->execute( $machine, $seen_lhs, $seen_rhs );
        }
        else {
            if ($lhs isa Cell) {
                $lhs->WATCH(sub ($c) {
                    $seen_lhs = $c->GET;
                    $propagator->execute( $machine, $seen_lhs, $seen_rhs )
                        if defined $seen_rhs;
                });
            }

            if ($rhs isa Cell) {
                $rhs->WATCH(sub ($c) {
                    $seen_rhs = $c->GET;
                    $propagator->execute( $machine, $seen_lhs, $seen_rhs )
                        if defined $seen_lhs;
                });
            }
        }
    }
}
