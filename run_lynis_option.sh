#!/bin/sh
# Run exactly one enhanced plugin with Lynis without changing /etc/lynis/plugins.
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 1|2 [path/to/da1_test.prf]" >&2
  exit 2
fi

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case "$1" in
  1)
    PLUGIN_NAME=kernel_ebpf_harden_enhanced_runtime
    SOURCE="$PACKAGE_DIR/option1/plugin_kernel_ebpf_harden_enhanced_runtime"
    DISABLE_NAME=kernel_ebpf_harden_enhanced_persistence
    ;;
  2)
    PLUGIN_NAME=kernel_ebpf_harden_enhanced_persistence
    SOURCE="$PACKAGE_DIR/option2/plugin_kernel_ebpf_harden_enhanced_persistence"
    DISABLE_NAME=kernel_ebpf_harden_enhanced_runtime
    ;;
  *) echo "Choose option 1 or 2." >&2; exit 2 ;;
esac

[ -r "$SOURCE" ] || { echo "Plugin source not found: $SOURCE" >&2; exit 1; }
command -v lynis >/dev/null 2>&1 || { echo "Lynis is not in PATH." >&2; exit 1; }

TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/lynis-da1.XXXXXX")
PLUGINDIR="$TMPROOT/plugins"
PROFILE="$TMPROOT/da1_test.prf"
mkdir -p "$PLUGINDIR"
chmod 755 "$TMPROOT" "$PLUGINDIR"
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT HUP INT TERM

sudo install -o root -g root -m 600 "$SOURCE" "$PLUGINDIR/plugin_${PLUGIN_NAME}_phase1"

if [ "$#" -eq 2 ]; then
  INPUT_PROFILE=$2
  [ -r "$INPUT_PROFILE" ] || { echo "Cannot read profile: $INPUT_PROFILE" >&2; exit 1; }
  # Preserve unrelated user profile settings, but replace eBPF plugin selection.
  awk '
    /^[[:space:]]*(plugin|disable-plugin)=/ && /(kernel_ebpf_harden|plugin_kernel_ebpf_harden)/ { next }
    { print }
  ' "$INPUT_PROFILE" > "$PROFILE"
fi
cat >> "$PROFILE" <<EOF_PROFILE
# Isolated DA1 eBPF plugin test: generated temporarily by run_lynis_option.sh
disable-plugin=kernel_ebpf_harden
disable-plugin=plugin_kernel_ebpf_harden
disable-plugin=$DISABLE_NAME
plugin=$PLUGIN_NAME
EOF_PROFILE
chmod 644 "$PROFILE"

echo "Running Lynis with only: $PLUGIN_NAME"
echo "Temporary plugin directory: $PLUGINDIR"
echo "No files in /etc/lynis/plugins are changed."
sudo lynis audit system --profile "$PROFILE" --plugin-dir "$PLUGINDIR"
