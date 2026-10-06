MODULE FntTest;  (** FntTest.Check name height runs: the header of an Oberon screen font *)
IMPORT Files, texts, out;

PROCEDURE Int(VAR s: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN i := 0; n := 0; WHILE s[i] # 0X DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END; RETURN n
END Int;

PROCEDURE Check*;
VAR A: texts.Reader; name, hs, rs: ARRAY 64 OF CHAR; f: Files.File; R: Files.Rider; id, type, ch: CHAR; h, runs, i, x, fails: INTEGER;
BEGIN
  texts.OpenArgs(A);
  IF ~texts.Arg(A, name) OR ~texts.Arg(A, hs) OR ~texts.Arg(A, rs) THEN out.String("usage: FntTest.Check name height runs"); out.Ln; RETURN END;
  f := Files.Old(name); IF f = NIL THEN out.String("FntTest: no "); out.String(name); out.Ln; RETURN END;
  Files.Set(R, f, 0); Files.Read(R, id); Files.Read(R, type); Files.Read(R, ch); Files.Read(R, ch);
  Files.ReadInt(R, h); i := 0; WHILE i < 4 DO Files.ReadInt(R, x); INC(i) END; Files.ReadInt(R, runs);
  fails := 0;
  IF (id # 0DBX) OR (type # 0X) THEN INC(fails); out.String("FAIL not a screen font"); out.Ln END;
  IF h # Int(hs) THEN INC(fails); out.String("FAIL height "); out.Int(h, 0); out.Ln END;
  IF runs # Int(rs) THEN INC(fails); out.String("FAIL runs "); out.Int(runs, 0); out.Ln END;
  out.String("FntTest: "); out.Int(fails, 0); out.String(" failed"); out.Ln
END Check;

END FntTest.
