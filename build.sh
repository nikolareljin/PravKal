#!/bin/bash
# Build script for Pravoslavni Kalendar (FPC port)
# Compiles src/pravkal6.pas and copies runtime data files next to the binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/src"
mkdir -p ../obj

echo "=== Building Pravoslavni Kalendar (FPC) ==="
fpc -Mtp \
    -Fu. \
    -FU../obj \
    -FE.. \
    pravkal6.pas

echo "=== Copying runtime data files ==="
for f in "$SCRIPT_DIR/data/"_*.KAL "$SCRIPT_DIR/data/"_*.MOL; do
  [ -f "$f" ] || continue
  cp "$f" "$SCRIPT_DIR/"
done

echo ""
echo "=== Build complete ==="
echo "Binary : $SCRIPT_DIR/pravkal6"
echo "Run    : cd $SCRIPT_DIR && ./pravkal6"
