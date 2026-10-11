# AoE-Kaitai
[Kaitai Struct](https://kaitai.io/) definitions for Age of Empires II: Definitive Edition files:

* `definitions/aoe2record.ksy` - recorded games (`.aoe2record`): header (versions, settings, players,
  map) and body (actions, syncs, chat, post-game data), DE save versions 12.97 to 68.9
* `definitions/gameInfo.ksy`, `definitions/slotMetadata.ksy` - game info and slot metadata blobs

## Parsers
Every [release](https://github.com/schwarzeszeux/AoE-Kaitai/releases) has the recorded game parser
generated for C#, Python, Java, JavaScript, Go and Rust, ready to use, and the C# one is on NuGet as
`AoEKaitai`. Each needs its language's Kaitai Struct runtime (0.11):

| Language   | Release file              | Runtime |
|------------|---------------------------|---------|
| C#         | `aoe2record-csharp.zip`, `AoEKaitai.*.nupkg` | NuGet `KaitaiStruct.Runtime.CSharp` |
| Python     | `aoe2record-python.zip`     | PyPI `kaitaistruct` |
| Java       | `aoe2record-java.zip`       | Maven `io.kaitai:kaitai-struct-runtime` |
| JavaScript | `aoe2record-javascript.zip` | npm `kaitai-struct` (in browsers also `pako`) |
| Go         | `aoe2record-go.zip`         | `github.com/kaitai-io/kaitai_struct_go_runtime` (in its `go.mod`) |
| Rust       | `aoe2record-rust.zip`       | `kaitai` from GitHub (in its `Cargo.toml`) |

The header of a recording is raw DEFLATE, which the definitions decode with the custom process routine
`raw_inflate`. Its implementation for each language is in `platform/<language>` and included in the
release files. The C# parser is in the namespace `AoEKaitai`, the Java one in the package `aoekaitai`.

Python example:

```python
from aoe2record import Aoe2record
from aoe2record_body import Aoe2recordBody

recording = Aoe2record.from_file("game.aoe2record")
for chapter in recording.chapters:
    for operation in chapter.body.operations:
        if isinstance(operation.data, Aoe2recordBody.OpChat):
            print(operation.data.message)
```

## Building
`scripts/build.sh <csharp|python|java|javascript|go|rust> <output dir>` generates the parser with
kaitai-struct-compiler 0.11 and puts it together with the `raw_inflate` routine and project files. It
also patches the few places where the compiler's Go, JavaScript or Rust output doesn't work as generated
(see the script).

## Tests
`tests/recordings` holds recorded games that a version of the definitions failed to read, and
`expected.json` what must be read from each (operations, chat messages, game time). Every language reads
them all on every push (`.github/workflows/ci.yml`); `tests/test_recordings.py` is the Python version:

```sh
scripts/build.sh python build/python
pip install kaitaistruct pytest
AOE2RECORD_PARSER=build/python pytest tests
```

A recording that fails to parse goes into `tests/recordings` with a line in `expected.json`.

## Releases
Pushing a tag `v<version>` (e.g. `v1.0.0`), or making a release with a new tag on GitHub, runs the tests
and, if all pass, publishes the release with the parsers and the NuGet package (secret `nuget_api_key`).
