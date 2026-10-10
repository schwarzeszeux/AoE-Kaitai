meta:
  id: aoe2record
  title: Age of Empires II Definitive Edition recorded game (.aoe2record)
  application: Age of Empires II - Definitive Edition
  file-extension: aoe2record
  license: MIT
  endian: le
  imports:
    - aoe2record_header
    - aoe2record_body
doc: |
  Recorded game (replay) of Age of Empires II: Definitive Edition.

  A recording consists of one or more chapters. A new chapter is written every time the game
  is saved/restored during play; most recordings have only one. Each chapter is:

  * `header_end_pos` (u4): absolute file offset where the compressed header ends and the
    chapter body begins,
  * `next_chapter_pos` (u4): absolute file offset of the next chapter, 0 for the last one,
  * the header, compressed with raw DEFLATE (no zlib header/trailer), see
    `aoe2record_header.ksy`,
  * the body (operations: actions, syncs, chat, ...) up to the next chapter or the end of the
    file, see `aoe2record_body.ksy`.

  The header of the first chapter describes the game as it was set up in the lobby
  (players, civilizations, map, settings); the body operations of all chapters together
  describe the whole game (e.g. the game duration is the sum of all sync `time_increment`s,
  or `postgame` world_time when present).

  What is decoded and what is kept raw (details in the docs of the two imported specs):

  * Header: version, the complete DE settings block (settings, players, lobby options,
    strings, lobby name), replay info, map (size, zones, tiles, visibility) and the start
    of the initial state. Kept raw (`header.unparsed`): AI script data (present when a
    computer player takes part; then replay / map / initial are not decoded either), the
    per-player initial state with starting objects, the scenario / trigger section, the
    achievements block and the lobby block (pre-game chat, map seed). The reference
    parsers only reach these parts by searching for byte patterns, which Kaitai Struct
    cannot express.
  * Body: every operation (action, sync incl. checksum blocks, viewlock, chat, start,
    postgame) is decoded with its correct length. Every action has its type decoded and,
    since save version 37, its player; the payloads of the common action types are decoded
    and the rest is kept as raw bytes.
  * Only Definitive Edition recordings are decoded beyond the version fields; HD Edition
    recordings (same file extension) get `header.is_de == false` and no body operations.
  * A truncated recording (e.g. after a game crash) fails when the operations are read;
    the header can still be read.

  Decompression uses the custom process routine `raw_inflate` (raw DEFLATE, RFC 1951), because
  the built-in `zlib` process expects a zlib (RFC 1950) wrapper. An implementation must be
  supplied for the target language (C#: class `Kaitai.RawInflate` implementing
  `Kaitai.CustomDecoder`).

  Format knowledge is based on aoc-mgz (https://github.com/happyleavesaoc/aoc-mgz, MIT) and
  aoe2rec (https://github.com/aoe2ct/aoe2rec, MIT) and verified against recordings with save
  versions 12.97 to 68.9.
doc-ref:
  - https://github.com/happyleavesaoc/aoc-mgz
  - https://github.com/aoe2ct/aoe2rec
seq:
  - id: chapters
    type: chapter
    repeat: until
    repeat-until: _.next_chapter_pos == 0 or _io.eof
types:
  chapter:
    seq:
      - id: header_end_pos
        type: u4
        doc: Absolute file offset of the end of the compressed header (= start of the body).
      - id: next_chapter_pos
        type: u4
        doc: Absolute file offset of the next chapter, 0 if this is the last chapter.
      - id: header
        size: header_end_pos - _io.pos
        process: raw_inflate
        type: aoe2record_header
      - id: body
        size: '(next_chapter_pos != 0 ? next_chapter_pos : _io.size) - _io.pos'
        type: aoe2record_body(header.save_version)
        doc: Operations of this chapter; decoded lazily through `body.operations`.
