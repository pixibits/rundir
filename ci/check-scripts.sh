#!/bin/bash
#
# check-scripts.sh - verify scripts.wombat/ and scripts/ are in lock-step.
#
# Three invariants are enforced:
#   1. Rebuild:    encoding scripts.wombat/*.m with scripts/*.m as
#                  variant reference reproduces scripts/*.m byte-for-byte.
#   2. Round-trip: decoding scripts/*.m produces text equal to
#                  scripts.wombat/*.m.
#   3. SDB:        ref-based encoding never appends to scripts/sdb.txt.
#
# Usage: ./ci/check-scripts.sh <wombat-dir>
#
#   <wombat-dir>  directory containing the compiled `wombat` binary and
#                 `convert.sh` (typically ../uotools/wombat).

set -e

if [ $# -ne 1 ]; then
	echo "usage: $0 <wombat-dir>" >&2
	exit 1
fi

WOMBAT_DIR="$1"
WOMBAT="$WOMBAT_DIR/wombat"
CONVERT="$WOMBAT_DIR/convert.sh"

if [ ! -x "$WOMBAT" ]; then
	echo "error: wombat binary not found or not executable: $WOMBAT" >&2
	exit 1
fi
if [ ! -x "$CONVERT" ]; then
	echo "error: convert.sh not found or not executable: $CONVERT" >&2
	exit 1
fi

RUNDIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$RUNDIR/scripts"
SOURCES="$RUNDIR/scripts.wombat"
SDB="$SCRIPTS/sdb.txt"

if [ ! -d "$SCRIPTS" ] || [ ! -f "$SDB" ]; then
	echo "error: $SCRIPTS or sdb.txt missing" >&2
	exit 1
fi
if [ ! -d "$SOURCES" ]; then
	echo "error: $SOURCES missing" >&2
	exit 1
fi

TMPDIR=$(mktemp -d "/tmp/check-scripts.XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/rebuilt" "$TMPDIR/decoded"

# Work on a copy of sdb.txt so the encoder cannot dirty the source tree
# if scripts.wombat/ references identifiers not yet in the DB.
WORK_SDB="$TMPDIR/sdb.txt"
cp "$SDB" "$WORK_SDB"

echo "=== check-scripts ==="
echo "  scripts:        $SCRIPTS"
echo "  scripts.wombat: $SOURCES"
echo "  sdb:            $SDB"
echo "  wombat:         $WOMBAT"
echo

sdb_before=$(sha1sum "$WORK_SDB" | cut -d' ' -f1)

# Rebuild: encode scripts.wombat -> tmp, using scripts/ as variant
# reference. Output must byte-match scripts/ file by file.
"$CONVERT" -c -s "$WORK_SDB" -r "$SCRIPTS" "$SOURCES" "$TMPDIR/rebuilt" >/dev/null

rebuild_total=0
rebuild_fail=0
for f in "$TMPDIR/rebuilt"/*.m; do
	[ -f "$f" ] || continue
	base="$(basename "$f")"
	rebuild_total=$((rebuild_total + 1))
	if ! cmp -s "$f" "$SCRIPTS/$base"; then
		echo "MISMATCH [rebuild]: $base"
		rebuild_fail=$((rebuild_fail + 1))
	fi
done

# SDB invariance: ref-mode encode of canonical sources must not grow
# the string DB (see uotools/wombat/main.c:87).
sdb_after=$(sha1sum "$WORK_SDB" | cut -d' ' -f1)
sdb_ok=1
if [ "$sdb_before" != "$sdb_after" ]; then
	echo "MISMATCH [sdb]: sdb.txt was modified by ref-based encode"
	echo "  before=$sdb_before"
	echo "  after =$sdb_after"
	sdb_ok=0
fi

# Round-trip: decode scripts -> tmp, must text-match scripts.wombat.
# Decode is read-only against the SDB; use the original path.
"$CONVERT" -d -s "$SDB" "$SCRIPTS" "$TMPDIR/decoded" >/dev/null

roundtrip_total=0
roundtrip_fail=0
first_fail=""
for f in "$TMPDIR/decoded"/*.m; do
	[ -f "$f" ] || continue
	base="$(basename "$f")"
	roundtrip_total=$((roundtrip_total + 1))
	if ! diff -q "$f" "$SOURCES/$base" >/dev/null 2>&1; then
		echo "MISMATCH [round-trip]: $base"
		roundtrip_fail=$((roundtrip_fail + 1))
		if [ -z "$first_fail" ]; then
			first_fail="$base"
			diff -u "$SOURCES/$base" "$f" | head -20
		fi
	fi
done

echo
echo "=== Results ==="
echo "  rebuild:    $((rebuild_total - rebuild_fail))/$rebuild_total ok"
echo "  round-trip: $((roundtrip_total - roundtrip_fail))/$roundtrip_total ok"
if [ "$sdb_ok" -eq 1 ]; then
	echo "  sdb:        unchanged"
else
	echo "  sdb:        MODIFIED"
fi

[ "$rebuild_fail" -eq 0 ] && [ "$roundtrip_fail" -eq 0 ] && [ "$sdb_ok" -eq 1 ]
