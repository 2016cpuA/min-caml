let limit = ref 1000

let syntax_option = ref false
let knormal_option = ref false
let alpha_option = ref false
let cls_option = ref false

let rec iter n e = 
  Format.eprintf "iteration %d@." n;
  if n = 0 then e else
    let e' = Elim.f (ConstFold.f (ConstFold.f (Inline.f (Assoc.f (Beta.f e))))) in
    if e = e' then e else
      iter (n - 1) e'

let lexbuf outchan l = 
  Id.counter := 0;
  Typing.extenv := M.empty;
  let ast = 
    (let ast = RegAlloc.f
         (Simm.f
            (Virtual.f
               (let ast = Closure.f
                    (iter !limit
                       (let ast = Alpha.f
                            (let ast =  KNormal.f
                                 (Typing.f
                                    (let ast = Parser.exp Lexer.token l in
                                     if !syntax_option then print_endline
                                         (Syntax.show ast) else () ; ast))
                             in if !knormal_option then print_endline (KNormal.show ast) else () ; ast)
                        in if !alpha_option then print_endline  (KNormal.show ast) else (); (* Arrayopt.findArray ast; *) ast) 
                    ) in if !cls_option then print_endline (Closure.show_prog ast) else (); ast)
            )) in ast (* print_endline (Asm.show_prog ast); ast*))
  in Emit_opt.f outchan ast (*Emit.f outchan ast*)


let string s = lexbuf stdout (Lexing.from_string s)

let file f = 
  let inchan = open_in (f ^ ".ml") in
  let outchan = open_out (f ^ ".s") in
  try
    lexbuf outchan (Lexing.from_channel inchan);
    close_in inchan;
    close_out outchan;
  with e -> (close_in inchan; close_out outchan; raise e)

let () =
  let files = ref [] in
  Arg.parse
    [("-inline", Arg.Int(fun i -> Inline.threshold := i), "maximum size of functions inlined");
     ("-iter", Arg.Int(fun i -> limit := i), "maximum number of optimizations iterated");
     ("-syntax", Arg.Unit(fun () -> syntax_option := true), "dump ast of syntax");
     ("-knormal", Arg.Unit(fun () -> knormal_option := true), "dump ast of knormal");
     ("-alpha", Arg.Unit(fun () -> alpha_option := true), "dump ast of alpha");
     ("-cls", Arg.Unit(fun () -> cls_option := true), "dump ast of closure")]
    (fun s -> files := !files @ [s])
    ("Mitou Min-Caml Compiler (C) Eijiro Sumii\n" ^
     Printf.sprintf "usage: %s [-inline m] [-iter n] ...filenames without \".ml\"..." Sys.argv.(0));
  List.iter
    (fun f -> ignore (file f))
    !files
