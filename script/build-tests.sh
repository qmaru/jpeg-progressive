#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
IMAGE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../images" && pwd)
cd "$IMAGE_DIR"

HDR_DIR="hdr"
JXL_DIR="jxl-features"
ANIMATION_DIR="animation"
ALPHA_DIR="alpha"
SDR_DIR="sdr-comparison"
STANDARD_DIR="sdr-standard-comparison"
JPEG_DIR="jpeg-recompression"
HDR_SOURCE="$HDR_DIR/jxl-rec-2020-16bit.jxl"

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

step() {
    printf '\n=== %s ===\n' "$1"
}

for tool in cjxl djxl magick; do
    command -v "$tool" >/dev/null 2>&1 || fail "Tool not found: $tool"
done
[ -f "$HDR_SOURCE" ] || fail "HDR source file not found: $HDR_SOURCE"

mkdir -p "$JXL_DIR" "$ANIMATION_DIR" "$ALPHA_DIR" "$SDR_DIR" "$STANDARD_DIR" "$JPEG_DIR"

step "Cleaning old generated files"
rm -f \
    "$HDR_DIR/test-hdr.png" \
    "$STANDARD_DIR/test-sdr.png" \
    "$SDR_DIR/test-progressive.png" \
    "$SDR_DIR/test-progressive.jpg" \
    "$STANDARD_DIR/test-standard.jxl" \
    "$SDR_DIR/test-avif.avif" \
    "$STANDARD_DIR/test-avif.avif" \
    "$JXL_DIR/test-lossless.jxl" \
    "$JXL_DIR/test-d0.5.jxl" \
    "$JXL_DIR/test-d1.jxl" \
    "$JXL_DIR/test-d2.jxl" \
    "$JXL_DIR/test-d3.jxl" \
    "$JXL_DIR/test-progressive.jxl" \
    "$ANIMATION_DIR/test-animation.gif" \
    "$ANIMATION_DIR/test-animation.jxl" \
    "$ANIMATION_DIR/test-animation.webp" \
    "$ANIMATION_DIR/test-animation.avif" \
    "$ALPHA_DIR/test-alpha.png" \
    "$ALPHA_DIR/test-alpha.jxl" \
    "$ALPHA_DIR/test-alpha.webp" \
    "$ALPHA_DIR/test-alpha.avif" \
    "$STANDARD_DIR/test.jpg" \
    "$STANDARD_DIR/test.webp" \
    "$SDR_DIR/test.webp" \
    "$SDR_DIR/test-compare.jxl" \
    "$JPEG_DIR/test-recompressed.jxl" \
    "$JPEG_DIR/test-recovered.jpg" \
    "$ANIMATION_DIR"/test-animation-0*.png

step "1. Decode original HDR JXL"
djxl "$HDR_SOURCE" "$HDR_DIR/test-hdr.png"

step "2. JXL native features"
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-lossless.jxl" -d 0
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-d0.5.jxl" -d 0.5
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-d1.jxl" -d 1
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-d2.jxl" -d 2
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-d3.jxl" -d 3
cjxl "$HDR_DIR/test-hdr.png" "$JXL_DIR/test-progressive.jxl" --progressive

step "3. Generate SDR master"
magick "$HDR_DIR/test-hdr.png" -colorspace RGB -colorspace sRGB -depth 8 "$STANDARD_DIR/test-sdr.png"

step "4. SDR format comparison"
magick "$STANDARD_DIR/test-sdr.png" -quality 95 -strip "$STANDARD_DIR/test.jpg"
magick "$STANDARD_DIR/test-sdr.png" -quality 95 -strip "$STANDARD_DIR/test.webp"
cp "$STANDARD_DIR/test.webp" "$SDR_DIR/test.webp"
cjxl "$STANDARD_DIR/test-sdr.png" "$SDR_DIR/test-compare.jxl" -d 1 --progressive
cjxl "$STANDARD_DIR/test-sdr.png" "$STANDARD_DIR/test-standard.jxl" -d 1
magick "$STANDARD_DIR/test-sdr.png" -quality 80 -strip "$SDR_DIR/test-avif.avif"
cp "$SDR_DIR/test-avif.avif" "$STANDARD_DIR/test-avif.avif"
magick "$STANDARD_DIR/test-sdr.png" -interlace PNG -strip "$SDR_DIR/test-progressive.png"
magick "$STANDARD_DIR/test-sdr.png" -quality 95 -interlace Plane -strip "$SDR_DIR/test-progressive.jpg"

step "5. JPEG recompression"
cjxl "$STANDARD_DIR/test.jpg" "$JPEG_DIR/test-recompressed.jxl"
djxl "$JPEG_DIR/test-recompressed.jxl" "$JPEG_DIR/test-recovered.jpg"

step "6. Alpha"
magick "$STANDARD_DIR/test-sdr.png" -alpha set -channel A -evaluate set 50% +channel "$ALPHA_DIR/test-alpha.png"
cjxl "$ALPHA_DIR/test-alpha.png" "$ALPHA_DIR/test-alpha.jxl" -d 0
magick "$ALPHA_DIR/test-alpha.png" -quality 90 -strip "$ALPHA_DIR/test-alpha.webp"
magick "$ALPHA_DIR/test-alpha.png" -quality 80 -strip "$ALPHA_DIR/test-alpha.avif"

step "7. Animation source frames"
WIDTH=$(magick identify -format "%w" "$STANDARD_DIR/test-sdr.png")
HEIGHT=$(magick identify -format "%h" "$STANDARD_DIR/test-sdr.png")
frame=1
while [ "$frame" -le 6 ]; do
    frame_file=$(printf '%s/test-animation-%02d.png' "$ANIMATION_DIR" "$frame")
    x=$((40 + ((WIDTH - 80) * (frame - 1) / 5)))
    y=$((HEIGHT / 2))
    magick "$STANDARD_DIR/test-sdr.png" -fill "rgba(255,0,0,0.85)" -stroke white -strokewidth 4 -draw "circle $x,$y $((x + 32)),$y" "$frame_file"
    frame=$((frame + 1))
done

magick \
    -delay 8 "$ANIMATION_DIR/test-animation-01.png" \
    -delay 12 "$ANIMATION_DIR/test-animation-02.png" \
    -delay 20 "$ANIMATION_DIR/test-animation-03.png" \
    -delay 40 "$ANIMATION_DIR/test-animation-04.png" \
    -delay 12 "$ANIMATION_DIR/test-animation-05.png" \
    -delay 8 "$ANIMATION_DIR/test-animation-06.png" \
    -loop 0 "$ANIMATION_DIR/test-animation.gif"
cjxl "$ANIMATION_DIR/test-animation.gif" "$ANIMATION_DIR/test-animation.jxl"
magick "$ANIMATION_DIR/test-animation.gif" -quality 80 "$ANIMATION_DIR/test-animation.webp"
magick "$ANIMATION_DIR/test-animation.gif" -quality 80 "$ANIMATION_DIR/test-animation.avif"

step "8. Remove intermediate files"
rm -f "$HDR_DIR/test-hdr.png" "$ANIMATION_DIR"/test-animation-0*.png

step "DONE"
find . -type f \( \
    -path "./$JXL_DIR/*" -o \
    -path "./$ANIMATION_DIR/*" -o \
    -path "./$ALPHA_DIR/*" -o \
    -path "./$SDR_DIR/*" -o \
    -path "./$STANDARD_DIR/*" -o \
    -path "./$JPEG_DIR/*" \
\) -print
