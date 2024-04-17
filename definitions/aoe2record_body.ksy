meta:
  id: save_game_body
  file-extension: aoe2record
  endian: le
seq:
  - id: header_length
    type: u8
  - id: header
    type: u1
    repeat: expr
    repeat-expr: header_length - 8
  - id: body
    type: action
types:
  action:
    seq:
      - 

enums:
  action_type:
    1: action
    2: sync
    3: viewlock
    4: chat
    5: start
    6: save