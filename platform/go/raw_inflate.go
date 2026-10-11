package aoe2record

import (
	"bytes"
	"compress/flate"
	"io"
)

// RawInflate is the custom process routine raw_inflate (see definitions/aoe2record.ksy): it
// decompresses raw DEFLATE data (RFC 1951, no zlib header or trailer), which is how Age of Empires II
// recorded games store their headers. The compiler's Go target leaves custom routines out, so
// scripts/build.sh inserts the call into the generated code.
func RawInflate(data []byte) ([]byte, error) {
	reader := flate.NewReader(bytes.NewReader(data))
	defer reader.Close()
	return io.ReadAll(reader)
}
