# bdffont, BDF fonts for polpo

`bdffont.Convert input.bdf output.Scn.Fnt` converts an ISO 10646 BDF bitmap font (the fonts of
X11, GNU Unifont, Terminus ...) into an Oberon screen font (`.Scn.Fnt`): the glyphs with their
widths and offsets, in runs of consecutive codes up to 7FFFH. A console command.

    bdffont.Mod          the converter
    test/sample.bdf      a font of three glyphs (A, B and D: two runs)
    test/FntTest.Mod     FntTest.Check name height runs: the header of the converted font

Install with portia: `portia.Install bdffont`; `portia.Test bdffont`.

The license is GPL-3: `LICENSE`.
