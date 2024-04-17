meta:
  id: save_game
  file-extension: aoe2record
  endian: le
seq:
  - id: header_length
    type: u8
  - id: header
    size: header_length - 8
  - id: body_a
    type: body
#    type: header
#    process: zlib
#    size: header_length - 8
types:
  header:
    seq:
      - id: game_version
        type: strz
        size: 8
        encoding: ASCII
  body:
    seq:
      - id: actions
        type: action
        repeat: eos
  action:
    seq:
      - id: action_id
        type: u4
        enum: action_type
      - id: action_body
        type:
          switch-on: action_id
          cases:
            'action_type::action': action_action
            'action_type::sync': action_sync
#            'action_type::viewlock': action_viewlock
#            'action_type::chat': action_chat
#            'action_type::start': action_start
#            'action_type::save': action_save
  action_sync:
    seq:
      - id: length
        type: u4
    instances:
      marker:
        type: u4
        pos: _io.pos + 4

  action_save:
    seq:
      - id: length
        type: u4

  action_action:
    seq:
      - id: length
        type: u4
      - id: action_id
        type: u1
      - id: action_bytes
        type: u1
        repeat: expr
        repeat-expr: length - 1
enums:
  action_type:
    1: action
    2: sync
    3: viewlock
    4: chat
    5: start
    6: save
instances:
  header_length_i:
    pos: 0
    type: u8
  body:
    pos: header_length_i
    type: body