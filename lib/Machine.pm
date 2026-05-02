
use v5.42;
use experimental qw[ class switch ];

class Kontinue {
    use overload '""' => 'to_string';

    method to_string (@) { __CLASS__ }
}

class Kontinue::ERROR :isa(Kontinue) {
    field $error :param :reader;

    method to_string (@) {
        sprintf '%s~>(%s)' => __CLASS__, $error
    }
}

class Kontinue::HALT :isa(Kontinue) {}
class Kontinue::TICK :isa(Kontinue) {
    field $topic  :param :reader;
    field $action :param :reader;
}

class Machine {
    field $queue :reader = +[];

    method enqueue (@work) { unshift @$queue => reverse @work; $self }

    method run (@queue) {
        return $self->enqueue(@queue)->execute;
    }

    method execute {
        while (@$queue) {
            my $work = pop @$queue;;
            given (blessed $work) {
                when ('Kontinue::ERROR') {
                    die $work->to_string;
                }
                when ('Kontinue::HALT') {
                    return $work;
                }
                when ('Kontinue::TICK') {
                    try {
                        $work->action->( $work->topic );
                    } catch ($e) {
                        push @$queue => Kontinue::ERROR->new( error => $e );
                    }
                }
                default {
                    push @$queue => Kontinue::ERROR->new( error => "Unknown Kontinue (${work})" );
                }
            }

        }
    }
}
