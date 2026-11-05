MODULE FntTest;  (** FntTest.Check name height runs: the header of an Oberon screen font *)
IMPORT Files, Texts, Out;

PROCEDURE Int(VAR s: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN i := 0; n := 0; WHILE s[i] # 0X DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END; RETURN n
END Int;

PROCEDURE Check*;
VAR A: Texts.Reader; name, hs, rs: ARRAY 64 OF CHAR; f: Files.File; R: Files.Rider; id, type, ch: CHAR; h, runs, i, x, fails: INTEGER;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, name) OR ~Texts.Arg(A, hs) OR ~Texts.Arg(A, rs) THEN Out.String("usage: FntTest.Check name height runs"); Out.Ln; RETURN END;
  f := Files.Old(name); IF f = NIL THEN Out.String("FntTest: no "); Out.String(name); Out.Ln; RETURN END;
  Files.Set(R, f, 0); Files.Read(R, id); Files.Read(R, type); Files.Read(R, ch); Files.Read(R, ch);
  Files.ReadInt(R, h); i := 0; WHILE i < 4 DO Files.ReadInt(R, x); INC(i) END; Files.ReadInt(R, runs);
  fails := 0;
  IF (id # 0DBX) OR (type # 0X) THEN INC(fails); Out.String("FAIL not a screen font"); Out.Ln END;
  IF h # Int(hs) THEN INC(fails); Out.String("FAIL height "); Out.Int(h, 0); Out.Ln END;
  IF runs # Int(rs) THEN INC(fails); Out.String("FAIL runs "); Out.Int(runs, 0); Out.Ln END;
  Out.String("FntTest: "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Check;

END FntTest.
