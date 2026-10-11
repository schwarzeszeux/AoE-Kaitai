use flate2::read::DeflateDecoder;
use kaitai::CustomDecoder;
use std::io::Read;

/// Kaitai Struct custom process routine raw_inflate (see definitions/aoe2record.ksy): decompresses raw
/// DEFLATE data (RFC 1951, no zlib header or trailer), which is how Age of Empires II recorded games
/// store their headers.
#[derive(Default)]
pub struct RawInflate;

impl RawInflate {
    pub fn new() -> Self {
        RawInflate
    }
}

impl CustomDecoder for RawInflate {
    fn decode(&self, bytes: &[u8]) -> Result<Vec<u8>, String> {
        let mut output = Vec::with_capacity(bytes.len() * 12);
        DeflateDecoder::new(bytes)
            .read_to_end(&mut output)
            .map_err(|e| format!("raw_inflate: {}", e))?;
        Ok(output)
    }
}
