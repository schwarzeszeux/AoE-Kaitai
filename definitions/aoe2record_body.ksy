meta:
  id: aoe2record_body
  title: Age of Empires II Definitive Edition recorded game, chapter body (operations)
  application: Age of Empires II - Definitive Edition
  license: MIT
  endian: le
doc: |
  The body of one chapter of an `.aoe2record` file: a stream of operations that runs until the
  next chapter (or the end of the file). Every operation starts with a u4 operation type:

  * 1 `action` - a player command (length-prefixed, followed by the world time),
  * 2 `sync` - time increment in ms; every `checksum_interval` (500) syncs it carries a
    checksum / per-player statistics block,
  * 3 `viewlock` - camera position of the recording player,
  * 4 `chat` - chat message (a JSON object in DE),
  * 5 `start` - recording meta data, the first operation of the first chapter (aoc-mgz treats
    the 5 as "log version" followed by meta data, aoe2rec as operation "Pregame"),
  * 6 `postgame` - DE post-game data (world time, leaderboards); it is the last operation of
    the file and is stored backwards, so it is decoded from the end of the file.

  The operation list is decoded lazily (`operations` instance), so reading only the header of a
  recording does not pay for parsing hundreds of thousands of operations. Operations are only
  decoded for DE recordings (save version 12.97 and newer); for HD Edition and older
  recordings `operations` is not available (null).

  Actions: since save version 37 (game build 71094) every action starts with type (u1),
  player id (u1) and payload length (u2), followed by the payload. Payloads of the common action
  types are decoded (layouts follow aoc-mgz `mgz/fast/actions.py` and aoe2rec `actions.rs`,
  corrected and extended for the save version differences seen in real recordings), all other
  types are kept as raw bytes (`action_raw`). Every action is parsed inside its own sub-stream,
  so a payload layout can never shift the following operations. Arrays of unit/object ids at
  the end of a payload are sized from the bytes that are left in the action, never from a count
  field (count fields are not always reliable, e.g. AI research actions). The decoded payload
  types are read right after the 4-byte action header, so in their expressions
  `_io.size - 4` is the payload size.

  Before save version 37 actions had no common header; for those only the action type and, for
  a few types, the player are decoded (`legacy_payload`, layouts from aoc-mgz `mgz/fast`).
params:
  - id: save_version
    type: s4
    doc: Save version * 100 from the chapter header (`aoe2record_header.save_version`).
instances:
  operations:
    pos: 0
    type: operation
    repeat: eos
    if: is_supported
    doc: All operations of this chapter, in order (parsed on first access).
  is_supported:
    value: save_version >= 1297
    doc: Operations are only decoded for DE recordings.
  is_new_action_format:
    value: save_version >= 3700
    doc: True if actions have the common type / player / length header (save version 37+).
types:
  operation:
    seq:
      - id: op_type
        type: u4
        enum: operation_type
        valid:
          any-of:
            - operation_type::action
            - operation_type::sync
            - operation_type::viewlock
            - operation_type::chat
            - operation_type::start
            - operation_type::postgame
      - id: data
        type:
          switch-on: op_type
          cases:
            'operation_type::action': op_action
            'operation_type::sync': op_sync(_io.pos)
            'operation_type::viewlock': op_viewlock
            'operation_type::chat': op_chat
            'operation_type::start': op_start(_io.pos)
            'operation_type::postgame': op_postgame

  op_action:
    seq:
      - id: len_action
        type: u4
      - id: action
        size: len_action
        type: action_data
      - id: world_time
        type: u4
        doc: World time in ms at which the action was issued (called sequence in aoc-mgz).

  op_sync:
    params:
      - id: ofs_start
        type: s8
        doc: Absolute position of `time_increment` (passed in so that the look-ahead does not depend on the current stream position).
    seq:
      - id: time_increment
        type: u4
        doc: Milliseconds elapsed since the previous sync. The sum over all syncs is the game duration.
      - id: checksum
        type: sync_checksum(ofs_start + 4)
        if: has_checksum
    instances:
      has_checksum:
        value: ofs_start + 8 <= _io.size.as<s8> and next_u4 == 0
        doc: A checksum block follows if the next u4 is 0 (otherwise it is the next operation type).
      next_u4:
        pos: ofs_start + 4
        type: u4
        if: ofs_start + 8 <= _io.size.as<s8>
  sync_checksum:
    params:
      - id: ofs_start
        type: s8
    seq:
      - id: marker
        contents: [0, 0, 0, 0]
      - id: player_stats
        type: sync_player_stats
        repeat: expr
        repeat-expr: 8
        if: is_de
        doc: |
          DE per-player statistics for player slots 1-8 (see aoc-mgz `fast.sync`, where the
          meaning of the values is marked as a guess). Unused slots are all zero.
      - id: current_time
        type: u4
        if: is_de
        doc: Game time in ms.
      - id: legacy_checksum
        size: 24
        if: not is_de
    instances:
      is_de:
        value: de_flag != 0 or de_fits or not legacy_fits
        doc: |
          DE per-player statistics, or the 24 bytes of earlier versions. The u4 read as `de_flag` (as
          aoc-mgz does) is player 1's fourth statistic, which is 0 when player 1 has no displayable
          objects (an empty slot, or defeated). Then the DE layout is still taken if it fits, and the
          old one only if it doesn't and an operation follows the old one. (Checking only the old
          layout misread recordings where a defeated player 1 still had 1 to 6 objects: that count
          is where the old layout expects the next operation type.)
      de_flag:
        pos: ofs_start + 16
        type: u4
      de_fits:
        value: >-
          (ofs_start + 360 == _io.size.as<s8> or (ofs_start + 364 <= _io.size.as<s8> and op_after_de >= 1 and op_after_de <= 6))
          and (de_slots[0].player_number == 0 or de_slots[0].player_number == 1)
          and (de_slots[1].player_number == 0 or de_slots[1].player_number == 2)
          and (de_slots[2].player_number == 0 or de_slots[2].player_number == 3)
          and (de_slots[3].player_number == 0 or de_slots[3].player_number == 4)
          and (de_slots[4].player_number == 0 or de_slots[4].player_number == 5)
          and (de_slots[5].player_number == 0 or de_slots[5].player_number == 6)
          and (de_slots[6].player_number == 0 or de_slots[6].player_number == 7)
          and (de_slots[7].player_number == 0 or de_slots[7].player_number == 8)
        doc: |
          The DE layout ends at the end of the body or right before an operation, and its slots hold
          the player numbers 1 to 8 in order (0 for an unused slot).
      op_after_de:
        pos: ofs_start + 360
        type: u4
        if: ofs_start + 364 <= _io.size.as<s8>
      de_slots:
        pos: ofs_start + 4
        type: sync_player_stats
        repeat: expr
        repeat-expr: 8
        if: ofs_start + 360 <= _io.size.as<s8>
        doc: The per-player statistics read ahead, for `de_fits`.
      legacy_fits:
        value: ofs_start + 32 <= _io.size.as<s8> and op_after_legacy >= 1 and op_after_legacy <= 6
      op_after_legacy:
        pos: ofs_start + 28
        type: u4
        if: ofs_start + 32 <= _io.size.as<s8>
  sync_player_stats:
    seq:
      - id: unknown0
        type: u4
      - id: total_resources
        type: u4
      - id: unknown2
        type: u4
      - id: num_displayable_objects
        type: u4
      - id: displayable_objects_ttl
        type: u4
      - id: unknown5
        type: u4
      - id: num_objects
        type: u4
      - id: unknown7
        type: u4
      - id: player_number
        type: u4
      - id: unknown9
        type: u4
      - id: unknown10
        type: u4

  op_viewlock:
    seq:
      - id: x
        type: f4
      - id: y
        type: f4
      - id: player_id
        type: u4

  op_chat:
    seq:
      - id: unknown
        type: s4
      - id: len_message
        type: u4
      - id: message
        type: str
        size: len_message
        encoding: UTF-8
        doc: |
          In DE a JSON object such as
          {"player":2,"channel":0,"message":"gg","tauntNumber":-1,"messageAGP":"","destinationMap":12}.

  op_start:
    doc: |
      Recording meta data (aoc-mgz `fast.meta`, aoe2rec `Pregame`) as the first operation of a body.
      `rec_owner` and `reveal_map` were checked against the header in all test recordings; aoe2rec
      names the fields differently (shifted by one).

      The same operation type also turns up later in a body (in about 1 of 700 DE recordings),
      followed by only 8 bytes: an s4 (0 or -1) and a u4 (seen 3, 25, 2306, 2349), meaning unknown.
      aoc-mgz reads nothing after it there.
    params:
      - id: ofs_start
        type: s8
        doc: Absolute position after the operation type (4 for the first operation of a body).
    seq:
      - id: checksum_interval
        type: u4
        if: is_meta
        doc: Number of syncs between two sync checksums (500).
      - id: multiplayer
        type: u4
        if: is_meta
      - id: unknown1
        type: u4
        if: is_meta
      - id: rec_owner
        type: u4
        if: is_meta
        doc: Player number of the recording player (same as header `replay.rec_player`).
      - id: reveal_map
        type: u4
        if: is_meta
        doc: Same value as the header setting `de.reveal_map` (0 = normal, 1 = explored, 2 = all visible).
      - id: unknown2
        type: u4
        if: is_meta
      - id: unknown3
        type: u4
        if: is_meta
      - id: later_unknown1
        type: s4
        if: not is_meta
      - id: later_unknown2
        type: u4
        if: not is_meta
    instances:
      is_meta:
        value: ofs_start == 4

  op_postgame:
    doc: |
      DE post-game data. It occupies the rest of the file and is laid out backwards:
      `[block n data][length n][id n] ... [block 1 data][length 1][id 1][num_blocks][version][trailer]`
      where block 1 is the one closest to the end of the file. Start at `data.last_block` and
      follow `previous_block`.
    seq:
      - id: data
        size-eos: true
        type: postgame_data
  postgame_data:
    instances:
      trailer:
        pos: _io.size - 8
        size: 8
        doc: Constant ce a4 59 b1 05 db 7b 43.
      version:
        pos: _io.size - 12
        type: u4
      num_blocks:
        pos: _io.size - 16
        type: u4
      last_block:
        pos: 0
        type: postgame_block(_io.size - 16, num_blocks)
        if: num_blocks > 0
  postgame_block:
    params:
      - id: ofs_end
        type: s8
        doc: Position right after this block's id field.
      - id: num_remaining
        type: u4
        doc: Number of blocks from this one to the start of the post-game data.
    instances:
      block_type:
        pos: ofs_end - 4
        type: u4
        doc: |
          Enum `postgame_block_type`. (Not typed as the enum: the Go target can't compile an enum
          instance that may fail.)
      len_block:
        pos: ofs_end - 8
        type: u4
      block:
        pos: ofs_end - 8 - len_block.as<s8>
        size: len_block
        type:
          switch-on: block_type.as<s4>
          cases:
            1: postgame_world_time
            2: postgame_leaderboards
            _: postgame_unknown_block
      previous_block:
        pos: 0
        type: postgame_block(ofs_end - 8 - len_block.as<s8>, num_remaining - 1)
        if: num_remaining > 1
  postgame_world_time:
    seq:
      - id: world_time
        type: u4
        doc: Game duration in ms.
  postgame_leaderboards:
    seq:
      - id: num_leaderboards
        type: u4
      - id: leaderboards
        type: postgame_leaderboard
        repeat: expr
        repeat-expr: num_leaderboards
  postgame_leaderboard:
    seq:
      - id: leaderboard_id
        type: u4
        doc: 1 = Deathmatch 1v1, 2 = Deathmatch team, 3 = Random Map 1v1, 4 = Random Map team, 13 = Empire Wars 1v1, 14 = Empire Wars team.
      - id: unknown
        type: u2
      - id: num_players
        type: u4
      - id: players
        type: postgame_leaderboard_player
        repeat: expr
        repeat-expr: num_players
  postgame_leaderboard_player:
    seq:
      - id: player_number
        type: s4
        doc: Player number minus 1.
      - id: rank
        type: s4
      - id: rating
        type: s4
  postgame_unknown_block:
    seq:
      - id: data
        size-eos: true

  action_data:
    doc: One action (player command), parsed in its own sub-stream of `len_action` bytes.
    seq:
      - id: action_type
        type: u1
        enum: action_type
      - id: player_id
        type: u1
        if: _root.is_new_action_format
      - id: len_payload
        type: u2
        if: _root.is_new_action_format
        doc: |
          Declared payload length. Usually equal to the payload size (`_io.size - 4`); `ai_order`
          actions carry additional unit ids beyond it.
      - id: payload
        if: _root.is_new_action_format
        type:
          switch-on: action_type
          cases:
            'action_type::order': action_order
            'action_type::move': action_order
            'action_type::stop': action_selection
            'action_type::de_autoscout': action_selection
            'action_type::ratha_ability': action_selection
            'action_type::de_107_a': action_selection
            'action_type::ai_order': action_ai_order
            'action_type::resign': action_resign
            'action_type::stance': action_stance
            'action_type::guard': action_target_selection
            'action_type::follow': action_target_selection
            'action_type::patrol': action_patrol
            'action_type::de_attack_move': action_patrol
            'action_type::formation': action_formation
            'action_type::de_transform': action_transform
            'action_type::de_multi_gatherpoint': action_multi_gather_point
            'action_type::make': action_make
            'action_type::research': action_research
            'action_type::build': action_build
            'action_type::game': action_game
            'action_type::wall': action_wall
            'action_type::delete': action_object
            'action_type::back_to_work': action_object
            'action_type::gate': action_object
            'action_type::drop_relic': action_object
            'action_type::de_107_b': action_object
            'action_type::attack_ground': action_attack_ground
            'action_type::tribute': action_tribute
            'action_type::repair': action_repair
            'action_type::ungarrison': action_ungarrison
            'action_type::flare': action_flare
            'action_type::special': action_special
            'action_type::gather_point': action_gather_point
            'action_type::sell': action_buy_sell
            'action_type::buy': action_buy_sell
            'action_type::town_bell': action_town_bell
            'action_type::de_queue': action_de_queue
            'action_type::de_tribute': action_de_tribute
            _: action_raw
      - id: legacy_payload
        if: not _root.is_new_action_format
        type:
          switch-on: action_type
          cases:
            'action_type::resign': legacy_action_player
            'action_type::tribute': legacy_action_tribute
            'action_type::buy': legacy_action_player
            'action_type::sell': legacy_action_player
            'action_type::game': legacy_action_game
            _: action_raw
        doc: Action bytes after the type for save versions before 37 (no common header).

  action_raw:
    doc: Undecoded payload (all remaining bytes of the action).
    seq:
      - id: data
        size-eos: true

  action_order:
    doc: order (0, interact with a target) and move (3, target_id -1).
    seq:
      - id: target_id
        type: s4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: num_selected
        type: s2
        doc: Number of selected units; -1 means "same selection as the previous action" (no ids follow).
      - id: unknown1
        type: u2
      - id: unknown2
        size: 2
      - id: unknown_60
        size: 2
        if: _root.save_version >= 6000
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: '(_io.size - (_root.save_version >= 6000 ? 24 : 22).as<s8>) / 4'

  action_selection:
    doc: Payload that is just a selection (stop, autoscout, ...).
    seq:
      - id: num_selected
        type: u4
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 8) / 4

  action_ai_order:
    doc: |
      AI order (also used for automatic scout moves). The meaning of most fields is unknown;
      when more than one unit is ordered, a u4 and the remaining unit ids follow at the end
      (in `rest`, beyond the declared payload length).
    seq:
      - id: num_units
        type: u4
      - id: unit_id
        type: u4
      - id: target_id
        type: s4
      - id: unknown1
        type: u4
      - id: unknown2
        type: u4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: rest
        size-eos: true

  action_resign:
    doc: The resigning player is `action_data.player_id`.
    seq:
      - id: unknown1
        size-eos: true

  action_stance:
    seq:
      - id: num_selected
        type: u4
      - id: stance
        type: u4
        enum: stance
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 12) / 4

  action_target_selection:
    doc: guard (19) and follow (20).
    seq:
      - id: num_selected
        type: u4
      - id: target_id
        type: u4
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 12) / 4

  action_patrol:
    doc: patrol (21) and attack move (33), with up to 10 waypoints.
    seq:
      - id: num_selected
        type: u4
      - id: num_waypoints
        type: u2
        doc: Presumably the number of used waypoints (1 in most recordings).
      - id: unknown1
        size: 2
      - id: x
        type: f4
        repeat: expr
        repeat-expr: 10
      - id: y
        type: f4
        repeat: expr
        repeat-expr: 10
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 92) / 4

  action_formation:
    seq:
      - id: num_selected
        type: u4
      - id: formation
        type: u4
        enum: formation
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 12) / 4

  action_transform:
    seq:
      - id: object_id
        type: u4
      - id: unknown1
        type: u4

  action_multi_gather_point:
    seq:
      - id: target_id
        type: s4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: rest
        size-eos: true

  action_make:
    seq:
      - id: building_id
        type: u4
      - id: unknown1
        type: s4
      - id: unit_type
        type: u4
        doc: Unit type id (e.g. 83 = villager).

  action_research:
    seq:
      - id: building_id
        type: u4
      - id: num_selected
        type: s2
      - id: technology_id
        type: s2
      - id: unknown1
        size: 5
      - id: building_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 17) / 4

  action_build:
    seq:
      - id: num_selected
        type: s2
      - id: unknown1
        type: u2
      - id: x
        type: f4
      - id: y
        type: f4
      - id: building_type
        type: u4
        doc: Unit type id of the building (e.g. 70 = house, 68 = mill, 562 = lumber camp).
      - id: unknown2
        size: 8
      - id: unknown3
        type: s2
      - id: unknown4
        type: u1
      - id: unknown5
        type: u1
      - id: builder_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 32) / 4

  action_game:
    doc: Game command (diplomacy, speed, farm / fish trap queue, ...).
    seq:
      - id: command
        type: u2
        enum: game_command
      - id: unknown1
        type: u2
      - id: command_player_id
        type: s2
      - id: params
        type:
          switch-on: command
          cases:
            'game_command::diplomacy': game_diplomacy
            'game_command::speed': game_speed
            'game_command::queue_farm': game_count
            'game_command::unqueue_farm': game_count
            'game_command::queue_fish_trap': game_count
            'game_command::unqueue_fish_trap': game_count
            _: action_raw
  game_diplomacy:
    seq:
      - id: target_player_id
        type: s2
      - id: stance_float
        type: f4
      - id: stance
        type: u1
        doc: 0 = ally, 1 = neutral, 3 = enemy.
      - id: rest
        size-eos: true
  game_speed:
    seq:
      - id: unknown1
        type: s2
      - id: speed
        type: f4
      - id: rest
        size-eos: true
  game_count:
    seq:
      - id: number
        type: s2
      - id: rest
        size-eos: true

  action_wall:
    seq:
      - id: num_selected
        type: u4
      - id: x_start
        type: u2
      - id: y_start
        type: u2
      - id: x_end
        type: u2
      - id: y_end
        type: u2
      - id: building_type
        type: u4
      - id: unknown1
        size: 8
      - id: builder_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 28) / 4

  action_object:
    doc: Payload with a single object id (delete, back to work, gate, drop relic, ...).
    seq:
      - id: object_id
        type: u4

  action_attack_ground:
    seq:
      - id: num_selected
        type: u4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: unknown1
        size: 4
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 20) / 4

  action_tribute:
    doc: Tribute of a single resource (108).
    seq:
      - id: amount
        type: f4
      - id: fee
        type: f4
      - id: resource
        type: u1
        enum: resource
      - id: unknown1
        type: u1
      - id: target_player_id
        type: u1

  action_repair:
    seq:
      - id: num_selected
        type: u4
      - id: target_id
        type: u4
      - id: unknown1
        size: 4
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: (_io.size - 16) / 4

  action_ungarrison:
    seq:
      - id: num_selected
        type: u4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: target_id
        type: s4
      - id: unknown1
        type: u4
      - id: unknown_66_3
        type: u1
        if: _root.save_version >= 6630
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: '(_io.size - (_root.save_version >= 6630 ? 25 : 24).as<s8>) / 4'

  action_flare:
    seq:
      - id: unknown1
        type: s4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: num_receivers
        type: u1
      - id: receivers
        type: u1
        repeat: expr
        repeat-expr: num_receivers
        doc: One flag per player (index 0 = Gaia), set if the player sees the flare.

  action_special:
    doc: Special order (117), e.g. garrison, pack / unpack trebuchet, unqueue.
    seq:
      - id: num_selected
        type: u4
      - id: target_id
        type: s4
      - id: x
        type: f4
      - id: y
        type: f4
      - id: unknown1
        type: s4
      - id: unknown2
        type: u4
      - id: order
        type: u1
        enum: special_order
      - id: unknown3
        size: '_root.save_version >= 6150 ? 4 : 3'
      - id: object_ids
        type: u4
        repeat: expr
        repeat-expr: '(_io.size - (_root.save_version >= 6150 ? 33 : 32).as<s8>) / 4'

  action_gather_point:
    seq:
      - id: num_selected
        type: s2
      - id: unknown1
        type: u2
      - id: x
        type: f4
      - id: y
        type: f4
      - id: target_id
        type: s4
      - id: target_type
        type: s4
      - id: unknown_63
        type: u1
        if: _root.save_version >= 6300
      - id: building_ids
        type: u4
        repeat: expr
        repeat-expr: '(_io.size - (_root.save_version >= 6300 ? 25 : 24).as<s8>) / 4'

  action_buy_sell:
    doc: buy (123) and sell (122) at the market.
    seq:
      - id: resource
        type: s2
        enum: resource
      - id: amount
        type: s2
        doc: Number of 100-unit lots.
      - id: market_id
        type: u4

  action_town_bell:
    seq:
      - id: building_id
        type: u4
      - id: active
        type: u1

  action_de_queue:
    doc: Unit queue (129).
    seq:
      - id: num_selected
        type: s2
      - id: unknown1
        size: 4
      - id: building_type
        type: s2
      - id: unit_type
        type: s2
        doc: Unit type id (e.g. 83 = villager, 4 = archer).
      - id: amount
        type: s2
      - id: unknown_66_3
        type: u4
        if: _root.save_version >= 6630
      - id: building_ids
        type: u4
        repeat: expr
        repeat-expr: '(_io.size - (_root.save_version >= 6630 ? 20 : 16).as<s8>) / 4'

  action_de_tribute:
    doc: Tribute of several resources at once (196).
    seq:
      - id: amounts
        type: f4
        repeat: expr
        repeat-expr: 4
        doc: Amounts, in the order given by `resources`.
      - id: fees
        type: f4
        repeat: expr
        repeat-expr: 4
      - id: resources
        type: u2
        enum: resource
        repeat: expr
        repeat-expr: 4
      - id: target_player_id
        type: u1

  legacy_action_player:
    doc: Pre-37 resign, buy and sell actions, which start with the player id.
    seq:
      - id: player_id
        type: u1
      - id: rest
        size-eos: true
  legacy_action_tribute:
    seq:
      - id: player_id
        type: u1
      - id: target_player_id
        type: u1
      - id: resource
        type: u1
        enum: resource
      - id: amount
        type: f4
      - id: fee
        type: f4
      - id: rest
        size-eos: true
  legacy_action_game:
    seq:
      - id: command
        type: u1
        enum: game_command
      - id: player_id
        type: u1
      - id: rest
        size-eos: true

enums:
  operation_type:
    1: action
    2: sync
    3: viewlock
    4: chat
    5: start
    6: postgame
  postgame_block_type:
    1: world_time
    2: leaderboards
  action_type:
    0: order
    1: stop
    2: work
    3: move
    4: create
    5: add_attribute
    6: give_attribute
    10: ai_order
    11: resign
    15: spectate
    16: add_waypoint
    18: stance
    19: guard
    20: follow
    21: patrol
    23: formation
    27: save
    31: group_multi_waypoints
    32: chapter
    33: de_attack_move
    34: hd_unknown_34
    35: de_retreat
    37: de_unknown_37
    38: de_autoscout
    39: de_unknown_39
    40: de_unknown_40
    41: de_transform
    43: ratha_ability
    44: de_107_a
    45: de_multi_gatherpoint
    46: de_unknown_46
    53: ai_command
    80: de_unknown_80
    100: make
    101: research
    102: build
    103: game
    104: de_unknown_104
    105: wall
    106: delete
    107: attack_ground
    108: tribute
    109: de_unknown_109
    110: repair
    111: ungarrison
    112: multiqueue
    114: gate
    115: flare
    117: special
    119: queue
    120: gather_point
    122: sell
    123: buy
    126: drop_relic
    127: town_bell
    128: back_to_work
    129: de_queue
    130: de_unknown_130
    131: de_unknown_131
    134: de_unknown_134
    135: de_unknown_135
    136: de_unknown_136
    137: de_unknown_137
    138: de_unknown_138
    140: de_107_b
    141: de_unknown_141
    196: de_tribute
    255: postgame
  game_command:
    0: diplomacy
    1: speed
    2: instant_build
    4: quick_build
    5: allied_victory
    6: cheat
    9: unknown_9
    10: spies
    11: strategic_number
    13: queue_farm
    14: unqueue_farm
    16: farm_autoqueue
    17: queue_fish_trap
    18: unqueue_fish_trap
    19: fish_trap_autoqueue
    20: default_stance
  stance:
    0: aggressive
    1: defensive
    2: stand_ground
    3: no_attack
  formation:
    2: line
    4: box
    7: staggered
    8: flank
  special_order:
    1: pack
    2: unpack
    4: unqueue
    5: garrison
    6: unknown_6
    7: unknown_7
    8: unknown_8
  resource:
    0: food
    1: wood
    2: stone
    3: gold
