
use v5.42;
use experimental qw[ class switch ];

use Machine::Opcodes;

class Propagator {}

class UnaryPropagator :isa(Propagator) {
    field $input  :param :reader;
    field $output :param :reader;
    field $action :param :reader;

    field $_in;

    method _reset_state {
        ($_in) = (undef);
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
        $input->WATCH(sub ($c) {
            return if $self->_is_new_value( $_in, $c );
            $_in = $c->GET;
            $self->_trigger_action( $m );
        });
    }
}

class BinaryPropagator :isa(Propagator) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;
    field $action :param :reader;

    field $_lhs;
    field $_rhs;

    method _reset_state {
        ($_lhs, $_rhs) = (undef, undef);
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
        $lhs->WATCH(sub ($c) {
            return if $self->_is_new_value( $_lhs, $c );
            $_lhs = $c->GET;
            $self->_trigger_action( $m ) if defined $_rhs;
        });

        $rhs->WATCH(sub ($c) {
            return if $self->_is_new_value( $_rhs, $c );
            $_rhs = $c->GET;
            $self->_trigger_action( $m ) if defined $_lhs;
        });
    }
}
