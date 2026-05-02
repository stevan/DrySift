
use v5.42;
use experimental qw[ class switch ];

class Propagator {
    field $action :param :reader;
    method fire (@args) { $action->(@args) }
}

class UnaryPropagator :isa(Propagator) {
    field $input  :param :reader;
    field $output :param :reader;

    method connect ($machine) {
        $input->deref->WATCH(sub ($cell) {
            $machine->enqueue(
                Kontinue::TICK->new(
                    topic  => [ $cell ],
                    action => sub ($n) {
                        $output->deref->SET( $self->fire( $n->GET ) );
                    }
                )
            )
        })
    }
}

class BinaryPropagator :isa(Propagator) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;

    method connect ($machine) {
        $lhs->deref->WATCH(sub ($lhs_cell) {
            my $rhs_cell = $rhs->deref;
            $machine->enqueue(
                Kontinue::TICK->new(
                    topic  => [ $lhs_cell, $rhs_cell ],
                    action => sub ($n, $m) {
                        $output->deref->SET( $self->fire( $n->GET, $m->GET ) );
                    }
                )
            )
        });

        $rhs->deref->WATCH(sub ($rhs_cell) {
            my $lhs_cell = $lhs->deref;
            $machine->enqueue(
                Kontinue::TICK->new(
                    topic  => [ $lhs_cell, $rhs_cell ],
                    action => sub ($n, $m) {
                        $output->deref->SET( $self->fire( $n->GET, $m->GET ) );
                    }
                )
            )
        });
    }
}
