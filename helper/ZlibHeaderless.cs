using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace AoEKaitai
{
    public class ZlibHeaderless : Kaitai.CustomDecoder
    {
        public byte[] Decode(byte[] src)
        {
            using (var ms = new MemoryStream(src))
            using (var decompressor = new System.IO.Compression.DeflateStream(ms, System.IO.Compression.CompressionMode.Decompress))
            using (var decompressed = new MemoryStream())
            {
                decompressor.CopyTo(decompressed);
                return decompressed.ToArray();
            }
                
        }
    }
}
