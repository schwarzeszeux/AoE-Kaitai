import aoekaitai.Aoe2record;
import aoekaitai.Aoe2recordBody;
import io.kaitai.struct.ByteBufferKaitaiStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.GZIPInputStream;

/**
 * Reads every recording listed in expected.json with the generated Java parser, completely, and compares
 * it with the expected values (see tests/test_recordings.py).
 * Usage: java -cp kaitai-struct-runtime.jar:classes Check tests/recordings
 */
public class Check {
    public static void main(String[] args) throws IOException {
        Path directory = Path.of(args[0]);
        String json = Files.readString(directory.resolve("expected.json"), StandardCharsets.UTF_8);
        // the manifest is a flat list of objects; no JSON library needed
        Matcher entry = Pattern.compile("\"file\":\\s*\"([^\"]+)\",\\s*\"operations\":\\s*(\\d+),\\s*\"chats\":\\s*(\\d+),"
                                        + "\\s*\"worldTime\":\\s*(\\d+)").matcher(json);
        int total = 0, failed = 0;
        while (entry.find()) {
            total++;
            String file = entry.group(1);
            String want = entry.group(2) + " operations, " + entry.group(3) + " chats, world time " + entry.group(4)
                          + ", sync time " + entry.group(4);
            try {
                Aoe2record recording = new Aoe2record(new ByteBufferKaitaiStream(gunzip(directory.resolve(file))));
                List<Aoe2recordBody.Operation> operations = new ArrayList<>();
                for (Aoe2record.Chapter chapter : recording.chapters())
                    operations.addAll(chapter.body().operations());
                long chats = 0, syncTime = 0;
                for (Aoe2recordBody.Operation operation : operations) {
                    if (operation.data() instanceof Aoe2recordBody.OpChat)
                        chats++;
                    if (operation.data() instanceof Aoe2recordBody.OpSync)
                        syncTime += ((Aoe2recordBody.OpSync) operation.data()).timeIncrement();
                }
                Long worldTime = null;
                Object last = operations.get(operations.size() - 1).data();
                if (last instanceof Aoe2recordBody.OpPostgame)
                    for (Aoe2recordBody.PostgameBlock block = ((Aoe2recordBody.OpPostgame) last).data().lastBlock();
                         block != null; block = block.previousBlock())
                        if (block.block() instanceof Aoe2recordBody.PostgameWorldTime)
                            worldTime = ((Aoe2recordBody.PostgameWorldTime) block.block()).worldTime();

                String got = operations.size() + " operations, " + chats + " chats, world time " + worldTime
                             + ", sync time " + syncTime;
                if (got.equals(want) && recording.chapters().get(0).header().isDe()) {
                    System.out.println(file + ": ok");
                } else {
                    failed++;
                    System.out.println(file + ": FAILED, got " + got + ", expected " + want);
                }
            } catch (Exception e) {
                failed++;
                System.out.println(file + ": FAILED, " + e);
            }
        }
        System.out.println((total - failed) + " of " + total + " recordings read correctly");
        System.exit(failed == 0 && total > 0 ? 0 : 1);
    }

    static byte[] gunzip(Path path) throws IOException {
        try (InputStream input = new GZIPInputStream(Files.newInputStream(path))) {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            input.transferTo(output);
            return output.toByteArray();
        }
    }
}
