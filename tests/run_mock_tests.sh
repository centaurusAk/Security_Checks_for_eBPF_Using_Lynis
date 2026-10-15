#!/bin/sh
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
OPT1="$PACKAGE_DIR/option1/plugin_kernel_ebpf_harden_enhanced_runtime"
OPT2="$PACKAGE_DIR/option2/plugin_kernel_ebpf_harden_enhanced_persistence"

# ZIP extraction may not preserve executable bits; the mock sysctl must be executable.
chmod +x "$TEST_DIR/mock-sysctl"

for f in "$OPT1" "$OPT2" "$TEST_DIR/mock-lynis-harness.sh" "$TEST_DIR/mock-sysctl" "$PACKAGE_DIR/run_lynis_option.sh"; do
  sh -n "$f"
done
printf '%s\n' 'PASS: POSIX shell syntax checks'

MOCK_BPF_JIT_HARDEN=2 MOCK_UNPRIV_BPF_DISABLED=1 \
  sh "$TEST_DIR/mock-lynis-harness.sh" "$OPT1" > "$TEST_DIR/option1-secure.out"
grep -q 'eBPF JIT hardening.*ENABLED' "$TEST_DIR/option1-secure.out"
grep -q 'Unprivileged eBPF restriction.*ENABLED' "$TEST_DIR/option1-secure.out"
! grep -q 'AddScore: not found' "$TEST_DIR/option1-secure.out"
printf '%s\n' 'PASS: Option 1 secure mock values'

MOCK_BPF_JIT_HARDEN=0 MOCK_UNPRIV_BPF_DISABLED=0 \
  sh "$TEST_DIR/mock-lynis-harness.sh" "$OPT1" > "$TEST_DIR/option1-warning.out"
grep -q 'eBPF JIT hardening.*WARNING' "$TEST_DIR/option1-warning.out"
grep -q 'Unprivileged eBPF restriction.*WARNING' "$TEST_DIR/option1-warning.out"
! grep -q 'AddScore: not found' "$TEST_DIR/option1-warning.out"
printf '%s\n' 'PASS: Option 1 warning mock values'

MOCK_BPF_JIT_HARDEN=2 MOCK_UNPRIV_BPF_DISABLED=1 \
  sh "$TEST_DIR/mock-lynis-harness.sh" "$OPT2" > "$TEST_DIR/option2-secure.out"
grep -q 'eBPF JIT hardening.*ENABLED' "$TEST_DIR/option2-secure.out"
grep -q 'Unprivileged eBPF restriction.*ENABLED' "$TEST_DIR/option2-secure.out"
grep -q 'Persistent eBPF JIT hardening' "$TEST_DIR/option2-secure.out"
grep -q 'Persistent unprivileged eBPF restriction' "$TEST_DIR/option2-secure.out"
! grep -q 'AddScore: not found' "$TEST_DIR/option2-secure.out"
printf '%s\n' 'PASS: Option 2 runtime and persistence mock smoke test'

echo 'All local mock smoke tests passed. These do not replace a live Lynis integration test.'
