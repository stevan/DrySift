
use v5.42;
use experimental qw[ class switch ];

class Propagator {
    field $action :param :reader;

    method fire (@args) { $action->(@args) }

    method connect { ... }
}

class UnaryPropagator :isa(Propagator) {
    field $input  :param :reader;
    field $output :param :reader;

    method connect {
        $input->deref->WATCH(sub ($cell) {
            my $term = $cell->GET;
            $output->deref->SET( $self->fire( $term ) );
        });
    }
}

class BinaryPropagator :isa(Propagator) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;

    method connect {
        $lhs->deref->WATCH(sub ($lhs_cell) {
            my $rhs_cell = $rhs->deref;
            $output->deref->SET( $self->fire( $lhs_cell->GET, $rhs_cell->GET ) );
        });

        $rhs->deref->WATCH(sub ($rhs_cell) {
            my $lhs_cell = $lhs->deref;
            $output->deref->SET( $self->fire( $lhs_cell->GET, $rhs_cell->GET ) );
        });
    }
}
