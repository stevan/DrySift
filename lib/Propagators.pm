
use v5.42;
use experimental qw[ class switch ];

use Machine::Opcodes;

class Propagator {}

class UnaryPropagator :isa(Propagator) {
    field $input  :param :reader;
    field $output :param :reader;
    field $action :param :reader;

    field $_in;

    ADJUST {
        $_in = $input if $input isa Term;
    }

    method _reset_state {
        $_in = undef if $input isa Cell;
    }

    method _trigger_action ($m) {
        $m->enqueue(
            Machine::Opcode::UNOP->new(
                input  => $_in,
                output => $output,
                action => $action
            )
        );
        $self->_reset_state;
    }

    method _is_new_value ($p, $c) {
        defined $p && $p->hash eq $c->storage->hash;
    }

    method connect ($m) {
        if ($input isa Term) {
            $self->_trigger_action($m);
        } else {
            $input->WATCH(sub ($c) {
                return if $self->_is_new_value( $_in, $c );
                $_in = $c->GET;
                $self->_trigger_action( $m );
            });
        }
    }
}

class BinaryPropagator :isa(Propagator) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;
    field $action :param :reader;

    field $_lhs;
    field $_rhs;

    ADJUST {
        $_lhs = $lhs if $lhs isa Term;
        $_rhs = $rhs if $rhs isa Term;
    }

    method _reset_state {
        $_lhs = undef if $lhs isa Cell;
        $_rhs = undef if $rhs isa Cell;
    }

    method _trigger_action ($m) {
        $m->enqueue(
            Machine::Opcode::BINOP->new(
                lhs    => $_lhs,
                rhs    => $_rhs,
                output => $output,
                action => $action
            )
        );
        $self->_reset_state;
    }

    method _is_new_value ($p, $c) {
        defined $p && $p->hash eq $c->storage->hash;
    }

    method connect ($m) {
        if ($lhs isa Term && $rhs isa Term) {
            $self->_trigger_action( $m );
        }
        else {
            $lhs->WATCH(sub ($c) {
                return if $self->_is_new_value( $_lhs, $c );
                $_lhs = $c->GET;
                $self->_trigger_action( $m ) if defined $_rhs;
            }) if $lhs isa Cell;

            $rhs->WATCH(sub ($c) {
                return if $self->_is_new_value( $_rhs, $c );
                $_rhs = $c->GET;
                $self->_trigger_action( $m ) if defined $_lhs;
            }) if $rhs isa Cell;
        }
    }
}
