// Reads every recording listed in expected.json with the generated C# parser, completely, and compares it
// with the expected values (see tests/test_recordings.py).
using System.IO.Compression;
using System.Text.Json;
using Kaitai;

var directory = args[0];
var cases = JsonDocument.Parse(File.ReadAllText(Path.Combine(directory, "expected.json"))).RootElement;
var failed = 0;

foreach (var expected in cases.EnumerateArray())
{
    var file = expected.GetProperty("file").GetString()!;
    try
    {
        byte[] bytes;
        using (var gzip = new GZipStream(File.OpenRead(Path.Combine(directory, file)), CompressionMode.Decompress))
        using (var unpacked = new MemoryStream())
        {
            gzip.CopyTo(unpacked);
            bytes = unpacked.ToArray();
        }

        var recording = new Aoe2record(new KaitaiStream(bytes));
        var operations = recording.Chapters.SelectMany(chapter => chapter.Body.Operations).ToList();
        var chats = operations.Count(operation => operation.Data is Aoe2recordBody.OpChat);
        var syncTime = operations.Select(operation => operation.Data).OfType<Aoe2recordBody.OpSync>()
            .Sum(sync => (long)sync.TimeIncrement);
        long? worldTime = null;
        if (operations.Last().Data is Aoe2recordBody.OpPostgame postgame)
            for (var block = postgame.Data.LastBlock; block != null; block = block.PreviousBlock)
                if (block.Block is Aoe2recordBody.PostgameWorldTime time)
                    worldTime = time.WorldTime;

        var got = $"{operations.Count} operations, {chats} chats, world time {worldTime}, sync time {syncTime}";
        var want = $"{expected.GetProperty("operations").GetInt64()} operations, {expected.GetProperty("chats").GetInt64()} chats, " +
                   $"world time {expected.GetProperty("worldTime").GetInt64()}, sync time {expected.GetProperty("worldTime").GetInt64()}";
        if (got == want && recording.Chapters[0].Header.IsDe)
            Console.WriteLine($"{file}: ok");
        else
        {
            failed++;
            Console.WriteLine($"{file}: FAILED, got {got}, expected {want}");
        }
    }
    catch (Exception e)
    {
        failed++;
        Console.WriteLine($"{file}: FAILED, {e.GetType().Name}: {e.Message}");
    }
}

Console.WriteLine($"{cases.GetArrayLength() - failed} of {cases.GetArrayLength()} recordings read correctly");
return failed == 0 ? 0 : 1;
