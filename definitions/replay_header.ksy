meta:
  id: header
  file-extension: header
  endian: le
seq:
    - id: game_version
      type: strz
      size: 8
      encoding: ASCII
    - id: save_version_f
      type: f4
    - id: build
      type: u4
    - id: version
      type: f4
    - id: game_info
      type: game_info_t
    - id: ai
      type: ai_t
    - id: replay
      type: replay_t
    - id: map_info
      type: map_info_t
    - id: initial
      type: initial_t
      doc: |
        Initial state of all players (including Gaia)
instances:
  save_version:
    value: (save_version_f * 100).to_i + 1
  game:
    value: 'game_version == "VER 9.3\0" ? 
      1 :
      game_version == "VER 9.4" ? save_version >= 1297 ? 21 : save_version >= 1236 ? 19 : 4 :
      game_version == "VER 9.8" ? 
      12 :
      game_version == "VER 9.9" ? 
      13 :
      game_version == "VER 9.A" ? 
      22 :
      ((game_version == "VER 9.B") or (game_version == "VER 9.C") or (game_version == "VER 9.D")) ? 
      11 :
      ((game_version == "VER 9.E") or (game_version == "VER 9.F")) ?
      20 :
      game_version == "MCP 9.F" ?
      30 :
      -1'
types:
  initial_t:
    seq:
      - id: restore_time
        type: u4
        doc: |
          Time of restore, 0 if the game was not restored
      - id: num_particles
        type: u4
      - id: particles
        type: u4
        repeat: expr
        repeat-expr: num_particles * 27
      - id: identifier
        type: u4
      - id: players
        type: player_initial
        repeat: expr
        repeat-expr: _root.replay.num_players
  player_initial:
    seq:
      - id: type
        type: u1
      - id: unknown
        type: u1
#      - id: attributes
#        type: attributes
  player_attributes:
    seq:
      - id: foreign_diplomacy
        type: u1
        repeat: expr
        repeat-expr: _root.replay.num_players
      - id: my_diplomacy
        type: s4
      - id: allied_los
        type: u4
      - id: allied_victory
        type: b1
      - id: player_name_length
        type: u2
      - id: player_name
        type: strz
        size: player_name_length
        encoding: UTF-8
      - id: magic
        content: [0x00, 0x16]
      - id: num_header_data
        type: u4
      - id: magic2
        content: [0x21]

  player_stats_t:
    seq:
      

    - id: resources
      type: resources
    - id: headroom
      type: f4
    - id: conversion_range
      type: f4
    - id: current_age
      type: f4
    - id: num_relics
      type: f4
    - id: trade_bonus
      type: f4
    - id: trade_goods
      type: f4
    - id: trade_production
      type: f4
    - id: pop_current
      type: f4
    - id: decay
      type: f4
    - id: discovery
      type: f4
    - id: ruins
      type: f4
    - id: meat
      type: f4
    - id: berries
      type: f4
    - id: fish
      type: f4
    - id: u10
      type: f4
    - id: total_units_created
      type: f4
    - id: num_kills
      type: f4
    - id: num_items_researched
      type: f4
    - id: percent_map_explored
      type: f4
    - id: castle_age
      type: f4
    - id: imperial_age
      type: f4
    - id: feudal_age
      type: f4
    - id: u14
      type: f4
    - id: convert_priests
      type: f4
    - id: convert_buildings
      type: f4
    - id: u17
      type: f4
    - id: building_limit
      type: f4
    - id: food_limit
      type: f4
    - id: pop_max
      type: f4
    - id: maintenance
      type: f4
    - id: faith
      type: f4
    - id: faith_recharge_rate
      type: f4
    - id: farm_food_amount
      type: f4
    - id: civilian_pop
      type: f4
    - id: u23
      type: f4
    - id: all_techs_achieved
      type: f4
    - id: military_pop
      type: f4
    - id: conversions
      type: f4
    - id: num_wonders
      type: f4
    - id: razings
      type: f4
    - id: kill_ratio
      type: f4
    - id: player_killed
      type: f4
    - id: tribute_inefficiency
      type: f4
    - id: gold_bonus_mining_productivity
      type: f4
    - id: town_center_unavailable
      type: f4
    - id: total_gold_gathered_2
      type: f4
    - id: has_cartography
      type: f4
    - id: houses_count
      type: f4
    - id: monasteries
      type: f4
    - id: total_resources_tributed
      type: f4
    - id: hold_ruins
      type: f4
    - id: hold_relics
      type: f4
    - id: ore
      type: f4
    - id: captured_unit
      type: f4
    - id: dark_age
      type: f4
    - id: trade_good_quality
      type: f4
    - id: trade_market_level
      type: f4
    - id: formations
      type: f4
    - id: building_housing_rate
      type: f4
    - id: gather_tax_rate
      type: f4
    - id: gather_accumulator
      type: f4
    - id: decay_rate
      type: f4
    - id: allow_formations
      type: f4
    - id: can_convert
      type: f4
    - id: hit_points_killed
      type: f4
    - id: p1_kills
      type: f4
    - id: p2_kills
      type: f4
    - id: p3_kills
      type: f4
    - id: p4_kills
      type: f4
    - id: p5_kills
      type: f4
    - id: p6_kills
      type: f4
    - id: p7_kills
      type: f4
    - id: p8_kills
      type: f4
    - id: convert_resistance
      type: f4
    - id: trade_fee
      type: f4
    - id: stone_mining_productivity
      type: f4
    - id: num_units_queued
      type: f4
    - id: num_units_making
      type: f4
    - id: raider
      type: f4
    - id: boarding_recharge_rate
      type: f4
    - id: starting_villagers
      type: f4
    - id: research_cost_mod
      type: f4
    - id: research_time_mod
      type: f4
    - id: convert_boats
      type: f4
    - id: fish_trap_food
      type: f4
    - id: heal_rate_modifier
      type: f4
    - id: heal_range
      type: f4
    - id: food_bonus
      type: f4
    - id: wood_bonus
      type: f4
    - id: stone_bonus
      type: f4
    - id: gold_bonus
      type: f4
    - id: raider_ability
      type: f4
    - id: berserker_heal_timer
      type: f4
    - id: dominant_sheep_control
      type: f4
    - id: object_cost_summation
      type: f4
    - id: research_cost_summation
      type: f4
    - id: relic_income_summation
      type: f4
    - id: trade_income_summation
      type: f4
    - id: p1_tributed_to
      type: f4
    - id: p2_tributed_to
      type: f4
    - id: p3_tributed_to
      type: f4
    - id: p4_tributed_to
      type: f4
    - id: p5_tributed_to
      type: f4
    - id: p6_tributed_to
      type: f4
    - id: p7_tributed_to
      type: f4
    - id: p8_tributed_to
      type: f4
    - id: p1_unit_kill_worth
      type: f4
    - id: p2_unit_kill_worth
      type: f4
    - id: p3_unit_kill_worth
      type: f4
    - id: p4_unit_kill_worth
      type: f4
    - id: p5_unit_kill_worth
      type: f4
    - id: p6_unit_kill_worth
      type: f4
    - id: p7_unit_kill_worth
      type: f4
    - id: p8_unit_kill_worth
      type: f4
    - id: p1_num_razes
      type: f4
    - id: p2_num_razes
      type: f4
    - id: p3_num_razes
      type: f4
    - id: p4_num_razes
      type: f4
    - id: p5_num_razes
      type: f4
    - id: p6_num_razes
      type: f4
    - id: p7_num_razes
      type: f4
    - id: p8_num_razes
      type: f4
    - id: p1_raze_worth
      type: f4
    - id: p2_raze_worth
      type: f4
    - id: p3_raze_worth
      type: f4
    - id: p4_raze_worth
      type: f4
    - id: p5_raze_worth
      type: f4
    - id: p6_raze_worth
      type: f4
    - id: p7_raze_worth
      type: f4
    - id: p8_raze_worth
      type: f4
    - id: num_castles
      type: f4
    - id: num_wonders
      type: f4
    - id: kills_by_p1
      type: f4
    - id: kills_by_p2
      type: f4
    - id: kills_by_p3
      type: f4
    - id: kills_by_p4
      type: f4
    - id: kills_by_p5
      type: f4
    - id: kills_by_p6
      type: f4
    - id: kills_by_p7
      type: f4
    - id: kills_by_p8
      type: f4
    - id: razings_by_p1
      type: f4
    - id: razings_by_p2
      type: f4
    - id: razings_by_p3
      type: f4
    - id: razings_by_p4
      type: f4
    - id: razings_by_p5
      type: f4
    - id: razings_by_p6
      type: f4
    - id: razings_by_p7
      type: f4
    - id: razings_by_p8
      type: f4
    - id: value_killed_by_others
      type: f4
    - id: value_razed_by_others
      type: f4
    - id: kills
      type: f4
    - id: losses
      type: f4
    - id: p1_tribute_recvd
      type: f4
    - id: p2_tribute_recvd
      type: f4
    - id: p3_tribute_recvd
      type: f4
    - id: p4_tribute_recvd
      type: f4
    - id: p5_tribute_recvd
      type: f4
    - id: p6_tribute_recvd
      type: f4
    - id: p7_tribute_recvd
      type: f4
    - id: p8_tribute_recvd
      type: f4
    - id: current_unit_worth
      type: f4
    - id: current_building_worth
      type: f4
    - id: total_food_gathered
      type: f4
    - id: total_wood_gathered
      type: f4
    - id: total_stone_gathered
      type: f4
    - id: total_gold_gathered
      type: f4
    - id: total_kill_and_raze_worth
      type: f4
    - id: total_tribute_recvd
      type: f4
    - id: total_value_of_razings
      type: f4
    - id: castle_high
      type: f4
    - id: wonder_high
      type: f4
    - id: total_tribute_sent
      type: f4
    - id: convert_min_adj
      type: f4
    - id: convert_max_adj
      type: f4
    - id: convert_resist_min_adj
      type: f4
    - id: convert_resist_max_adj
      type: f4
    - id: convert_building_min
      type: f4
    - id: convert_building_max
      type: f4
    - id: convert_building_chance
      type: f4
    - id: spies
      type: f4
    - id: value_wonders_castles
      type: f4
    - id: food_score
      type: f4
    - id: wood_score
      type: f4
    - id: stone_score
      type: f4
    - id: gold_score
      type: f4
    - id: player_bonus
      type: player_bonus_t
      if: _root.save_version >= 1176
    # - id: additional_data
    #   type: f4
    #   if: 

  player_bonus_t:
    seq:
      - id: wood_bonus0
        type: f4
      - id: food_bonus0
        type: f4
      - id: relic_rate
        type: f4
      - id: heresy
        type: f4
      - id: theocracy
        type: f4
      - id: crenellations
        type: f4
      - id: construction_rate_mod
        type: f4
      - id: hun_wonder_bonus
        type: f4
      - id: spies_discount
        type: f4
      

  resources:
    seq:
      - id: food
        type: f4
      - id: wood
        type: f4
      - id: stone
        type: f4
      - id: gold
        type: f4

  map_info_t:
    instances:
      num_tiles_de:
        value: size_x * size_y
    seq:
      - id: size_x
        type: u4
      - id: size_y
        type: u4
      - id: num_zones
        type: u4
      - id: zones
        type: zone
        repeat: expr
        repeat-expr: num_zones
      - id: all_visible
        type: u1
      - id: fog_of_war
        type: u1
      - id: tiles_de
        type: tile_de
        repeat: expr
        repeat-expr: num_tiles_de
        if: _root.game == 21
        # todo: add non de tiles
      - id: num_data
        type: u4
      - id: padding
        type: u4
        repeat: expr
        repeat-expr: num_data + 1
      - id: couple
        type: couple
        repeat: expr
        repeat-expr: num_data
      - id: size_x_2
        type: u4
      - id: size_y_2
        type: u4
      - id: visibility_map
        type: u4
        repeat: expr
        repeat-expr: num_tiles_de
  couple:
    seq:
      - id: num_obstructions
        type: u4
      - id: unknown
        type: u1
        repeat: expr
        repeat-expr: num_obstructions * 8
  tile_de:
    seq:
      - id: terrain_type
        type: u1
      - id: terrain_type_2
        type: u1
      - id: elevation
        type: u1
      - id: unknown_1
        type: s2
      - id: unknown_2
        type: s2
      - id: unknown_3
        type: s2
        if: _root.save_version >= 1303 # ?
  zone:
    seq:
      - id: padding_de
        type: u1
        repeat: expr
        repeat-expr: 2048 + _parent.num_tiles_de * 2
        if: _root.game == 21
      - id: padding_hd
        type: u1
        repeat: expr
        repeat-expr: 1275 + _parent.num_tiles_de
        if: _root.game == 19
      - id: num_floats
        type: u4
      - id: padding
        type: f4
        repeat: expr
        repeat-expr: num_floats + 1

  replay_t:
    seq:
      - id: old_time
        type: u4
      - id: world_time
        type: u4
      - id: old_world_time
        type: u4
      - id: game_speed_id
        type: u4
      - id: world_time_delta_seconds
        type: u4
      - id: timer
        type: f4
      - id: game_speed_float
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
      - id: num_players
        type: u1
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
        repeat-expr: 9
      - id: padding
        type: u1
        repeat: expr
        repeat-expr: 9
        if: _root.game == 21
  ai_t:
    seq:
      - id: has_ai
        type: u1
      - id: ai_data
        type: ai_data
        if: has_ai > 0
  ai_data:
    seq:
      - id: ai_de
        type: u1
        repeat: until
        repeat-until: _ == 0
  game_info_t:
    seq:
      - id: internal_version
        type: u4
      - id: game_options_version
        type: u4
      - id: num_dlc_ids
        type: u4
      - id: dlc_ids
        type: u4
        repeat: expr
        repeat-expr: num_dlc_ids
      - id: dataset_ref
        type: u4
      - id: difficulty
        type: u4
        enum: difficulty
      - id: selected_map_id
        type: u4
      - id: resolved_map_id
        type: u4
      - id: reveal_map
        type: u4
      - id: victory_type
        type: u4
        enum: victory_type
      - id: starting_resources
        type: u4
        enum: starting_resources
      - id: starting_age
        type: u4
        enum: age
      - id: ending_age
        type: u4
        enum: age
      - id: game_type
        type: u4
      - id: separator
        type: separator
        repeat: expr
        repeat-expr: 2
      - id: speed
        type: f4
      - id: treaty_length
        type: u4
      - id: population_limit
        type: u4
      - id: num_players
        type: u4
      - id: unused_player_color
        type: u4
      - id: victory_amount
        type: u4
      - id: x
        type: separator
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
        if: _root.save_version > 1334
      - id: battle_royale_time
        type: u4
        if: _root.save_version > 1334
      - id: handicap
        type: u1
        if: _root.save_version > 2506
      - id: x1
        type: separator
      - id: players
        type: player
        repeat: expr
        repeat-expr: 8
      - id: x2
        type: u1
        repeat: expr
        repeat-expr: 9
      - id: fog_of_war
        type: u1
      - id: cheat_notifications
        type: u1
      - id: colored_chat
        type: u1
      - id: x3
        type: separator
      - id: ranked
        type: u1
      - id: allow_specs
        type: u1
      - id: lobby_visibility
        type: u4
      - id: hidden_civs
        type: u1
      - id: matchmaking
        type: u1
      - id: spec_delay
        type: u4
      - id: scenario_civ
        type: u1
        if : _root.save_version >= 1313
      - id: rms_crc
        type: u1
        repeat: expr
        repeat-expr: 4
        if : _root.save_version >= 1313
      - id: strings
        type: kvp
        repeat: expr
        repeat-expr: 23
      - id: strategic_numbers
        type: s4
        repeat: expr
        repeat-expr: strings[22].nums[1]
      - id: num_ai_files
        type: u8
      - id: ai_files
        type: ai_file
        repeat: expr
        repeat-expr: num_ai_files
      - id: x4
        type: u1
        repeat: expr
        repeat-expr: 8
        if: _root.save_version >= 2502
      - id: guid
        type: u1
        repeat: expr
        repeat-expr: 16
      - id: lobby_name
        type: string
      - id: x5
        type: u1
        repeat: expr
        repeat-expr: 8
        if: _root.save_version >= 2502
      - id: x6
        type: u1
        repeat: expr
        repeat-expr: 19
        if: _root.save_version >= 2502
      - id: x7
        type: u1
        repeat: expr
        repeat-expr: 5
        if: _root.save_version >= 1313
      - id: x8
        type: u1
        repeat: expr
        repeat-expr: 9
        if: _root.save_version >= 1317
      - id: x9
        type: u1
        repeat: expr
        repeat-expr: 1
        if: _root.save_version >= 2006
      - id: x10
        type: u1
        repeat: expr
        repeat-expr: 8
        if: _root.save_version >= 2016
      - id: x11
        type: u1
        repeat: expr
        repeat-expr: 21
        if: _root.save_version >= 2506
      - id: x12
        type: u1
        repeat: expr
        repeat-expr: 8
        if: _root.save_version > 2519
      - id: unknown
        type: string
      - id: x13
        type: u1
        repeat: expr
        repeat-expr: 5
        if: _root.save_version >= 1313
      - id: x14
        type: unknown_type1
        if: _root.save_version < 1313
      - id: x15
        type: u1
        repeat: expr
        repeat-expr: 5
        if: _root.save_version >= 1317
  unknown_type1:
    seq:
      - id: unknown_string
        type: string
      - id: unknown_number
        type: u4
      - id: unknown_bytes
        type: u1
        repeat: expr
        repeat-expr: 4
  ai_file:
    seq:
      - id: header
        type: u1
        repeat: expr
        repeat-expr: 4
      - id: name
        type: string
      - id: footer
        type: u1
        repeat: expr
        repeat-expr: 6
  kvp:
    seq:
      - id: key
        type: string
      - id: nums
        type: u4
        repeat: until
        repeat-until:
          _ != 3 and _ != 21 and _ != 23 and _ != 42 and _ != 44 and _ != 45 and _ != 46 and _ != 47
  string:
    seq:
      - id: magic
        contents: [0x60, 0x0A]
      - id: length
        type: u2
      - id: value
        type: str
        size: length
        encoding: ASCII
  player:
    seq:
      - id: dlc_id
        type: u4
      - id: color_id
        type: s4
        enum: color
      - id: selected_color
        type: u1
      - id: selected_team_id
        type: u1
      - id: resolved_team_id
        type: u1
      - id: dat_crc
        type: u1
        repeat: expr
        repeat-expr: 8
      - id: mp_game_version
        type: u1
      - id: civ_id
        type: u4
      - id: ai_type
        type: string
      - id: ai_civ_name_index
        type: u1
      - id: ai_name
        type: string
      - id: name
        type: string
      - id: type
        type: u4
        enum: player_type
      - id: profile_id
        type: u4
      - id: magic
        contents: [0,0,0,0]
      - id: player_number
        type: s4
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
      - id: handicap
        type: u1
        repeat: expr
        repeat-expr: 8
        if: _root.save_version >= 2506
      
      
        
  separator:
    seq:
      - id: sep
        contents: [0xA3, 0x5F, 0x02, 0x00]
enums:
  foreign_diplomacy:
    0: ally_or_self
    3: enemy
    4: treaty
  color:
    0: blue
    1: red
    2: green
    3: yellow
    4: teal
    5: pink
    6: gray
    7: orange
  player_type:
    0: absent
    1: closed
    2: human
    3: eliminated
    4: computer
    5: cyborg
    6: spectator
  age:
    -2: unknown
    -1: unset
    0: dark
    1: feudal
    2: castle
    3: imperial
    4: postimperial
    5: dmpostimperial
    
  starting_resources:
    -1: none
    0: standard
    1: low
    2: medium
    3: high
    4: unknown1
    5: unknown2
    6: unknown3
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
  difficulty:
    0: hardest
    1: hard
    2: moderate
    3: standard
    4: easiest
    5: extreme
    6: unknown