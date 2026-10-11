package aoekaitai;

import io.kaitai.struct.CustomDecoder;
import java.io.ByteArrayOutputStream;
import java.util.Arrays;
import java.util.zip.DataFormatException;
import java.util.zip.Inflater;

/**
 * Kaitai Struct custom process routine raw_inflate (see definitions/aoe2record.ksy): decompresses raw
 * DEFLATE data (RFC 1951, no zlib header or trailer), which is how Age of Empires II recorded games
 * store their headers.
 */
public class RawInflate implements CustomDecoder {
    @Override
    public byte[] decode(byte[] src) {
        Inflater inflater = new Inflater(true);
        // without the zlib wrapper, the inflater may need one byte beyond the compressed data
        inflater.setInput(Arrays.copyOf(src, src.length + 1));
        ByteArrayOutputStream output = new ByteArrayOutputStream(src.length * 12);
        byte[] buffer = new byte[1 << 16];
        try {
            while (!inflater.finished()) {
                int length = inflater.inflate(buffer);
                if (length == 0 && (inflater.needsInput() || inflater.needsDictionary()))
                    throw new RuntimeException("raw_inflate: the compressed data ends early");
                output.write(buffer, 0, length);
            }
        } catch (DataFormatException e) {
            throw new RuntimeException("raw_inflate: " + e.getMessage(), e);
        } finally {
            inflater.end();
        }
        return output.toByteArray();
    }
}
