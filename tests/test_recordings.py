"""Reads every recording listed in recordings/expected.json with the generated Python parser, completely,
and compares it with the expected values. The recordings are games that a version of the definitions
failed to read ("broke" says how).

Build the parser first, then run pytest with its directory in AOE2RECORD_PARSER:

    scripts/build.sh python build/python
    AOE2RECORD_PARSER=build/python pytest tests
"""
import gzip
import json
import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.environ.get("AOE2RECORD_PARSER", os.path.join(HERE, "..", "build", "python"))))

from aoe2record import Aoe2record  # noqa: E402
from aoe2record_body import Aoe2recordBody  # noqa: E402

RECORDINGS = os.path.join(HERE, "recordings")
CASES = json.load(open(os.path.join(RECORDINGS, "expected.json"), encoding="utf-8"))


@pytest.mark.parametrize("case", CASES, ids=[case["file"] for case in CASES])
def test_reads_whole_recording(case):
    with gzip.open(os.path.join(RECORDINGS, case["file"])) as file:
        recording = Aoe2record.from_bytes(file.read())

    operations = [operation for chapter in recording.chapters for operation in chapter.body.operations]
    assert recording.chapters[0].header.is_de
    assert len(operations) == case["operations"]
    assert sum(isinstance(operation.data, Aoe2recordBody.OpChat) for operation in operations) == case["chats"]

    # the game time of the syncs only adds up to the post-game world time if no operation was read with
    # the wrong length
    postgame = operations[-1].data
    assert isinstance(postgame, Aoe2recordBody.OpPostgame)
    world_time = None
    block = postgame.data.last_block
    while block is not None:
        if isinstance(block.block, Aoe2recordBody.PostgameWorldTime):
            world_time = block.block.world_time
        block = block.previous_block
    assert world_time == case["worldTime"]
    assert sum(operation.data.time_increment for operation in operations
               if isinstance(operation.data, Aoe2recordBody.OpSync)) == case["worldTime"]
