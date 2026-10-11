"""Kaitai Struct custom process routine raw_inflate (see definitions/aoe2record.ksy): decompresses raw
DEFLATE data (RFC 1951, no zlib header or trailer), which is how Age of Empires II recorded games store
their headers."""
import zlib


class RawInflate:
    def decode(self, data):
        return zlib.decompress(data, -zlib.MAX_WBITS)
