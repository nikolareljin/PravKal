#!/bin/bash
# Build script for PravKal (FPC port)
# Compiles src/pravkal.pas and copies runtime data files next to the binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/src"
mkdir -p ../obj

# Windows (Git bash on the CI runner) needs a .exe; Unix builds an
# extensionless binary. FPC's handling of -o without an extension is
# inconsistent on Windows (it can emit "pravkal" with no extension, which the
# release verify step then can't find as "pravkal.exe"), so name it explicitly.
EXE=""
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) EXE=".exe" ;;
esac

echo "=== Building PravKal (FPC) ==="
fpc -Mtp \
    -Fu. \
    -FU../obj \
    -FE.. \
    -opravkal"${EXE}" \
    pravkal.pas

# Guarantee <root>/pravkal${EXE} exists regardless of how FPC named the output,
# so the release pipeline's "Verify binary" step finds it.
cd "$SCRIPT_DIR"
if [ -n "$EXE" ] && [ ! -f "pravkal${EXE}" ] && [ -f pravkal ]; then
  mv pravkal "pravkal${EXE}"
fi
if [ ! -f "pravkal${EXE}" ]; then
  echo "::error::expected binary pravkal${EXE} not found after build" >&2
  ls -la "$SCRIPT_DIR" >&2 || true
  exit 1
fi

echo "=== Copying runtime data files ==="
for f in "$SCRIPT_DIR/data/"_*.KAL "$SCRIPT_DIR/data/"_*.MOL; do
  [ -f "$f" ] || continue
  cp "$f" "$SCRIPT_DIR/"
done

echo ""
echo "=== Build complete ==="
echo "Binary : $SCRIPT_DIR/pravkal${EXE}"
echo "Run    : cd $SCRIPT_DIR && ./pravkal${EXE}"
