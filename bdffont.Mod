MODULE bdffont;

(** Convert an ISO10646 BDF bitmap font to an Oberon .Scn.Fnt file.
    Usage: bdffont.Convert "input.bdf" "output.Scn.Fnt" *)

IMPORT Files, Texts := texts, Oberon := Oberon0, out;

CONST
  MaxLine = 512;
  MaxCode = 7FFFH;

TYPE
  Raster = POINTER TO ARRAY OF CHAR;
  Glyph = POINTER TO GlyphDesc;
  GlyphDesc = RECORD
    next: Glyph;
    code, dx, x, y, w, h: INTEGER;
    raster: Raster
  END;

PROCEDURE Match(VAR s: ARRAY OF CHAR; key: ARRAY OF CHAR): BOOLEAN;
VAR i: INTEGER;
BEGIN
  i := 0; WHILE (key[i] # 0X) & (s[i] = key[i]) DO INC(i) END;
  RETURN (key[i] = 0X) & ((s[i] = 0X) OR (s[i] = " ") OR (s[i] = 09X))
END Match;

PROCEDURE SkipKey(VAR s: ARRAY OF CHAR; VAR i: INTEGER);
BEGIN
  i := 0; WHILE (s[i] # 0X) & (s[i] # " ") & (s[i] # 09X) DO INC(i) END
END SkipKey;

PROCEDURE Int(VAR s: ARRAY OF CHAR; VAR i: INTEGER): LONGINT;
VAR n: LONGINT; neg: BOOLEAN;
BEGIN
  WHILE (s[i] = " ") OR (s[i] = 09X) DO INC(i) END;
  neg := s[i] = "-"; IF neg THEN INC(i) END;
  n := 0;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO
    n := 10*n + ORD(s[i]) - ORD("0"); INC(i)
  END;
  IF neg THEN n := -n END;
  RETURN n
END Int;

PROCEDURE Hex(ch: CHAR): INTEGER;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch) - ORD("0")
  ELSIF (CAP(ch) >= "A") & (CAP(ch) <= "F") THEN RETURN ORD(CAP(ch)) - ORD("A") + 10
  ELSE RETURN 0
  END
END Hex;

PROCEDURE Reverse(b: INTEGER): CHAR;
VAR i, r: INTEGER;
BEGIN
  r := 0; i := 0;
  WHILE i < 8 DO r := 2*r + b MOD 2; b := b DIV 2; INC(i) END;
  RETURN CHR(r)
END Reverse;

PROCEDURE ReadLine(VAR R: Files.Rider; len: LONGINT; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR ch: CHAR; i: INTEGER; done: BOOLEAN;
BEGIN
  IF Files.Pos(R) >= len THEN s[0] := 0X; RETURN FALSE END;
  i := 0; done := FALSE;
  WHILE (Files.Pos(R) < len) & ~done DO
    Files.Read(R, ch);
    IF ch = 0AX THEN done := TRUE
    ELSIF (ch # 0DX) & (i < LEN(s)-1) THEN s[i] := ch; INC(i)
    END
  END;
  s[i] := 0X; RETURN TRUE
END ReadLine;

PROCEDURE Insert(VAR first: Glyph; g: Glyph; VAR count: INTEGER);
VAR p: Glyph;
BEGIN
  IF (first = NIL) OR (g.code < first.code) THEN
    g.next := first; first := g; INC(count)
  ELSIF g.code = first.code THEN
    g.next := first.next; first := g
  ELSE
    p := first;
    WHILE (p.next # NIL) & (p.next.code < g.code) DO p := p.next END;
    IF (p.next # NIL) & (p.next.code = g.code) THEN
      g.next := p.next.next; p.next := g
    ELSE
      g.next := p.next; p.next := g; INC(count)
    END
  END
END Insert;

PROCEDURE Parse(name: ARRAY OF CHAR; VAR first: Glyph; VAR count, fontW, fontH: INTEGER): BOOLEAN;
VAR
  f: Files.File; R: Files.Rider; len: LONGINT;
  line: ARRAY MaxLine OF CHAR;
  data: Raster; g: Glyph;
  enc, dx, x, y, w, h, bpr, row, i, j, v: INTEGER;
  inBitmap: BOOLEAN;
BEGIN
  f := Files.Old(name);
  IF f = NIL THEN out.String("bdffont: cannot open "); out.String(name); out.Ln; RETURN FALSE END;
  len := Files.Length(f); Files.Set(R, f, 0);
  first := NIL; count := 0; fontW := 0; fontH := 0;
  enc := -1; dx := 0; x := 0; y := 0; w := 0; h := 0;
  data := NIL; row := 0; inBitmap := FALSE;
  WHILE ReadLine(R, len, line) DO
    IF Match(line, "FONTBOUNDINGBOX") THEN
      SkipKey(line, i); fontW := SHORT(Int(line, i)); fontH := SHORT(Int(line, i))
    ELSIF Match(line, "ENCODING") THEN
      SkipKey(line, i); enc := SHORT(Int(line, i))
    ELSIF Match(line, "DWIDTH") THEN
      SkipKey(line, i); dx := SHORT(Int(line, i))
    ELSIF Match(line, "BBX") THEN
      SkipKey(line, i); w := SHORT(Int(line, i)); h := SHORT(Int(line, i));
      x := SHORT(Int(line, i)); y := SHORT(Int(line, i))
    ELSIF Match(line, "BITMAP") THEN
      inBitmap := TRUE; row := 0; bpr := (w + 7) DIV 8;
      IF (enc >= 0) & (enc <= MaxCode) & (w >= 0) & (h >= 0) THEN NEW(data, bpr*h)
      ELSE data := NIL
      END
    ELSIF Match(line, "ENDCHAR") THEN
      IF (enc >= 0) & (enc <= MaxCode) & (data # NIL) THEN
        NEW(g); g.code := enc; g.dx := dx; g.x := x; g.y := y; g.w := w; g.h := h;
        g.raster := data; Insert(first, g, count)
      END;
      enc := -1; data := NIL; inBitmap := FALSE
    ELSIF inBitmap & (data # NIL) & (row < h) THEN
      i := 0; WHILE (line[i] = " ") OR (line[i] = 09X) DO INC(i) END;
      j := 0;
      WHILE j < bpr DO
        v := 16*Hex(line[i]) + Hex(line[i+1]); data[row*bpr+j] := Reverse(v);
        INC(i, 2); INC(j)
      END;
      INC(row)
    END
  END;
  Files.ReleaseRead(f);
  IF count = 0 THEN out.String("bdffont: no usable glyphs"); out.Ln; RETURN FALSE END;
  RETURN TRUE
END Parse;

PROCEDURE WriteInt(VAR R: Files.Rider; x: INTEGER);
BEGIN Files.WriteInt(R, x)
END WriteInt;

PROCEDURE Store(name: ARRAY OF CHAR; first: Glyph; count, fontW, fontH: INTEGER): BOOLEAN;
VAR f: Files.File; R: Files.Rider; p, q: Glyph; runs, i, row, bpr: INTEGER;
BEGIN
  runs := 0; p := first;
  WHILE p # NIL DO
    INC(runs); q := p; WHILE (q.next # NIL) & (q.next.code = q.code + 1) DO q := q.next END;
    p := q.next
  END;
  f := Files.New(name);
  IF f = NIL THEN out.String("bdffont: cannot create "); out.String(name); out.Ln; RETURN FALSE END;
  Files.Set(R, f, 0);
  Files.Write(R, 0DBX); Files.Write(R, 0X);  (* library id, screen font *)
  Files.Write(R, 0X); Files.Write(R, 0X);   (* family, variant *)
  WriteInt(R, fontH); WriteInt(R, 0); WriteInt(R, fontW); WriteInt(R, 0); WriteInt(R, fontH);
  WriteInt(R, runs);
  p := first;
  WHILE p # NIL DO
    q := p; WHILE (q.next # NIL) & (q.next.code = q.code + 1) DO q := q.next END;
    WriteInt(R, p.code); WriteInt(R, q.code + 1); p := q.next
  END;
  p := first;
  WHILE p # NIL DO
    WriteInt(R, p.dx); WriteInt(R, p.x); WriteInt(R, p.y); WriteInt(R, p.w); WriteInt(R, p.h);
    p := p.next
  END;
  p := first;
  WHILE p # NIL DO
    bpr := (p.w + 7) DIV 8; row := p.h;
    WHILE row > 0 DO
      DEC(row); i := 0;
      WHILE i < bpr DO Files.Write(R, p.raster[row*bpr+i]); INC(i) END
    END;
    p := p.next
  END;
  Files.Register(f);
  out.String("bdffont: wrote "); out.String(name); out.String(" with ");
  out.Int(count, 0); out.String(" glyphs in "); out.Int(runs, 0); out.String(" runs"); out.Ln;
  RETURN TRUE
END Store;

PROCEDURE Convert*;
VAR S: Texts.Scanner; input, output: ARRAY 256 OF CHAR; first: Glyph; count, w, h: INTEGER;
BEGIN
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
  IF S.class IN {Texts.Name, Texts.String} THEN COPY(S.s, input); Texts.Scan(S)
  ELSE out.String("usage: bdffont.Convert input.bdf output.Scn.Fnt"); out.Ln; RETURN
  END;
  IF S.class IN {Texts.Name, Texts.String} THEN COPY(S.s, output)
  ELSE out.String("usage: bdffont.Convert input.bdf output.Scn.Fnt"); out.Ln; RETURN
  END;
  IF Parse(input, first, count, w, h) THEN
    IF Store(output, first, count, w, h) THEN END
  END
END Convert;

END bdffont.
