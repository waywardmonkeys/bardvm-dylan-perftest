module: bard
synopsis: 
author: 
copyright: 

define variable *pc* :: <integer> = 0;
define variable *vals* :: <simple-object-vector> = make(<vector>, size: 8, fill: 0);
define variable *nvals* :: <integer> = 0;
define variable *env* :: <simple-object-vector> = vector(vector(0));

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
  *vals*[*nvals*] := v;
  *nvals* := *nvals* + 1;
end;

define inline function popv! ()
 *nvals* := *nvals* - 1;
 *vals*[*nvals*]
end;

define inline function setpc! (d)
  *pc* := d;
end;

define inline function incpc! ()
  *pc* := *pc* + 1;
end;

define inline function lref (i, j)
  vector-element(vector-element(*env*, i), j)
end;

define inline function lset! (i, j, v)
  vector-element(vector-element(*env*, i), j) := v;
end;

define constant $HALT  = 0;
define constant $CONST = 1;
define constant $JUMP  = 2;
define constant $FJUMP = 3;
define constant $LREF  = 4;
define constant $LSET  = 5;
define constant $GT    = 6;
define constant $ADD   = 7;

define variable %halt = #f;

define function %const (instr :: <instruction>) => ()
  pushv!(arg1(instr));
  incpc!();
end;

define function %jump (instr :: <instruction>) => ()
  setpc!(arg1(instr));
end;

define function %fjump (instr :: <instruction>) => ()
  if (popv!())
    incpc!()
  else
    setpc!(arg1(instr));
  end if;
end;

define function %lref (instr :: <instruction>) => ()
  pushv!(lref(arg1(instr), arg2(instr)));
  incpc!();
end;

define function %lset (instr :: <instruction>) => ()
  lset!(arg1(instr), arg2(instr), popv!());
  incpc!();
end;

define function %gt (instr :: <instruction>) => ()
  if (popv!() > popv!())
    pushv!(#t);
  else
    pushv!(#f);
  end if;
  incpc!();
end;

define function %add (instr :: <instruction>) => ()
  pushv!(popv!() + popv!());
  incpc!();
end;

define variable *instructions* :: <simple-object-vector> = #[];

define function exec! ()
  let instr = $code[*pc*];
  let opfn = *instructions*[opcode(instr)];
  opfn(instr);
  exec!();
end;

define constant $code :: <simple-object-vector>
  = vector(make-instruction($LREF, 0, 0),
           make-instruction($CONST, 1000000, 0),
           make-instruction($GT, 0, 0),
           make-instruction($FJUMP, 9, 0),
           make-instruction($LREF, 0, 0),
           make-instruction($CONST, 1, 0),
           make-instruction($ADD, 0, 0),
           make-instruction($LSET, 0, 0),
           make-instruction($JUMP, 0, 0),
           make-instruction($HALT, 0, 0));

define function vmrun ()
  block (exit)
    %halt := exit;
    *instructions* := vector(%halt, %const, %jump, %fjump, %lref, %lset, %gt, %add);
    exec!();
  end;
end;

vmrun();
format-out("\n%=\n", *env*);
