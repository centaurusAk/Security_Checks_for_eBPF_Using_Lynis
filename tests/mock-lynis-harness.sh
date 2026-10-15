#!/bin/sh
# Test helper: provide minimal Lynis function stubs and source one plugin.
set -eu
[ "$#" -eq 1 ] || { echo "Usage: $0 PLUGIN_FILE" >&2; exit 2; }
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
InsertSection() { printf '\n## %s\n' "$1"; }
Register() { printf '[REGISTER] %s\n' "$*"; }
LogText() { printf '[LOG] %s\n' "$*"; }
Display() { printf '[DISPLAY] %s\n' "$*"; }
ReportSuggestion() { printf '[SUGGESTION] %s: %s\n' "$1" "$2"; }
WaitForKeyPress() { :; }
SYSCTLBINARY="$SCRIPT_DIR/mock-sysctl"
SKIPTEST=0
AWKBINARY=/usr/bin/awk
export SYSCTLBINARY SKIPTEST AWKBINARY MOCK_BPF_JIT_HARDEN MOCK_UNPRIV_BPF_DISABLED
. "$1"
