#!/usr/bin/env bash
# [VERIFIED-GOLDEN: part2-prepare-rust | 2026-11-26 | DO NOT MODIFY UNLESS TARGETED]
# SPDX-License-Identifier: MIT
# Reuse GitHub runner Rust toolchain instead of compiling Rust bootstrap from source.
set -euo pipefail

RUST_FEED="$PWD/feeds/packages/lang/rust"
RUST_MAKEFILE="$RUST_FEED/Makefile"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ ! -f "$RUST_MAKEFILE" ] || [ ! -f "$RUST_FEED/rust-values.mk" ]; then
	echo "Rust feed not present ($RUST_MAKEFILE); skipping runner Rust hook."
	exit 0
fi

RUSTUP_BIN=$(command -v rustup || true)
if [ -z "$RUSTUP_BIN" ]; then
	for candidate in "$HOME/.cargo/bin/rustup" /usr/bin/rustup; do
		if [ -x "$candidate" ]; then RUSTUP_BIN=$candidate; break; fi
	done
fi
if [ -z "$RUSTUP_BIN" ]; then
	echo "rustup not found on runner; falling back to OpenWrt Rust host build."
	exit 0
fi
PATH="$(dirname "$RUSTUP_BIN"):$PATH"
export PATH

RUST_TARGET=$(make --no-print-directory -s -f - TOPDIR="$PWD" ci-rust-target <<'MAKE'
include $(TOPDIR)/rules.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-values.mk
.PHONY: ci-rust-target
ci-rust-target:
	@printf '%s\n' '$(RUSTC_TARGET_ARCH)'
MAKE
)
[ -n "$RUST_TARGET" ] || { echo "Empty RUSTC_TARGET_ARCH; skipping runner Rust hook."; exit 0; }

RUST_TOOLCHAIN=$(rustup show active-toolchain | awk '{print $1}')
rustup target add --toolchain "$RUST_TOOLCHAIN" "$RUST_TARGET"
RUST_ROOT=$(rustup run "$RUST_TOOLCHAIN" rustc --print sysroot)
test -d "$RUST_ROOT/lib/rustlib/$RUST_TARGET/lib"
for tool in cargo rustc rustdoc; do
	test -x "$RUST_ROOT/bin/$tool"
done

{
	printf 'CI_RUST_ROOT:=%s\n' "$RUST_ROOT"
	cat "$SCRIPT_DIR/rust-prebuilt.mk"
} > "$RUST_FEED/ci-prebuilt.mk"

# shellcheck disable=SC2016
sed -i '/^include \.\/ci-prebuilt.mk$/d; /^$(eval $(call HostBuild))$/i include ./ci-prebuilt.mk' "$RUST_MAKEFILE"
grep -Fxq 'include ./ci-prebuilt.mk' "$RUST_MAKEFILE"

REPORT_DIR="${GITHUB_WORKSPACE:-$PWD}/build-reports"
mkdir -p "$REPORT_DIR"
{
	printf 'Rust toolchain: %s\nRust target: %s\n' "$RUST_TOOLCHAIN" "$RUST_TARGET"
	"$RUST_ROOT/bin/rustc" --version
} | tee "$REPORT_DIR/rust-toolchain.txt"
# [/VERIFIED-GOLDEN]
