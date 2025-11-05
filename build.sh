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

# Optional: show manifest status for debugging
west -vv status || true

# Ensure CMake can find Zephyr; tolerate unset var when -u is enabled
export CMAKE_PREFIX_PATH="/zmk-config/zephyr:${CMAKE_PREFIX_PATH:-}"

# Build left side with nice_view display
west build -d /build/left -p -b eyelash_corne_left \
  -s /zmk-config/zmk/app \
  -- -DSHIELD=nice_view \
     -DZMK_CONFIG=/zmk-config/config

# Build right side with nice_view display
west build -d /build/right -p -b eyelash_corne_right \
  -s /zmk-config/zmk/app \
  -- -DSHIELD=nice_view \
     -DZMK_CONFIG=/zmk-config/config

# Build left side with ZMK Studio support (optional)
west build -d /build/studio_left -p -b eyelash_corne_left \
  -s /zmk-config/zmk/app \
  -- -DSHIELD=nice_view \
     -DZMK_CONFIG=/zmk-config/config \
     -DCONFIG_ZMK_STUDIO=y \
     -DCONFIG_ZMK_STUDIO_LOCKING=n \
     -DSNIPPET=studio-rpc-usb-uart

# Build settings reset
west build -d /build/settings_reset -p -b nice_nano_v2 \
  -s /zmk-config/zmk/app \
  -- -DSHIELD=settings_reset \
     -DZMK_CONFIG=/zmk-config/config

# Copy firmware files to output directory
mkdir -p /output
cp /build/left/zephyr/zmk.uf2 /output/eyelash_corne_left-nice_view-zmk.uf2
cp /build/right/zephyr/zmk.uf2 /output/eyelash_corne_right-nice_view-zmk.uf2
cp /build/studio_left/zephyr/zmk.uf2 /output/eyelash_corne_studio_left-zmk.uf2
cp /build/settings_reset/zephyr/zmk.uf2 /output/settings_reset.uf2

echo ""
echo "Build complete! Firmware files are in /output/"
echo "  - eyelash_corne_left-nice_view-zmk.uf2"
echo "  - eyelash_corne_right-nice_view-zmk.uf2"
echo "  - eyelash_corne_studio_left-zmk.uf2 (with ZMK Studio support)"
echo "  - settings_reset.uf2"
