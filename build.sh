#!/usr/bin/env bash
set -euo pipefail

# Make Git trust bind-mounted repos inside the container
git config --global --add safe.directory /zmk-config/zephyr || true
git config --global --add safe.directory /zmk-config/zmk || true
git config --global --add safe.directory /zmk-config/eyelash_corne || true
git config --global --add safe.directory /zmk-config || true

# Initialize and update west (idempotent init)
west init -l config || true
west update

# Ensure CMake can find Zephyr
export CMAKE_PREFIX_PATH="/zmk-config/zephyr:${CMAKE_PREFIX_PATH:-}"

# Build only what's in build.yaml (matching GitHub Actions)
# Right side build
west build -d /build/eyelash_corne_right -p -b eyelash_corne_right -s /zmk-config/zmk/app -- -DSHIELD=nice_view -DZMK_CONFIG=/zmk-config/config

# Left side with ZMK Studio (this is what build.yaml specifies!)
west build -d /build/eyelash_corne_studio_left -p -b eyelash_corne_left -s /zmk-config/zmk/app -- -DSHIELD=nice_view -DZMK_CONFIG=/zmk-config/config -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -DSNIPPET="studio-rpc-usb-uart"

# Settings reset
west build -d /build/settings_reset -p -b nice_nano_v2 -s /zmk-config/zmk/app -- -DSHIELD=settings_reset -DZMK_CONFIG=/zmk-config/config

# Copy firmware files to output directory
mkdir -p /output
cp /build/eyelash_corne_right/zephyr/zmk.uf2 /output/eyelash_corne_right-nice_view-zmk.uf2
cp /build/eyelash_corne_studio_left/zephyr/zmk.uf2 /output/eyelash_corne_studio_left-zmk.uf2
cp /build/settings_reset/zephyr/zmk.uf2 /output/settings_reset.uf2

echo ""
echo "Build complete! Firmware files are in /output/"
echo "  - eyelash_corne_right-nice_view-zmk.uf2"
echo "  - eyelash_corne_studio_left-zmk.uf2 (Flash this to LEFT side!)"
echo "  - settings_reset.uf2"
echo ""
echo "IMPORTANT: Use studio_left for LEFT side (not a regular left build!)"
