$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$imageDir = Join-Path (Split-Path -Parent $PSScriptRoot) "images"
Set-Location $imageDir

$hdrDir = "hdr"
$jxlDir = "jxl-features"
$animationDir = "animation"
$alphaDir = "alpha"
$sdrDir = "sdr-comparison"
$standardDir = "sdr-standard-comparison"
$jpegDir = "jpeg-recompression"

New-Item -ItemType Directory -Force -Path @(
    $jxlDir,
    $animationDir,
    $alphaDir,
    $sdrDir,
    $standardDir,
    $jpegDir
) | Out-Null

$hdrSource = Join-Path $hdrDir "jxl-rec-2020-16bit.jxl"

Write-Host "=== Checking tools ===" -ForegroundColor Cyan

foreach ($tool in @("cjxl", "djxl", "magick")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Tool not found: $tool"
    }
}

if (-not (Test-Path $hdrSource)) {
    throw "HDR source file not found: $hdrSource"
}

Write-Host "=== Cleaning old generated files ===" -ForegroundColor Cyan

$generatedFiles = @(
    "$hdrDir\test-hdr.png",
    "$standardDir\test-sdr.png",
    "$sdrDir\test-progressive.png",
    "$sdrDir\test-progressive.jpg",
    "$standardDir\test-standard.jxl",
    "$sdrDir\test-avif.avif",
    "$standardDir\test-avif.avif",
    "$jxlDir\test-lossless.jxl",
    "$jxlDir\test-d0.5.jxl",
    "$jxlDir\test-d1.jxl",
    "$jxlDir\test-d2.jxl",
    "$jxlDir\test-d3.jxl",
    "$jxlDir\test-progressive.jxl",
    "$animationDir\test-animation.gif",
    "$animationDir\test-animation.jxl",
    "$animationDir\test-animation.webp",
    "$animationDir\test-animation.avif",
    "$alphaDir\test-alpha.png",
    "$alphaDir\test-alpha.jxl",
    "$alphaDir\test-alpha.webp",
    "$alphaDir\test-alpha.avif",
    "$standardDir\test.jpg",
    "$standardDir\test.webp",
    "$sdrDir\test.webp",
    "$sdrDir\test-compare.jxl",
    "$jpegDir\test-recompressed.jxl",
    "$jpegDir\test-recovered.jpg",
    "$animationDir\test-animation-01.png",
    "$animationDir\test-animation-02.png",
    "$animationDir\test-animation-03.png",
    "$animationDir\test-animation-04.png",
    "$animationDir\test-animation-05.png",
    "$animationDir\test-animation-06.png"
)

foreach ($file in $generatedFiles) {
    Remove-Item $file -Force -ErrorAction SilentlyContinue
}

# ============================================================
# 1. Original HDR JXL -> HDR PNG
# ============================================================

Write-Host ""
Write-Host "=== 1. Decode original HDR JXL ===" -ForegroundColor Cyan

djxl $hdrSource "$hdrDir\test-hdr.png"

# ============================================================
# 2. JXL native: lossless + lossy + progressive
# ============================================================

Write-Host ""
Write-Host "=== 2. JXL native features ===" -ForegroundColor Cyan

cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-lossless.jxl" -d 0

cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-d0.5.jxl" -d 0.5
cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-d1.jxl"   -d 1
cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-d2.jxl"   -d 2
cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-d3.jxl"   -d 3

cjxl "$hdrDir\test-hdr.png" "$jxlDir\test-progressive.jxl" --progressive

# ============================================================
# 3. SDR conversion
#    HDR source -> SDR sRGB
# ============================================================

Write-Host ""
Write-Host "=== 3. Generate SDR master ===" -ForegroundColor Cyan

magick "$hdrDir\test-hdr.png" `
    -colorspace RGB `
    -colorspace sRGB `
    -depth 8 `
    "$standardDir\test-sdr.png"

# ============================================================
# 4. SDR format comparison
#    Same SDR source -> PNG / JPEG / WebP / JXL
# ============================================================

Write-Host ""
Write-Host "=== 4. SDR format comparison ===" -ForegroundColor Cyan

magick "$standardDir\test-sdr.png" `
    -quality 95 `
    -strip `
    "$standardDir\test.jpg"

magick "$standardDir\test-sdr.png" `
    -quality 95 `
    -strip `
    "$standardDir\test.webp"

Copy-Item "$standardDir\test.webp" "$sdrDir\test.webp" -Force

cjxl "$standardDir\test-sdr.png" "$sdrDir\test-compare.jxl" -d 1 --progressive
cjxl "$standardDir\test-sdr.png" "$standardDir\test-standard.jxl" -d 1

magick "$standardDir\test-sdr.png" `
    -quality 80 `
    -strip `
    "$sdrDir\test-avif.avif"

Copy-Item "$sdrDir\test-avif.avif" "$standardDir\test-avif.avif" -Force

magick "$standardDir\test-sdr.png" `
    -interlace PNG `
    -strip `
    "$sdrDir\test-progressive.png"

magick "$standardDir\test-sdr.png" `
    -quality 95 `
    -interlace Plane `
    -strip `
    "$sdrDir\test-progressive.jpg"

# ============================================================
# 5. JPEG recompression
# ============================================================

Write-Host ""
Write-Host "=== 5. JPEG recompression ===" -ForegroundColor Cyan

cjxl "$standardDir\test.jpg" "$jpegDir\test-recompressed.jxl"

djxl "$jpegDir\test-recompressed.jxl" "$jpegDir\test-recovered.jpg"

# ============================================================
# 6. Alpha
#    SDR master + alpha gradient
# ============================================================

Write-Host ""
Write-Host "=== 6. Alpha ===" -ForegroundColor Cyan

magick "$standardDir\test-sdr.png" `
    -alpha set `
    -channel A `
    -evaluate set 50% `
    +channel `
    "$alphaDir\test-alpha.png"

cjxl "$alphaDir\test-alpha.png" "$alphaDir\test-alpha.jxl" -d 0

magick "$alphaDir\test-alpha.png" `
    -quality 90 `
    -strip `
    "$alphaDir\test-alpha.webp"

magick "$alphaDir\test-alpha.png" `
    -quality 80 `
    -strip `
    "$alphaDir\test-alpha.avif"

# ============================================================
# 7. Animation
#    Generate obvious moving frames from SDR master
# ============================================================

Write-Host ""
Write-Host "=== 7. Animation source frames ===" -ForegroundColor Cyan

$w = (magick identify -format "%w" "$standardDir\test-sdr.png")
$h = (magick identify -format "%h" "$standardDir\test-sdr.png")

# 6 frames: a clearly visible moving circle
for ($i = 0; $i -lt 6; $i++) {

    $frame = "$animationDir\test-animation-{0:D2}.png" -f ($i + 1)

    $x = [int](40 + (($w - 80) * $i / 5))
    $y = [int]($h / 2)

    magick "$standardDir\test-sdr.png" `
        -fill "rgba(255,0,0,0.85)" `
        -stroke "white" `
        -strokewidth 4 `
        -draw "circle $x,$y $($x + 32),$y" `
        $frame
}

# Non-uniform frame durations:
# 80, 120, 200, 400, 120, 80 ms
magick `
    -delay 8 `
    "$animationDir\test-animation-01.png" `
    -delay 12 `
    "$animationDir\test-animation-02.png" `
    -delay 20 `
    "$animationDir\test-animation-03.png" `
    -delay 40 `
    "$animationDir\test-animation-04.png" `
    -delay 12 `
    "$animationDir\test-animation-05.png" `
    -delay 8 `
    "$animationDir\test-animation-06.png" `
    -loop 0 `
    "$animationDir\test-animation.gif"

cjxl "$animationDir\test-animation.gif" "$animationDir\test-animation.jxl"

magick "$animationDir\test-animation.gif" `
    -quality 80 `
    "$animationDir\test-animation.webp"

magick "$animationDir\test-animation.gif" `
    -quality 80 `
    "$animationDir\test-animation.avif"

# ============================================================
# 8. Remove intermediate files
# ============================================================

Write-Host ""
Write-Host "=== 8. Remove intermediate files ===" -ForegroundColor Cyan

Remove-Item `
    "$hdrDir\test-hdr.png", `
    "$animationDir\test-animation-01.png",
    "$animationDir\test-animation-02.png",
    "$animationDir\test-animation-03.png",
    "$animationDir\test-animation-04.png",
    "$animationDir\test-animation-05.png",
    "$animationDir\test-animation-06.png" `
    -Force `
    -ErrorAction SilentlyContinue

# ============================================================
# 9. Summary
# ============================================================

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host ""

Get-ChildItem `
    "$standardDir\test-sdr.png",
    "$sdrDir\test-progressive.png",
    "$sdrDir\test-progressive.jpg",
    "$standardDir\test-standard.jxl",
    "$sdrDir\test-avif.avif",
    "$jxlDir\test-lossless.jxl",
    "$jxlDir\test-d0.5.jxl",
    "$jxlDir\test-d1.jxl",
    "$jxlDir\test-d2.jxl",
    "$jxlDir\test-d3.jxl",
    "$jxlDir\test-progressive.jxl",
    "$animationDir\test-animation.gif",
    "$animationDir\test-animation.jxl",
    "$animationDir\test-animation.webp",
    "$animationDir\test-animation.avif",
    "$alphaDir\test-alpha.png",
    "$alphaDir\test-alpha.jxl",
    "$alphaDir\test-alpha.webp",
    "$alphaDir\test-alpha.avif",
    "$standardDir\test.jpg",
    "$standardDir\test.webp",
    "$sdrDir\test-compare.jxl",
    "$jpegDir\test-recompressed.jxl",
    "$jpegDir\test-recovered.jpg" |
    Select-Object Name, Length