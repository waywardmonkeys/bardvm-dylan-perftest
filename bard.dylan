module: bard
synopsis: 
author: 
copyright: 

define variable *pc* :: <integer> = 0;
define variable *vals* = make(<vector>, size: 8, fill: 0);
define variable *nvals* :: <integer> = 0;
define variable *env* = vector(vector(0));

define inline function pushv! (v)
  *vals*[*nvals*] := v;
  *nvals* := *nvals* + 1;
end;

define inline function popv! ()
 *nvals* := *nvals* - 1;
 *vals*[*nvals*]
end;

define inline function opcode (i)
  i[0]
end;

define inline function arg1 (i)
  i[1]
end;

define inline function arg2 (i)
  i[2]
end;

define inline function setpc! (d)
  *pc* := d;
end;

define inline function incpc! ()
  *pc* := *pc* + 1;
end;

define inline function lref (i, j)
  *env*[i][j]
end;

define inline function lset! (i, j, v)
  *env*[i][j] := v;
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

define function %const (instr)
  pushv!(arg1(instr));
  incpc!();
end;

define function %jump (instr)
  setpc!(arg1(instr));
end;

define function %fjump (instr)
  if (popv!())
    incpc!()
  else
    setpc!(arg1(instr));
  end if;
end;

define function %lref (instr)
  pushv!(lref(arg1(instr), arg2(instr)));
  incpc!();
end;

define function %lset (instr)
  lset!(arg1(instr), arg2(instr), popv!());
  incpc!();
end;

define function %gt (instr)
  if (popv!() > popv!())
    pushv!(#t);
  else
    pushv!(#f);
  end if;
  incpc!();
end;

define function %add (instr)
  pushv!(popv!() + popv!());
  incpc!();
end;

define variable *instructions* = #f;

define function exec! ()
  let instr = $code[*pc*];
  let opfn = *instructions*[opcode(instr)];
  opfn(instr);
  exec!();
end;

define constant $code
  = vector(vector($LREF, 0, 0),
           vector($CONST, 1000000, 0),
           vector($GT, 0, 0),
           vector($FJUMP, 9, 0),
           vector($LREF, 0, 0),
           vector($CONST, 1, 0),
           vector($ADD, 0, 0),
           vector($LSET, 0, 0),
           vector($JUMP, 0, 0),
           vector($HALT, 0, 0));

define function vmrun ()
  block (exit)
    %halt := exit;
    *instructions* := vector(%halt, %const, %jump, %fjump, %lref, %lset, %gt, %add);
    exec!();
  end;
end;

vmrun();
format-out("\n%=\n", *env*);
