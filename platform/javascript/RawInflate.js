// Kaitai Struct custom process routine raw_inflate (see definitions/aoe2record.ksy): decompresses raw
// DEFLATE data (RFC 1951, no zlib header or trailer), which is how Age of Empires II recorded games store
// their headers. Uses pako when it is loaded (browsers), otherwise Node's zlib.

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['exports'], factory);
  } else if (typeof exports === 'object' && exports !== null && typeof exports.nodeType !== 'number') {
    factory(exports);
  } else {
    factory(root.RawInflate || (root.RawInflate = {}));
  }
})(typeof self !== 'undefined' ? self : this, function (RawInflate_) {
  function inflateRaw(data) {
    if (typeof pako !== 'undefined') {
      return pako.inflateRaw(data);
    }
    if (typeof require === 'function') {
      var zlib = require('zlib');
      var output = zlib.inflateRawSync(data);
      return new Uint8Array(output.buffer, output.byteOffset, output.byteLength);
    }
    throw new Error('raw_inflate needs pako in a browser');
  }

  function RawInflate() {
  }

  RawInflate.prototype.decode = function (data) {
    return inflateRaw(data);
  };

  RawInflate_.RawInflate = RawInflate;
});
