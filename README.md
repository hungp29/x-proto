# x-proto

Protocol buffer definitions shared across x-* services.

## Layout

- `word/v1/` — x-word gRPC API (WordService: GetWord, GetWords, Ping, Health).
- `gen/go/` — **Generated Go code** (`.pb.go`, `_grpc.pb.go`), committed by CI (see below).

## CI: push proto → generate → auto-commit

The workflow [`.github/workflows/generate-and-commit.yaml`](.github/workflows/generate-and-commit.yaml) runs on push to `main` when `**.proto`, `buf.yaml`, or `buf.gen.yaml` change (and on `workflow_dispatch`). It:

1. Runs `buf generate` (Go + gRPC plugins, output under `gen/go/` with managed `go_package` for this repo).
2. If `gen/` has changes, commits and pushes with message `chore(gen): regenerate Go from proto [skip ci]`.

Ensure the default `GITHUB_TOKEN` has **Contents: write** (the workflow requests it) so the push succeeds. For protected branches you may need to allow the Actions bot to push or use a PAT.

## Consuming (e.g. x-word)

Generated Go code lives in **x-word** (`internal/genpb/word/v1/`). To regenerate from this repo:

**Option 1 – protoc (from x-word):**
```bash
cd x-word
make generate
```
Requires `protoc`, `protoc-gen-go`, and `protoc-gen-go-grpc` on PATH.

**Option 2 – Docker (from workspace root):**
```bash
docker run --rm -v $(pwd):/workspace -w /workspace/x-word golang:1.22-bookworm bash -c \
  'apt-get update -qq && apt-get install -qq -y protobuf-compiler && \
   go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0 && \
   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.4.0 && \
   protoc -I ../x-proto --go_out=. --go_opt=module=github.com/hungp29/x-word \
   --go-grpc_out=. --go-grpc_opt=module=github.com/hungp29/x-word ../x-proto/word/v1/word.proto'
```

**Option 3 – buf:** From `x-proto`, run `buf generate` with `out: gen` (or point `out` at x-word’s `internal/genpb` if desired).
