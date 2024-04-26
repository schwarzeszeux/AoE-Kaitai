meta:
  id: save_game
  file-extension: aoe2record
  endian: le
  imports:
   - common
   - replay_header
seq:
  - id: header_length
    type: u4
  - id: next_pos
    type: u4
  - id: header
    size: header_length - 8
    process: zlib_headerless
    type: t_header
#    size: header_length - 8
types:
  t_body:
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
    type: u4
  body:
    pos: header_length_i
    type: t_body