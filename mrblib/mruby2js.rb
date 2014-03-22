class M2JTranslator
  def initialize
    @cur_block_no = 0
    @block_table = {}
    @rite_vm = RiteVM.new
  end

  def dispatch_inst(irep, ins, klass)
    case ins[0]
    when :NOP
      ""
    when :MOVE
      "r#{ins[1]} = r#{ins[2]}\n"

    when :LOADL
      "r#{ins[1]} = #{irep.pool[ins[2]]}\n"

    when :LOADI
      "r#{ins[1]} = #{ins[2]}\n"

    when :LOADSYM
      "r#{ins[1]} = #{irep.syms[ins[2]]}\n"

    when :LOADSELF
      "r#{ins[1]} = r0\n"

    when :LOADT
      "r#{ins[1]} = true\n"

    when :ADD
      "r#{ins[1]} = r#{ins[1]} + r#{ins[1] + 1}\n"

    when :SUB
      "r#{ins[1]} = r#{ins[1]} - r#{ins[1] + 1}\n"

    when :MUL
      "r#{ins[1]} = r#{ins[1]} * r#{ins[1] + 1}\n"

    when :DIV
      "r#{ins[1]} = r#{ins[1]} / r#{ins[1] + 1}\n"

    when :EQ
      "r#{ins[1]} = (r#{ins[1]} == r#{ins[1] + 1})\n"

    when :RETURN
      "return r#{ins[1]}\n"

    when :ADDI
      "r#{ins[1]} = r#{ins[1]} + #{ins[2]}\n"

    when :SUBI
      "r#{ins[1]} = r#{ins[1]} - #{ins[2]}\n"

    when :JMP
      "status = #{ins[2]}\n" +
      "break\n"

    when :JMPIF
      "if (r#{ins[1]}) {\n" +
      "status = #{ins[2]}\n" +
      "break\n" +
      "}\n"

    when :JMPNOT
      "if (!r#{ins[1]}) {\n" +
      "status = #{ins[2]}\n" +
      "break\n" +
      "}\n"

    when :ENTER
      ""

    when :SEND
      target = Irep::get_irep(klass, ins[2]).id
      if @block_table[target] == nil then
        @cur_block_no += 1
        @block_table[target] = @cur_block_no
      end

      "r#{ins[1]} = f_#{@block_table[target]}()\n"

    else
      printf("Unkown code %s \n", Irep::OPTABLE_SYM[get_opcode(cop)])
      ""
    end
  end

  def translate(irep)
    if @block_table[irep.id] then
      return @block_table[irep.id]
    end

    @cur_block_no += 1
    @block_table[irep.id] = @cur_block_no
    output = ""
    # gnerate
    output += "_mruby.prototype[\"f_#{@cur_block_no}\"] = function("

    # arguments
    # argc always > 0 because self is always passed
    argc = irep.nlocals
    (argc - 1).times do |no|
      output += "r#{no},"
    end
    output += "r#{argc - 1}) {\n"

    # variable decl.
    (argc...(irep.nregs - 1)).each do |no|
      output += "var r#{no};\n"
    end
    output += "var state = 0\n"
    output += "while (1) {\n"
    output += "switch(state) {\n"
    output += "case 0:\n"

    iseq = @rite_vm.to_relocate_iseq(irep)
    iseq.each do |ins|
      if ins.is_a?(Fixnum) then
        # Label
        output += "case #{ins}: \n"
      else
        output += dispatch_inst(irep, ins, Object)
      end
    end

    output += "}"               # for switch
    output += "}"               # for while
    output += "}"               # for function
    output
  end
end

if $0 == __FILE__ then
def fib(n)
  if n == 1 then
    1
  elsif n == 0 then
    1
  else
    fib(n - 1) + fib(n - 2)
  end
end
tr = M2JTranslator.new
print tr.translate(Irep::get_irep(self, :fib))
end
