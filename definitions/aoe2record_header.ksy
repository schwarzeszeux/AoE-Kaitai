meta:
  id: aoe2record_header
  title: Age of Empires II Definitive Edition recorded game, decompressed chapter header
  application: Age of Empires II - Definitive Edition
  license: MIT
  endian: le
doc: |
  The decompressed header of one chapter of an `.aoe2record` file (see `aoe2record.ksy`,
  which inflates it and hands it to this type).

  Layout, in order:

  1. `game_version` / save version (always parsed).
  2. `de` - the Definitive Edition settings block: game settings, players (name, civ, colour,
     team, profile id, AI), lobby options, RMS strings, strategic numbers, lobby name, ...
     (parsed for every DE save version, 12.97 and newer).
  3. `ai` - only the `has_ai` flag is parsed. When it is non-zero (a player is a computer AI),
     the AI script data follows (strings, rules, timers, goals). Neither reference parser
     decodes its DE layout; both skip it by searching for the next run of 4096 zero bytes,
     which Kaitai Struct cannot express. In that case parsing of the structured part stops
     here and the rest of the header ends up in `unparsed`.
  4. `replay` - world time, speed, recording player, number of players, ... (only if no AI data).
  5. `map` - map size, zones, tiles (decoded lazily), visibility maps (only if no AI data).
  6. `initial` - restore time, particles, identifier (only if no AI data).
  7. `unparsed` - everything after the last structured section, as raw bytes. This contains the
     per-player initial state (diplomacy, resources/stats, starting objects), the scenario
     section (instructions, triggers), the achievements block and the lobby block (team
     choices, pre-game chat, map seed). The reference parsers only reach these by
     byte-searching (for player objects, the scenario settings version and the player end
     marker), so they are deliberately not described here.

  Save versions are compared as an integer `save_version` = version * 100 (e.g. 61.5 -> 6150,
  66.6 -> 6660), see the `save_version` instance. Version differences are taken from the
  reference parsers aoc-mgz (https://github.com/happyleavesaoc/aoc-mgz, MIT) and aoe2rec
  (https://github.com/aoe2ct/aoe2rec, MIT) and verified against real recordings from save
  version 12.97 to 68.9.

  Only Definitive Edition recordings are supported (`is_de`). For HD Edition/older recordings
  only the version fields are parsed and everything else is left in `unparsed`.
seq:
  - id: game_version
    type: strz
    encoding: ASCII
    doc: Always "VER 9.4" for DE.
  - id: old_save_version
    type: f4
    doc: Save version as float (e.g. 25.22), or -1 when `new_save_version` is used (37 and newer).
  - id: new_save_version
    type: new_save_version_data
    if: old_save_version == -1
    doc: Save version for 37 and newer. Use the `save_version` instance instead.
  - id: de
    type: de_section
    if: is_de
  - id: ai
    type: ai_section
    if: is_de
  - id: replay
    type: replay_section
    if: has_structured_tail
  - id: map
    type: map_section
    if: has_structured_tail
  - id: initial
    type: initial_section
    if: has_structured_tail
  - id: unparsed
    type: unparsed_data(_io.pos)
    doc: |
      Remaining header bytes that are not described (see the top-level doc), read lazily
      through `unparsed.data`. If `ai.has_ai` is non-zero they start with the AI data,
      otherwise with the initial player data.
instances:
  save_version:
    value: 'old_save_version == -1 ? new_save_version.x100 : (old_save_version * 100 + 0.5).to_i'
    doc: |
      Save version * 100 as an integer, e.g. 1334 (13.34), 2522 (25.22), 3700 (37.0),
      5070 (50.7), 6150 (61.5), 6430 (64.3), 6660 (66.6), 6720 (67.2), 6890 (68.9).
  is_de:
    value: game_version == "VER 9.4" and save_version >= 1297
    doc: True for Definitive Edition recordings (save version 12.97 and newer).
  has_structured_tail:
    value: is_de and ai.has_ai == 0
    doc: True if `replay`, `map` and `initial` could be parsed (no AI data in the header).
types:
  unparsed_data:
    doc: Raw bytes from `ofs_start` to the end of the header; nothing is read until `data` is accessed.
    params:
      - id: ofs_start
        type: s8
    instances:
      len_data:
        value: _io.size - ofs_start
      data:
        pos: ofs_start
        size: len_data

  new_save_version_data:
    seq:
      - id: raw
        type: u4
        doc: |
          16.16 fixed point (major version in the high word, fraction in the low word), or the
          plain value 37 in some early 37 builds.
    instances:
      x100:
        value: 'raw == 37 ? 3700 : ((raw >> 16) * 100 + ((raw & 0xffff) * 100 + 32768) / 65536).as<s4>'
        doc: Save version * 100.

  de_string:
    doc: DE string, prefixed with the magic 0x60 0x0A and a 16-bit length.
    seq:
      - id: magic
        contents: [0x60, 0x0a]
      - id: len_value
        type: u2
      - id: value
        type: str
        size: len_value
        encoding: UTF-8

  string_block:
    doc: |
      A list of DE strings, each preceded by a u4 (a CRC or 0). The list ends with a u4
      that is between 1 and 254 (inclusive), which is not followed by a string.
    seq:
      - id: entries
        type: string_block_entry
        repeat: until
        repeat-until: _.is_terminator
  string_block_entry:
    seq:
      - id: crc
        type: u4
      - id: value
        type: de_string
        if: not is_terminator
    instances:
      is_terminator:
        value: crc > 0 and crc < 255

  de_section:
    doc: Definitive Edition game settings and players.
    seq:
      - id: build
        type: u4
        if: _root.save_version >= 2522
        doc: Game build number (e.g. 158041). Present since 25.22.
      - id: timestamp
        type: u4
        if: _root.save_version >= 2616
        doc: Unix timestamp of the game start. Present since 26.16.
      - id: version
        type: f4
      - id: interval_version
        type: u4
      - id: game_options_version
        type: u4
      - id: num_dlc_ids
        type: u4
      - id: dlc_ids
        type: u4
        repeat: expr
        repeat-expr: num_dlc_ids
      - id: difficulty
        type: s4
        enum: difficulty
        doc: |
          AI difficulty (3 = standard is the default in games without AI, -1 = extreme).
          aoc-mgz calls this field dataset_ref; recordings against AI show the selected AI
          difficulty here, as aoe2rec assumes.
      - id: map_size_raw
        type: u4
        doc: |
          Before 61.5 the map size id (enum `map_size`: 0 = tiny ... 6 = ludicrous), since 61.5
          the map size in tiles (120, 144, 168, 200, 220, 240, 480). aoc-mgz reads the old value
          as difficulty. Use the `map_size_id` / `map_size_tiles` instances.
      - id: selected_map_id
        type: u4
        doc: Map id selected in the lobby (may be a "random" map id).
      - id: resolved_map_id
        type: u4
        doc: Map id actually played (e.g. 9 = Arabia, 29 = Arena, 33 = Nomad, 77 = MegaRandom).
      - id: reveal_map
        type: u4
        enum: reveal_map
      - id: victory_type
        type: u4
        enum: victory_type
      - id: starting_resources
        type: u4
        enum: starting_resources
      - id: starting_age
        type: u4
        enum: age_setting
      - id: ending_age
        type: u4
        enum: age_setting
      - id: game_type
        type: u4
        enum: game_type
      - id: separator1
        contents: [0xa3, 0x5f, 0x02, 0x00]
      - id: separator2
        contents: [0xa3, 0x5f, 0x02, 0x00]
      - id: speed
        type: f4
        doc: Game speed multiplier, e.g. 1.0 (slow), 1.5 / 1.7 (normal), 2.0 (fast).
      - id: treaty_length
        type: u4
      - id: population_limit
        type: u4
      - id: num_players
        type: u4
        doc: Number of players (without Gaia).
      - id: unused_player_color
        type: u4
      - id: victory_amount
        type: s4
      - id: unknown_61_5
        type: u1
        if: _root.save_version >= 6150
      - id: separator3
        contents: [0xa3, 0x5f, 0x02, 0x00]
      - id: trade_enabled
        type: u1
      - id: team_bonus_disabled
        type: u1
      - id: random_positions
        type: u1
      - id: all_techs
        type: u1
      - id: num_starting_units
        type: u1
      - id: lock_teams
        type: u1
      - id: lock_speed
        type: u1
      - id: multiplayer
        type: u1
      - id: cheats
        type: u1
      - id: record_game
        type: u1
      - id: animals_enabled
        type: u1
      - id: predators_enabled
        type: u1
      - id: turbo_enabled
        type: u1
      - id: shared_exploration
        type: u1
      - id: team_positions
        type: u1
      - id: sub_game_mode
        type: u4
        if: _root.save_version >= 1334
      - id: battle_royale_time
        type: u4
        if: _root.save_version >= 1334
      - id: handicap
        type: u1
        if: _root.save_version >= 2506
      - id: unknown_50
        type: u1
        if: _root.save_version >= 5000
      - id: separator4
        contents: [0xa3, 0x5f, 0x02, 0x00]
      - id: players
        type: de_player
        repeat: expr
        repeat-expr: '_root.save_version >= 3700 and _root.save_version < 6630 ? num_players : 8'
        doc: |
          Player slots. For save versions 37 <= v < 66.3 only the `num_players` used slots are
          stored; otherwise all 8 slots are stored and unused slots have `player_type` closed
          (1) / absent (0) and `profile_id` -1 or 0.
      - id: unknown_after_players
        size: 9
      - id: fog_of_war
        type: u1
      - id: cheat_notifications
        type: u1
      - id: colored_chat
        type: u1
      - id: empty_slots
        type: de_empty_slot
        repeat: expr
        repeat-expr: 8 - num_players
        if: _root.save_version >= 3700 and _root.save_version < 6630
      - id: separator5
        contents: [0xa3, 0x5f, 0x02, 0x00]
      - id: ranked
        type: u1
      - id: allow_spectators
        type: u1
      - id: lobby_visibility
        type: u4
        enum: lobby_visibility
      - id: hidden_civs
        type: u1
      - id: matchmaking
        type: u1
      - id: spectator_delay
        type: u4
        if: _root.save_version >= 1313
        doc: Spectator delay in seconds.
      - id: scenario_civ
        type: u1
        if: _root.save_version >= 1313
      - id: rms_strings
        type: string_block
        doc: |
          Random map script strings, e.g. "SUBSCRIBEDMODS:RANDOM_MAPS:<file>.rms:<modid>_..." for
          custom (mod) maps.
      - id: unknown_after_rms_strings
        size: 8
      - id: other_strings
        type: string_block
        repeat: expr
        repeat-expr: 20
      - id: num_strategic_numbers
        type: u4
      - id: strategic_numbers
        type: s4
        repeat: expr
        repeat-expr: '_root.save_version >= 2522 ? num_strategic_numbers : 59'
      - id: num_ai_files
        type: u8
      - id: ai_files
        type: de_ai_file
        repeat: expr
        repeat-expr: num_ai_files.as<s4>
      - id: unknown_25_02
        size: 8
        if: _root.save_version >= 2502
      - id: guid
        size: 16
        doc: Game GUID (identical for all recordings of the same game).
      - id: lobby_name
        type: de_string
      - id: unknown_25_22
        size: 8
        if: _root.save_version >= 2522
      - id: modded_dataset
        type: de_string
      - id: unknown_tail1
        size: 19
      - id: unknown_tail_13_13
        size: 5
        if: _root.save_version >= 1313
      - id: unknown_tail_13_17
        size: 9
        if: _root.save_version >= 1317
      - id: unknown_tail_20_06
        size: 1
        if: _root.save_version >= 2006
      - id: unknown_tail_20_16
        size: 8
        if: _root.save_version >= 2016
      - id: unknown_tail_25_06
        size: 21
        if: _root.save_version >= 2506
      - id: unknown_tail_25_22
        size: 4
        if: _root.save_version >= 2522
      - id: unknown_tail_26_16
        size: 8
        if: _root.save_version >= 2616
      - id: unknown_tail_37
        size: 3
        if: _root.save_version >= 3700
      - id: unknown_tail_50
        size: 8
        if: _root.save_version >= 5000
      - id: unknown_tail_61_5
        size: 1
        if: _root.save_version >= 6150
      - id: unknown_tail_63
        size: 5
        if: _root.save_version >= 6300
      - id: num_unknown_66_3_values
        type: u4
        if: _root.save_version >= 6630
      - id: unknown_tail_66_3
        size: 12
        if: _root.save_version >= 6630
      - id: unknown_66_3_values
        type: u4
        repeat: expr
        repeat-expr: num_unknown_66_3_values
        if: _root.save_version >= 6630
      - id: unknown_string1
        type: de_string
      - id: unknown_strings_67
        type: de_string
        repeat: expr
        repeat-expr: 2
        if: _root.save_version >= 6700
      - id: unknown_tail2
        size: 5
      - id: unknown_tail2_13_13
        size: 1
        if: _root.save_version >= 1313
      - id: unknown_pre_13_17
        type: de_unknown_pre_13_17
        if: _root.save_version < 1317
      - id: unknown_tail2_13_17
        size: 2
        if: _root.save_version >= 1317
      - id: timestamp2
        type: u4
        if: _root.save_version >= 3700
        doc: |
          Unix timestamp of the game start (also set when `timestamp` is 0, e.g. in 50.7),
          0 in later chapters.
      - id: unknown_37
        type: u4
        if: _root.save_version >= 3700
    instances:
      map_size_id:
        value: map_size_raw
        enum: map_size
        if: _root.save_version < 6150
        doc: Map size setting, only stored here before 61.5.
      map_size_tiles:
        value: map_size_raw
        if: _root.save_version >= 6150
        doc: Map size in tiles per side, only stored here since 61.5 (see also `map.size_x`).

  de_player:
    doc: A DE player slot.
    seq:
      - id: dlc_id
        type: u4
      - id: color_id
        type: s4
        doc: Player colour index, 0 = blue, 1 = red, 2 = green, 3 = yellow, 4 = teal, 5 = purple, 6 = grey, 7 = orange.
      - id: selected_color
        type: u1
      - id: selected_team_id
        type: u1
      - id: resolved_team_id
        type: u1
        doc: |
          Team as shown in the lobby: 1 = no team, 2..5 = team 1..4 (aoc-mgz treats 1 as a
          team of its own).
      - id: dat_crc
        size: 8
      - id: mp_game_version
        type: u1
      - id: civ_id
        type: u4
        enum: civilization
      - id: num_custom_civ_ids
        type: u4
        if: _root.save_version >= 6150
      - id: custom_civ_ids
        type: u4
        repeat: expr
        repeat-expr: num_custom_civ_ids
        if: _root.save_version >= 6150
        doc: Civilization pool for random civ selection.
      - id: ai_type
        type: de_string
      - id: ai_civ_name_index
        type: u1
      - id: ai_name
        type: de_string
        doc: Name of the AI leader for computer players, empty for humans.
      - id: censored_name
        type: de_string
        if: _root.save_version >= 6630
      - id: name
        type: de_string
        doc: Player name (empty for AI players and unused slots).
      - id: player_type
        type: u4
        enum: player_type
      - id: profile_id
        type: s4
        doc: Relic/Microsoft profile id; -1 for AI players, -1 or 0 for unused slots.
      - id: unknown1
        type: s4
      - id: player_number
        type: s4
        doc: Player number 1..8 (-1 for unused slots).
      - id: hd_rm_elo
        type: u4
        if: _root.save_version < 2522
      - id: hd_dm_elo
        type: u4
        if: _root.save_version < 2522
      - id: prefer_random
        type: u1
      - id: custom_ai
        type: u1
      - id: unknown_handicap
        type: s4
        if: _root.save_version >= 2506
      - id: handicap
        type: u4
        if: _root.save_version >= 2506
        doc: Handicap in percent (100 = no handicap).
      - id: unknown_64_3
        type: u4
        if: _root.save_version >= 6430
      - id: unknown_string_67
        type: de_string
        if: _root.save_version >= 6700
    instances:
      is_used:
        value: player_number >= 1 and (player_type == player_type::human or player_type == player_type::computer)
        doc: True for slots occupied by a human or computer player.

  de_empty_slot:
    doc: Unused player slot, only stored this way for save versions 37 <= v < 66.3.
    seq:
      - id: unknown_61_5
        type: u4
        if: _root.save_version >= 6150
      - id: unknown1
        size: 12
      - id: string1
        type: de_string
      - id: unknown2
        type: u1
      - id: string2
        type: de_string
      - id: string3
        type: de_string
      - id: unknown3
        size: 38
      - id: unknown_64_3
        type: u4
        if: _root.save_version >= 6430

  de_ai_file:
    seq:
      - id: unknown1
        type: u4
      - id: name
        type: de_string
      - id: unknown2
        type: u4

  de_unknown_pre_13_17:
    seq:
      - id: unknown_string
        type: de_string
      - id: unknown1
        type: u4
      - id: unknown2
        size: 4

  ai_section:
    seq:
      - id: has_ai
        type: u4
        doc: |
          Non-zero if AI script data follows. That data cannot be described without searching,
          so the rest of the header is then left in `unparsed` (see the top-level doc).

  replay_section:
    doc: Basic replay state (world time, speed, owner, ...).
    seq:
      - id: old_time
        type: u4
      - id: world_time
        type: u4
        doc: World time in ms at the start of this chapter (0 for the first chapter of a normal game).
      - id: old_world_time
        type: u4
      - id: game_speed_id
        type: u4
      - id: world_time_delta_seconds
        type: u4
      - id: timer
        type: f4
      - id: game_speed
        type: f4
      - id: temp_pause
        type: u1
      - id: next_object_id
        type: u4
      - id: next_reusable_object_id
        type: s4
      - id: random_seed
        type: u4
      - id: random_seed_2
        type: u4
      - id: rec_player
        type: u2
        doc: Player number of the player who recorded the game.
      - id: num_players
        type: u1
        doc: Number of players including Gaia.
      - id: instant_build
        type: u1
      - id: cheats_enabled
        type: u1
      - id: game_mode
        type: u2
      - id: campaign
        type: u4
      - id: campaign_player
        type: u4
      - id: campaign_scenario
        type: u4
      - id: king_campaign
        type: u4
      - id: king_campaign_player
        type: u1
      - id: king_campaign_scenario
        type: u1
      - id: player_turn
        type: u4
      - id: player_time_delta
        type: u4
        repeat: expr
        repeat-expr: '_root.save_version >= 6150 ? num_players : 9'
      - id: unknown_de
        size: 8

  map_section:
    doc: Map dimensions, zones and terrain.
    seq:
      - id: size_x
        type: u4
      - id: size_y
        type: u4
      - id: num_zones
        type: u4
      - id: zones
        type: map_zone
        repeat: expr
        repeat-expr: num_zones
      - id: all_visible
        type: u1
      - id: fog_of_war
        type: u1
      - id: tile_size_probe
        type: tile_size_probe(_io.pos, num_tiles)
        if: _root.save_version < 1303
        doc: Needed to tell the two 12.97 tile formats apart (as aoc-mgz does).
      - id: tiles
        size: num_tiles * tile_size
        type: tile_grid(tile_size)
      - id: num_obstruction_sets
        type: u4
      - id: unknown1
        type: u4
      - id: unknown_data
        size: num_obstruction_sets * 4
      - id: obstruction_sets
        type: obstruction_set
        repeat: expr
        repeat-expr: num_obstruction_sets
      - id: size_x_2
        type: u4
      - id: size_y_2
        type: u4
      - id: visibility
        size: size_x_2 * size_y_2 * 4
      - id: unknown_visibility_61_5
        size: size_x_2 * size_y_2 * 4
        if: _root.save_version >= 6150
    instances:
      num_tiles:
        value: size_x * size_y
      tile_size:
        value: >-
          _root.save_version >= 6200 ? 10 :
          _root.save_version >= 1303 ? 9 :
          tile_size_probe.value > 1000 ? 9 : 7
        doc: Size of one tile record in bytes.
  map_zone:
    seq:
      - id: unknown1
        size: 2048 + _parent.num_tiles * 2
      - id: num_floats
        type: u4
      - id: floats
        size: num_floats * 4
      - id: unknown2
        type: u4
  tile_size_probe:
    params:
      - id: tiles_start
        type: s8
      - id: num_tiles
        type: s8
    instances:
      value:
        pos: tiles_start + num_tiles * 7
        type: u4
  tile_grid:
    doc: |
      All map tiles, row by row (index = y * size_x + x). Decoded lazily through the `items`
      instance because there can be up to 480 * 480 of them.
    params:
      - id: tile_size
        type: s4
    instances:
      items:
        pos: 0
        type: tile(tile_size)
        repeat: expr
        repeat-expr: _io.size / tile_size
  tile:
    params:
      - id: tile_size
        type: s4
    seq:
      - id: terrain_type
        type: u1
      - id: unknown_62
        type: u1
        if: tile_size >= 10
      - id: terrain_type_2
        type: u1
      - id: elevation
        type: u1
      - id: unknown1
        type: s2
      - id: unknown2
        type: s2
      - id: unknown3
        type: s2
        if: tile_size >= 9
  obstruction_set:
    seq:
      - id: num_obstructions
        type: u4
      - id: obstructions
        size: num_obstructions * 8

  initial_section:
    doc: |
      Start of the initial game state. Everything after `identifier` (the per-player data and
      starting objects, scenario, achievements and lobby blocks) is in `unparsed`.
    seq:
      - id: restore_time
        type: u4
        doc: Game time in ms the game was restored from, 0 if it was not restored.
      - id: num_particles
        type: u4
      - id: particles
        size: num_particles * 27
      - id: identifier
        type: u4

enums:
  civilization:
    1: britons
    2: franks
    3: goths
    4: teutons
    5: japanese
    6: chinese
    7: byzantines
    8: persians
    9: saracens
    10: turks
    11: vikings
    12: mongols
    13: celts
    14: spanish
    15: aztecs
    16: maya
    17: huns
    18: koreans
    19: italians
    20: hindustanis
    21: incas
    22: magyars
    23: slavs
    24: portuguese
    25: ethiopians
    26: malians
    27: berbers
    28: khmer
    29: malay
    30: burmese
    31: vietnamese
    32: bulgarians
    33: tatars
    34: cumans
    35: lithuanians
    36: burgundians
    37: sicilians
    38: poles
    39: bohemians
    40: dravidians
    41: bengalis
    42: gurjaras
    43: romans
    44: armenians
    45: georgians
    46: achaemenids
    47: athenians
    48: spartans
    49: shu
    50: wu
    51: wei
    52: jurchens
    53: khitans
    54: macedonians
    55: thracians
    56: puru
    57: muisca
    58: mapuche
    59: tupi
    60: saxons
    61: varangians
    62: danes
  player_type:
    0: absent
    1: closed
    2: human
    3: eliminated
    4: computer
    5: cyborg
    6: spectator
  game_type:
    0: random_map
    1: regicide
    2: deathmatch
    3: scenario
    4: campaign
    5: king_of_the_hill
    6: wonder_race
    7: defend_the_wonder
    8: turbo_random_map
    9: lombard
    10: capture_the_relic
    11: sudden_death
    12: battle_royale
    13: empire_wars
    15: co_op_campaign
    16: d3
  victory_type:
    0: standard
    1: conquest
    2: exploration
    3: ruins
    4: artifacts
    5: discoveries
    6: gold
    7: time_limit
    8: score
    9: standard2
    10: regicide
    11: last_man_standing
  starting_resources:
    0: standard
    1: low
    2: medium
    3: high
    4: ultra_high
    5: infinite
    6: random
  age_setting:
    0: default
    1: unknown_1
    2: dark
    3: feudal
    4: castle
    5: imperial
    6: post_imperial
  reveal_map:
    0: normal
    1: explored
    2: all_visible
    3: no_fog
  difficulty:
    -1: extreme
    0: hardest
    1: hard
    2: moderate
    3: standard
    4: easiest
  lobby_visibility:
    0: public
    1: private
    2: hidden
  map_size:
    0: tiny
    1: small
    2: medium
    3: normal
    4: large
    5: giant
    6: ludicrous
