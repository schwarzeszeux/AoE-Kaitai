meta:
  id: game_info
  endian: le
  imports:
   - common
doc: |
  Decodes the "option" field returned by https://aoe-api.reliclink.com/community/advertisement/findAdvertisements

  Note: a lot of enum values are missing here!
seq:
  - id: unknown
    type: u1
  - id: kvps
    type: kvp
    repeat: eos
types:
  kvp:
    seq:
      - id: length
        type: u4
      - id: key
        type: str
        terminator: 0x3a
        encoding: UTF-8
      - id: value
        type: str
        size: length - key.length -1
        encoding: UTF-8
    instances:
      key_type:
        value: key.to_i
        enum: keys
        
enums:
  keys:
    0: starting_age
    5: ending_age
    6: game_mode
    9: map_size
    29: population
    38: resource
    42: game_speed
    58: treaty_length
    62: ai_difficulty
    67: lock_teams
    81: victory_time
    82: victory_type
    83: reveal_map