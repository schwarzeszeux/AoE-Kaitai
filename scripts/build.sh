#!/bin/sh
# Builds the recorded game parser for one language as a ready-to-use package directory:
#
#   scripts/build.sh <csharp|python|java|javascript|go|rust> <output dir>
#
# The parser is generated from definitions/aoe2record.ksy with kaitai-struct-compiler 0.11 (set KSC to
# run another command); the hand-written raw_inflate routine and the project files come from
# platform/<language>. Three targets need their generated code patched:
#   - Go: the compiler leaves custom process routines out (it keeps the compressed bytes as they are),
#     so the call to RawInflate is inserted, and the imported header and body get no root (nil), so
#     their Read falls back to themselves;
#   - JavaScript: the routine is imported as a package named RawInflate; it is the file next to it;
#   - Rust: the header reads its own save_version instance, which can fail, without the ? to pass the
#     error on.
set -eu

lang=$1
out=$2
root=$(cd "$(dirname "$0")/.." && pwd)
ksc=${KSC:-kaitai-struct-compiler}
ksy=$root/definitions/aoe2record.ksy

rm -rf "$out"
mkdir -p "$out"
cp -R "$root/platform/$lang/." "$out/"

case $lang in
csharp)
    $ksc -t csharp --outdir "$out" "$ksy"
    cp "$root/README.md" "$out/"
    ;;
python)
    $ksc -t python --outdir "$out" "$ksy"
    ;;
java)
    $ksc -t java --java-package aoekaitai --outdir "$out" "$ksy"
    ;;
javascript)
    $ksc -t javascript --outdir "$out" "$ksy"
    sed -i "s|'RawInflate'|'./RawInflate'|g" "$out/Aoe2record.js"
    grep -q "'./RawInflate'" "$out/Aoe2record.js"
    ;;
go)
    $ksc -t go --go-package aoe2record --outdir "$out/generated" "$ksy"
    mv "$out"/generated/aoe2record/*.go "$out/"
    rm -rf "$out/generated"
    sed -i 's|^\([[:space:]]*\)this\._raw_Header = this\._raw__raw_Header$|\1this._raw_Header, err = RawInflate(this._raw__raw_Header)\n\1if err != nil {\n\1\treturn err\n\1}|' "$out/aoe2record.go"
    grep -q "RawInflate(this._raw__raw_Header)" "$out/aoe2record.go"
    # the imported header and body get nil for their root, which they read the save version from
    for type in Aoe2record Aoe2recordHeader Aoe2recordBody; do
        sed -i "/^func (this \*$type) Read(/,/this\._root = root/ s|^\([[:space:]]*\)this\._root = root$|\1if root == nil {\n\1\troot = this\n\1}\n\1this._root = root|" "$out/$(echo $type | sed 's/Aoe2record/aoe2record/; s/Header$/_header/; s/Body$/_body/').go"
    done
    [ "$(cat "$out"/*.go | grep -c "root = this$")" = 3 ]
    ;;
rust)
    $ksc -t rust --outdir "$out/src" "$ksy"
    sed -i 's|\*_r\.save_version()\([^?]\)|*_r.save_version()?\1|g' "$out/src/aoe2record_header.rs"
    ;;
*)
    echo "unknown language: $lang" >&2
    exit 1
    ;;
esac
