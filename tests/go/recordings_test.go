package aoe2record

// Reads every recording listed in expected.json with the generated Go parser, completely, and compares
// it with the expected values (see tests/test_recordings.py). Copied into the package built by
// scripts/build.sh go; run with the recordings directory in AOE2RECORD_RECORDINGS.

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/kaitai-io/kaitai_struct_go_runtime/kaitai"
)

type expectation struct {
	File       string `json:"file"`
	Operations int    `json:"operations"`
	Chats      int    `json:"chats"`
	WorldTime  int64  `json:"worldTime"`
}

func TestRecordings(t *testing.T) {
	directory := os.Getenv("AOE2RECORD_RECORDINGS")
	manifest, err := os.ReadFile(filepath.Join(directory, "expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	var cases []expectation
	if err := json.Unmarshal(manifest, &cases); err != nil {
		t.Fatal(err)
	}
	for _, expected := range cases {
		expected := expected
		t.Run(expected.File, func(t *testing.T) {
			got, isDe, err := read(filepath.Join(directory, expected.File))
			if err != nil {
				t.Fatal(err)
			}
			want := fmt.Sprintf("%d operations, %d chats, world time %d, sync time %d",
				expected.Operations, expected.Chats, expected.WorldTime, expected.WorldTime)
			if got != want || !isDe {
				t.Errorf("got %s, expected %s", got, want)
			}
		})
	}
}

func read(path string) (string, bool, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", false, err
	}
	defer file.Close()
	gz, err := gzip.NewReader(file)
	if err != nil {
		return "", false, err
	}
	data, err := io.ReadAll(gz)
	if err != nil {
		return "", false, err
	}

	recording := NewAoe2record()
	if err := recording.Read(kaitai.NewStream(bytes.NewReader(data)), nil, nil); err != nil {
		return "", false, err
	}
	isDe, err := recording.Chapters[0].Header.IsDe()
	if err != nil {
		return "", false, err
	}
	var operations []*Aoe2recordBody_Operation
	for _, chapter := range recording.Chapters {
		chapterOperations, err := chapter.Body.Operations()
		if err != nil {
			return "", false, err
		}
		operations = append(operations, chapterOperations...)
	}

	chats, syncTime := 0, int64(0)
	for _, operation := range operations {
		switch data := operation.Data.(type) {
		case *Aoe2recordBody_OpChat:
			chats++
		case *Aoe2recordBody_OpSync:
			syncTime += int64(data.TimeIncrement)
		}
	}
	worldTime := "<nil>"
	if postgame, ok := operations[len(operations)-1].Data.(*Aoe2recordBody_OpPostgame); ok {
		block, err := postgame.Data.LastBlock()
		for err == nil && block != nil {
			content, blockErr := block.Block()
			if blockErr != nil {
				return "", false, blockErr
			}
			if time, ok := content.(*Aoe2recordBody_PostgameWorldTime); ok {
				worldTime = fmt.Sprint(time.WorldTime)
			}
			block, err = block.PreviousBlock()
		}
		if err != nil {
			return "", false, err
		}
	}
	return fmt.Sprintf("%d operations, %d chats, world time %s, sync time %d", len(operations), chats, worldTime, syncTime), isDe, nil
}
