//! Reads every recording listed in expected.json with the generated Rust parser, completely, and compares
//! it with the expected values (see tests/test_recordings.py). Copied into the tests of the crate built by
//! scripts/build.sh rust; run with the recordings directory in AOE2RECORD_RECORDINGS.

use aoe2record::aoe2record::Aoe2record;
use aoe2record::aoe2record_body::{Aoe2recordBody_Operation_Data, Aoe2recordBody_PostgameBlock_Block};
use flate2::read::GzDecoder;
use kaitai::{BytesReader, KResult, KStruct};
use std::io::Read;
use std::path::Path;

/// The value of a field of one manifest entry (the manifest is a flat list of objects, no JSON crate needed)
fn field<'a>(entry: &'a str, name: &str) -> &'a str {
    let key = format!("\"{}\":", name);
    let rest = entry[entry.find(&key).expect(name) + key.len()..].trim_start();
    let end = rest.find(|c: char| c == ',' || c == '\n' || c == '}').unwrap();
    rest[..end].trim().trim_matches('"')
}

/// What the parser reads from a recording, in the words of the manifest, and whether it is a DE recording
fn read(path: &Path) -> KResult<(String, bool)> {
    let mut data = Vec::new();
    GzDecoder::new(std::fs::File::open(path).unwrap()).read_to_end(&mut data).unwrap();
    let reader = BytesReader::from(data);
    let recording = Aoe2record::read_into::<BytesReader, Aoe2record>(&reader, None, None)?;
    let chapters = recording.chapters();
    let is_de = *chapters[0].header().is_de()?;

    let (mut operations, mut chats, mut sync_time) = (0usize, 0usize, 0u64);
    let mut world_time = None;
    for chapter in chapters.iter() {
        let body = chapter.body();
        let chapter_operations = body.operations()?;
        for (i, operation) in chapter_operations.iter().enumerate() {
            operations += 1;
            match &*operation.data() {
                Some(Aoe2recordBody_Operation_Data::Aoe2recordBody_OpChat(_)) => chats += 1,
                Some(Aoe2recordBody_Operation_Data::Aoe2recordBody_OpSync(sync)) => {
                    sync_time += *sync.time_increment() as u64
                }
                Some(Aoe2recordBody_Operation_Data::Aoe2recordBody_OpPostgame(postgame))
                    if i == chapter_operations.len() - 1 =>
                {
                    let data = postgame.data();
                    let mut block = data.last_block()?.clone();
                    while !block.is_none() {
                        if let Some(Aoe2recordBody_PostgameBlock_Block::Aoe2recordBody_PostgameWorldTime(time)) =
                            &*block.block()?
                        {
                            world_time = Some(*time.world_time());
                        }
                        let previous = block.previous_block()?.clone();
                        block = previous;
                    }
                }
                _ => {}
            }
        }
    }

    let world_time = world_time.map_or("none".to_string(), |time| time.to_string());
    Ok((format!("{} operations, {} chats, world time {}, sync time {}", operations, chats, world_time, sync_time), is_de))
}

#[test]
fn recordings() {
    let directory = std::env::var("AOE2RECORD_RECORDINGS").expect("AOE2RECORD_RECORDINGS");
    let manifest = std::fs::read_to_string(Path::new(&directory).join("expected.json")).unwrap();
    let mut failed = Vec::new();
    for entry in manifest.split('{').skip(1) {
        let file = field(entry, "file");
        let world_time = field(entry, "worldTime");
        let want = format!("{} operations, {} chats, world time {}, sync time {}",
                           field(entry, "operations"), field(entry, "chats"), world_time, world_time);
        match read(&Path::new(&directory).join(file)) {
            Ok((got, true)) if got == want => println!("{}: ok", file),
            Ok((got, is_de)) => failed.push(format!("{}: got {} (DE: {}), expected {}", file, got, is_de, want)),
            Err(e) => failed.push(format!("{}: {:?}", file, e)),
        }
    }
    assert!(failed.is_empty(), "\n{}", failed.join("\n"));
}
