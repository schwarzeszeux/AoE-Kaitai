using System.IO;
using System.IO.Compression;

namespace AoEKaitai
{
    /// <summary>
    /// Kaitai Struct custom process routine <c>raw_inflate</c> (see definitions/aoe2record.ksy).
    /// Decompresses raw DEFLATE data (RFC 1951, no zlib header or Adler-32 trailer), which is how
    /// Age of Empires II recorded games store their headers. The built-in <c>process: zlib</c>
    /// expects a zlib (RFC 1950) wrapper and cannot be used.
    /// </summary>
    public class RawInflate : Kaitai.CustomDecoder
    {
        public byte[] Decode(byte[] src)
        {
            using var input = new MemoryStream(src, writable: false);
            using var inflater = new DeflateStream(input, CompressionMode.Decompress);
            // Recorded game headers inflate to roughly 10-15x their compressed size.
            using var output = new MemoryStream(src.Length * 12);
            inflater.CopyTo(output);
            return output.ToArray();
        }
    }
}
