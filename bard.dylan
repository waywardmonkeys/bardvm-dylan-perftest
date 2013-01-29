module: bard
synopsis: 
author: 
copyright: 

define variable *pc* :: <integer> = 0;
define variable *vals* :: <simple-object-vector> = make(<vector>, size: 8, fill: 0);
define variable *nvals* :: <integer> = 0;

define constant <environment> = limited(<vector>, of: <simple-object-vector>);
define variable *env* :: <environment> = as(<environment>, vector(vector(0)));

define class <instruction> (<object>)
  constant slot opcode :: <integer>,
    required-init-keyword: opcode:;
  constant slot arg1 = 0,
    init-keyword: arg1:;
  constant slot arg2 = 0,
    init-keyword: arg2:;
end;

define inline function make-instruction (opcode :: <integer>, arg1, arg2)
  make(<instruction>, opcode: opcode, arg1: arg1, arg2: arg2)
end;

define inline function pushv! (v)
  without-bounds-checks
    *vals*[*nvals*] := v;
    *nvals* := *nvals* + 1;
  end
end;

define inline function popv! ()
  without-bounds-checks
    *nvals* := *nvals* - 1;
    *vals*[*nvals*]
  end
end;

define inline function setpc! (d)
  *pc* := d;
end;

define inline function incpc! ()
  *pc* := *pc* + 1;
end;

define inline function lref (i :: <integer>, j :: <integer>)
  without-bounds-checks
    *env*[i][j]
  end
end;

define inline function lset! (i :: <integer>, j :: <integer>, v)
  without-bounds-checks
    *env*[i][j] := v;
  end
end;

define constant $HALT  = 0;
define constant $CONST = 1;
define constant $JUMP  = 2;
define constant $FJUMP = 3;
define constant $LREF  = 4;
define constant $LSET  = 5;
define constant $GT    = 6;
define constant $ADD   = 7;
define constant $MAX-I = 8;

define inline function %const (instr :: <instruction>) => ()
  pushv!(arg1(instr));
  incpc!();
end;

define inline function %jump (instr :: <instruction>) => ()
  setpc!(arg1(instr));
end;

define inline function %fjump (instr :: <instruction>) => ()
  if (popv!())
    incpc!()
  else
    setpc!(arg1(instr));
  end if;
end;

define inline function %lref (instr :: <instruction>) => ()
  pushv!(lref(arg1(instr), arg2(instr)));
  incpc!();
end;

define inline function %lset (instr :: <instruction>) => ()
  lset!(arg1(instr), arg2(instr), popv!());
  incpc!();
end;

define inline function %gt (instr :: <instruction>) => ()
  let i1 :: <integer> = popv!();
  let i2 :: <integer> = popv!();
  if (i1 > i2)
    pushv!(#t);
  else
    pushv!(#f);
  end if;
  incpc!();
end;

define inline function %add (instr :: <instruction>) => ()
  let i1 :: <integer> = popv!();
  let i2 :: <integer> = popv!();
  pushv!(i1 + i2);
  incpc!();
end;

define constant <function-vector> = limited(<vector>, of: <function>);
define variable *instructions* :: <function-vector> = make(<function-vector>, size: $MAX-I, fill: identity);

define function exec! ()
  without-bounds-checks
    let instr = $code[*pc*];
    select (opcode(instr))
      $CONST => %const(instr);
      $JUMP => %jump(instr);
      $FJUMP => %fjump(instr);
      $LREF => %lref(instr);
      $LSET => %lset(instr);
      $GT => %gt(instr);
      $ADD => %add(instr);
      otherwise => *instructions*[opcode(instr)](instr);
    end;
  end;
  exec!();
end;

define constant <program> = limited(<vector>, of: <instruction>);

define constant $code :: <program>
  = as(<program>, vector(make-instruction($LREF, 0, 0),
                         make-instruction($CONST, 1000000, 0),
                         make-instruction($GT, 0, 0),
                         make-instruction($FJUMP, 9, 0),
                         make-instruction($LREF, 0, 0),
                         make-instruction($CONST, 1, 0),
                         make-instruction($ADD, 0, 0),
                         make-instruction($LSET, 0, 0),
                         make-instruction($JUMP, 0, 0),
                         make-instruction($HALT, 0, 0)));

define function vmrun ()
  block (exit)
    *instructions*
      := as(<function-vector>,
            vector(exit, %const, %jump, %fjump, %lref, %lset, %gt, %add));
    exec!();
  end;
end;

define method print-object (env :: <environment>, stream :: <stream>) => ()
  for (e in env)
    print(e, stream);
  end;
end;

profiling (cpu-time-seconds, cpu-time-microseconds)
  vmrun();
results
  format-out("vmrun (in %d.%s seconds)\n",
             cpu-time-seconds, integer-to-string(cpu-time-microseconds, size: 6));
end profiling;
format-out("\n%=\n", *env*);
