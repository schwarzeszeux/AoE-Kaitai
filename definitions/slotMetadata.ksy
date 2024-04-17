meta:
  id: slot_metadata
  endian: le
doc: |
  Decodes the "slotInfo" field returned by https://aoe-api.reliclink.com/community/advertisement/findAdvertisements
seq:
  - id: unknown
    type: u1
  - id: kvps
    type: kvp
    repeat: eos
    doc: |
      List of key value pairs
      (Not sure if the first entry is in fact key/value or not)
types:
  kvp:
    seq:
      - id: key_length
        type: u4
      - id: key
        type: str
        size: key_length
        encoding: UTF-8
      - id: value_length
        type: u4
      - id: value
        type: str
        size: value_length
        encoding: UTF-8