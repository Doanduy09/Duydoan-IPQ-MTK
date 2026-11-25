#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Reuse GitHub runner Go, LLVM/BPF, and skip Host Python PGO to cut OpenWrt build time.
set -euo pipefail

GO_ROOT=$(go env GOROOT)
test -x "$GO_ROOT/bin/go"

# Use the runner's Go to bootstrap OpenWrt's pinned host Go compiler.
sed -i '/^CONFIG_GOLANG_BUILD_BOOTSTRAP=/d; /^# CONFIG_GOLANG_BUILD_BOOTSTRAP is not set$/d; /^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=/d' .config
printf '# CONFIG_GOLANG_BUILD_BOOTSTRAP is not set\nCONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="%s"\n' "$GO_ROOT" >> .config

# Host Python PGO is unnecessary overhead on CI runners; only patch when present.
PYTHON_MAKEFILE=feeds/packages/lang/python/python3/Makefile
if [ -f "$PYTHON_MAKEFILE" ] && grep -q -- '--enable-optimizations' "$PYTHON_MAKEFILE"; then
	sed -i '/^HOST_CONFIGURE_ARGS[[:space:]]*+=/,/^$/s/--enable-optimizations/--disable-optimizations/' "$PYTHON_MAKEFILE"
	echo "Host Python PGO: disabled in $PYTHON_MAKEFILE"
else
	echo "Host Python PGO: not applicable or already disabled"
fi

# Use runner LLVM for BPF toolchain instead of compiling LLVM from source (~50 min saved).
LLVM_ROOT=$(llvm-config --prefix)
for tool in clang llc opt llvm-dis llvm-strip; do
	test -x "$LLVM_ROOT/bin/$tool"
done

LLVM_SMOKE="${RUNNER_TEMP:-/tmp}/wrt-bpf-smoke"
mkdir -p "$LLVM_SMOKE"
printf 'int wrt_bpf_smoke(void) { return 0; }\n' > "$LLVM_SMOKE/smoke.c"
"$LLVM_ROOT/bin/clang" --target=bpfel -O2 -emit-llvm -c \
	"$LLVM_SMOKE/smoke.c" -o "$LLVM_SMOKE/smoke.bc"
"$LLVM_ROOT/bin/opt" -O2 -mtriple=bpfel \
	< "$LLVM_SMOKE/smoke.bc" > "$LLVM_SMOKE/smoke.opt"
"$LLVM_ROOT/bin/llvm-dis" \
	< "$LLVM_SMOKE/smoke.opt" > "$LLVM_SMOKE/smoke.S"
"$LLVM_ROOT/bin/llc" -march=bpfel -mcpu=v3 -filetype=obj \
	-o "$LLVM_SMOKE/smoke.o" < "$LLVM_SMOKE/smoke.S"
"$LLVM_ROOT/bin/llvm-strip" --strip-debug "$LLVM_SMOKE/smoke.o"

# Unlock DEVEL so make defconfig honors CCACHE and BPF_TOOLCHAIN_HOST on all targets
sed -i '/^CONFIG_DEVEL=/d; /^# CONFIG_DEVEL is not set$/d; /^CONFIG_USE_LLVM_BUILD=/d; /^# CONFIG_USE_LLVM_BUILD is not set$/d; /^CONFIG_BPF_TOOLCHAIN_/d; /^# CONFIG_BPF_TOOLCHAIN_.* is not set$/d' .config
printf 'CONFIG_DEVEL=y\nCONFIG_BPF_TOOLCHAIN_HOST=y\nCONFIG_BPF_TOOLCHAIN_HOST_PATH="%s"\n' "$LLVM_ROOT" >> .config

REPORT_DIR="${GITHUB_WORKSPACE:-$PWD}/build-reports"
mkdir -p "$REPORT_DIR"
{
	"$GO_ROOT/bin/go" version
	printf 'Go bootstrap root: %s\n' "$GO_ROOT"
	printf 'BPF LLVM prefix: %s\n' "$LLVM_ROOT"
	"$LLVM_ROOT/bin/clang" --version
} | tee "$REPORT_DIR/host-toolchains.txt"
