
use v5.42;
use experimental qw[ class switch ];

class Opcode {
    use overload '""' => 'to_string';

    method to_string (@) { __CLASS__ }
}

class Opcode::ERROR :isa(Opcode) {
    field $error :param :reader;

    method to_string (@) {
        sprintf '%s~>(%s)' => __CLASS__, $error
    }
}

class Opcode::HALT :isa(Opcode) {}
class Opcode::UNOP :isa(Opcode) {
    field $input  :param :reader;
    field $output :param :reader;
    field $action :param :reader;
}

class Opcode::BINOP :isa(Opcode) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;
    field $action :param :reader;
}

class Machine {
    field $queue :reader = +[];

    method connect_unary ($input, $action, $output) {
        $input->WATCH(sub ($c) {
            state $last;
            return if defined $last && $last eq $c->storage->hash;
            $last = $c->storage->hash;
            # push it ...
            unshift @$queue => Opcode::UNOP->new(
                input  => $c->GET,
                output => $output,
                action => $action
            );
        });
    }

    method connect_binary ($lhs, $rhs, $action, $output) {
        my $_lhs;
        my $_rhs;

        $lhs->WATCH(sub ($c) {
            say "BINOP LHS $c";
            state $last;
            return if defined $last && $last eq $c->storage->hash;
            $last = $c->storage->hash;

            # if we have one already ... see if it is different?
            return if defined $_lhs && $_lhs->hash eq $c->storage->hash;
            # update the _lhs
            $_lhs = $c->GET;
            say "BINOP LHS UPDATE";

            # and defer if we do not have rhs
            return unless defined $_rhs;

            # if we are here, we want to fire ...
            unshift @$queue => Opcode::BINOP->new(
                lhs    => $_lhs,
                rhs    => $_rhs,
                output => $output,
                action => $action
            );

            # and reset the state variables
            ($_lhs, $_rhs) = (undef, undef);
            say "BINOP LHS NQ";
        });

        $rhs->WATCH(sub ($c) {
            say "BINOP RHS $c";

            state $last;
            return if defined $last && $last eq $c->storage->hash;
            $last = $c->storage->hash;

            # if we have one already ... see if it is different?
            return if defined $_rhs && $_rhs->hash eq $c->storage->hash;
            # update the _rhs
            $_rhs = $c->GET;
            say "BINOP RHS UPDATE";

            # and defer if we do not have lhs
            return unless defined $_lhs;

            # if we are here, we want to fire ...
            unshift @$queue => Opcode::BINOP->new(
                lhs    => $_lhs,
                rhs    => $_rhs,
                output => $output,
                action => $action
            );

            # and reset the state variables
            ($_lhs, $_rhs) = (undef, undef);
            say "BINOP RHS NQ";
        });
    }

    method execute {
        while (@$queue) {
            my $work = pop @$queue;
            given (blessed $work) {
                when ('Opcode::ERROR') {
                    die $work->to_string;
                }
                when ('Opcode::HALT') {
                    return $work;
                }
                when ('Opcode::UNOP') {
                    try {
                        $work->output->SET( $work->action->( $work->input ) );
                    } catch ($e) {
                        push @$queue => Opcode::ERROR->new( error => $e );
                    }
                }
                when ('Opcode::BINOP') {
                    try {
                        $work->output->SET( $work->action->( $work->lhs, $work->rhs ) );
                    } catch ($e) {
                        push @$queue => Opcode::ERROR->new( error => $e );
                    }
                }
                default {
                    push @$queue => Opcode::ERROR->new( error => "Unknown Opcode (${work})" );
                }
            }
        }
    }
}
