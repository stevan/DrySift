
use v5.42;
use experimental qw[ class switch ];

class Machine::Opcode {
    use overload '""' => 'to_string';

    method op { __CLASS__ =~ s/^Machine\:\:Opcode\:\://r }

    method to_string (@) { __CLASS__ }
}

class Machine::Opcode::HALT :isa(Machine::Opcode) {
    # ???
}

class Machine::Opcode::ERROR :isa(Machine::Opcode) {
    field $error :param :reader;

    method to_string (@) {
        sprintf '%s~>(%s)' => __CLASS__, $error
    }
}

class Machine::Opcode::UNOP :isa(Machine::Opcode) {
    field $input  :param :reader;
    field $output :param :reader;
    field $action :param :reader;
}

class Machine::Opcode::BINOP :isa(Machine::Opcode) {
    field $lhs    :param :reader;
    field $rhs    :param :reader;
    field $output :param :reader;
    field $action :param :reader;
}

class Machine::Opcode::COND :isa(Machine::Opcode) {
    field $cond     :param :reader;
    field $input    :param :reader;
    field $if_true  :param :reader;
    field $if_false :param :reader;
}
