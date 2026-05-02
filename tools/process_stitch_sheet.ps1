# Convert a Google Stitch 1024x1024 sprite sheet (4x4 grid, RGB with bluish-gray
# checkerboard background) into a 224x320 RGBA sheet ready for the project's
# 56x80 SpriteFrames pipeline.
#
# Pipeline:
#   1. Load source PNG, copy into a 32bppArgb bitmap so we can write alpha.
#   2. Sample the top-left 16x16 region to estimate the checkerboard average
#      gray. Stitch uses two alternating grays; their mean is a good single key.
#   3. LockBits-iterate every pixel and zero alpha for any pixel within
#      $tolerance of the detected key color (per-channel).
#   4. Resize 1024x1024 -> 224x320 with high-quality bilinear so character
#      edges become smoothly anti-aliased against the now-transparent bg.
#   5. Save PNG.
#
# Usage: .\process_stitch_sheet.ps1 -src <path> -dst <path> [-tolerance N]
# Defaults: tolerance=35.

param(
    [Parameter(Mandatory=$true)] [string]$src,
    [Parameter(Mandatory=$true)] [string]$dst,
    [int]$tolerance = 35
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $src)) { throw "Source not found: $src" }
$dstDir = Split-Path -Parent $dst
if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

$srcBmp = [System.Drawing.Bitmap]::new($src)
$w = $srcBmp.Width; $h = $srcBmp.Height

# Copy into a 32bppArgb bitmap so LockBits gives us BGRA bytes.
$rgba = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g0 = [System.Drawing.Graphics]::FromImage($rgba)
$g0.DrawImage($srcBmp, 0, 0)
$g0.Dispose()

# Stitch's checkerboard is two alternating greys. Sampling a tiny corner can
# either land on character pixels (Goku has yellow hair in the top-left) or
# on only one of the two greys, both of which give a wrong key. Instead we
# sample the top 4 rows + bottom 4 rows (8192 pixels almost guaranteed to be
# bg) and pick the two most common grey values — checkerboard greys are
# achromatic so we histogram on R alone.
$hist = New-Object 'int[]' 256
for ($x = 0; $x -lt $w; $x++) {
    for ($y = 0; $y -lt 4; $y++) { $hist[$rgba.GetPixel($x, $y).R]++ }
    for ($y = $h - 4; $y -lt $h; $y++) { $hist[$rgba.GetPixel($x, $y).R]++ }
}
# Top peak.
$peak1 = 0; $peak1V = -1
for ($i = 0; $i -lt 256; $i++) { if ($hist[$i] -gt $peak1V) { $peak1V = $hist[$i]; $peak1 = $i } }
# Second peak — must be at least 20 levels away from the first to be a
# distinct gray rather than a noise neighbor.
$peak2 = -1; $peak2V = -1
for ($i = 0; $i -lt 256; $i++) {
    if ([Math]::Abs($i - $peak1) -lt 20) { continue }
    if ($hist[$i] -gt $peak2V) { $peak2V = $hist[$i]; $peak2 = $i }
}
# If no clear second peak (single-color bg like Gojo's pure white), reuse
# the first so the keying loop still works.
if ($peak2 -lt 0 -or $peak2V -lt ($peak1V / 10)) { $peak2 = $peak1 }
Write-Output ("    bg keys: gray {0} (n={1}) and gray {2} (n={3}), tolerance={4}" -f $peak1, $peak1V, $peak2, $peak2V, $tolerance)

# Key out bg via LockBits — fast pixel iteration.
$rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
$bData = $rgba.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $bData.Stride
$byteCount = $stride * $h
$bytes = [byte[]]::new($byteCount)
[System.Runtime.InteropServices.Marshal]::Copy($bData.Scan0, $bytes, 0, $byteCount)

$keyed = 0
for ($i = 0; $i -lt $byteCount; $i += 4) {
    $b = $bytes[$i]; $g = $bytes[$i + 1]; $r = $bytes[$i + 2]
    # Only treat as bg if the pixel is achromatic (Stitch's checkerboard is
    # always grey — character pixels with similar luminance but any color
    # saturation should NOT get keyed).
    $maxC = [Math]::Max([Math]::Max($r, $g), $b)
    $minC = [Math]::Min([Math]::Min($r, $g), $b)
    if (($maxC - $minC) -gt 12) { continue }
    $lum = ($r + $g + $b) / 3
    if ([Math]::Abs($lum - $peak1) -lt $tolerance -or [Math]::Abs($lum - $peak2) -lt $tolerance) {
        $bytes[$i + 3] = 0
        $keyed++
    }
}
[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $bData.Scan0, $byteCount)
$rgba.UnlockBits($bData)
Write-Output ("    keyed {0:N0} of {1:N0} pixels ({2:P1})" -f $keyed, ($w * $h), ($keyed / ($w * $h)))

# Resize 1024x1024 -> 224x320.
$out = [System.Drawing.Bitmap]::new(224, 320, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gOut = [System.Drawing.Graphics]::FromImage($out)
$gOut.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
$gOut.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gOut.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gOut.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$gOut.DrawImage($rgba, [System.Drawing.Rectangle]::new(0, 0, 224, 320))
$gOut.Dispose()

$out.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("    wrote: $dst")

$out.Dispose(); $rgba.Dispose(); $srcBmp.Dispose()
