// Reads every recording listed in expected.json with the generated JavaScript parser, completely, and
// compares it with the expected values (see tests/test_recordings.py).
// Usage: node tests/javascript/check.js <dir from scripts/build.sh javascript, after npm install> tests/recordings
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { createRequire } = require('module');

const parserDir = path.resolve(process.argv[2]);
const directory = path.resolve(process.argv[3]);
const requireParser = createRequire(path.join(parserDir, 'package.json'));
const KaitaiStream = requireParser('kaitai-struct/KaitaiStream');
const { Aoe2record } = requireParser('./Aoe2record');
const { Aoe2recordBody } = requireParser('./Aoe2recordBody');

const cases = JSON.parse(fs.readFileSync(path.join(directory, 'expected.json'), 'utf8'));
let failed = 0;

for (const expected of cases) {
  const file = expected.file;
  try {
    const recording = new Aoe2record(new KaitaiStream(zlib.gunzipSync(fs.readFileSync(path.join(directory, file)))));
    const operations = recording.chapters.flatMap((chapter) => chapter.body.operations);
    let chats = 0;
    let syncTime = 0;
    for (const operation of operations) {
      if (operation.data instanceof Aoe2recordBody.OpChat) chats++;
      if (operation.data instanceof Aoe2recordBody.OpSync) syncTime += operation.data.timeIncrement;
    }
    let worldTime = null;
    const last = operations[operations.length - 1].data;
    if (last instanceof Aoe2recordBody.OpPostgame) {
      for (let block = last.data.lastBlock; block; block = block.previousBlock) {
        if (block.block instanceof Aoe2recordBody.PostgameWorldTime) worldTime = block.block.worldTime;
      }
    }

    const got = `${operations.length} operations, ${chats} chats, world time ${worldTime}, sync time ${syncTime}`;
    const want = `${expected.operations} operations, ${expected.chats} chats, world time ${expected.worldTime}, sync time ${expected.worldTime}`;
    if (got === want && recording.chapters[0].header.isDe) {
      console.log(`${file}: ok`);
    } else {
      failed++;
      console.log(`${file}: FAILED, got ${got}, expected ${want}`);
    }
  } catch (e) {
    failed++;
    console.log(`${file}: FAILED, ${e}`);
  }
}

console.log(`${cases.length - failed} of ${cases.length} recordings read correctly`);
process.exit(failed === 0 ? 0 : 1);
