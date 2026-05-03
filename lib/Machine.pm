
use v5.42;
use experimental qw[ class switch ];

use Propagators;
use Machine::Opcodes;

class Machine {
    field $queue :reader = +[];

    method connect (@propagators) {
        $_->connect($self) foreach @propagators
    }

    method enqueue ($work) { unshift @$queue => $work }

    method execute ($max_iterations = 100) {
        while ($max_iterations-- > 0 && @$queue) {
            my $work = pop @$queue;
            given ($work->op) {
                when ('ERROR') {
                    die $work->to_string;
                }
                when ('HALT') {
                    return $work;
                }
                when ('UNOP') {
                    try {
                        $work->output->SET( $work->action->( $work->input ) );
                    } catch ($e) {
                        push @$queue => Machine::Opcode::ERROR->new( error => $e );
                    }
                }
                when ('BINOP') {
                    try {
                        $work->output->SET( $work->action->( $work->lhs, $work->rhs ) );
                    } catch ($e) {
                        push @$queue => Machine::Opcode::ERROR->new( error => $e );
                    }
                }
                when ('COND') {
                    my $cond = $work->cond;
                    if ($cond isa Bool && $cond->is_true) {
                        $work->if_true->SET( $work->input );
                    } else {
                        $work->if_false->SET( $work->input );
                    }
                }
                default {
                    push @$queue => Machine::Opcode::ERROR->new( error => "Unknown Opcode (${work})" );
                }
            }
        }
    }
}
