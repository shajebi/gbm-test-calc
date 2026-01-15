param(
  [string]$AssetsDir = "docs/presentations/gobuildme-business-deck/assets"
)

$OutDir = Join-Path $AssetsDir 'png'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Have($cmd) {
  $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function RenderSvg($in, $out) {
  if (Have 'rsvg-convert') {
    rsvg-convert -w 1600 $in -o $out
  } elseif (Have 'inkscape') {
    inkscape $in --export-type=png -o $out -w 1600 | Out-Null
  } elseif (Have 'magick') {
    magick -density 300 $in -resize 1600x $out
  } else {
    throw 'No renderer found. Install librsvg (rsvg-convert), Inkscape, or ImageMagick.'
  }
}

Get-ChildItem -Path $AssetsDir -Filter *.svg | ForEach-Object {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
  $out = Join-Path $OutDir "$base.png"
  Write-Host "Rendering $($_.Name) -> $(Split-Path -Leaf $out)"
  RenderSvg $_.FullName $out
}
Write-Host "Done. PNGs at $OutDir"

