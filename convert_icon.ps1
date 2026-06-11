Add-Type -AssemblyName System.Drawing

$pngPath = 'D:\Soniqo\assets\poster\applogo.png'
$icoPath = 'D:\Soniqo\windows\runner\resources\app_icon.ico'

$bitmap = New-Object System.Drawing.Bitmap($pngPath)

$sizes = @(16, 32, 48, 64, 128, 256)

$stream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($stream)

# ICO header: reserved=0, type=1 (ICO), count=number of images
$writer.Write([int16]0)
$writer.Write([int16]1)
$writer.Write([int16]$sizes.Count)

# Generate all image byte arrays first
$imageData = New-Object System.Collections.Generic.List[byte[]]
foreach ($size in $sizes) {
    $img = New-Object System.Drawing.Bitmap($bitmap, (New-Object System.Drawing.Size($size, $size)))
    $ms = New-Object System.IO.MemoryStream
    $img.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $imageData.Add($ms.ToArray())
    $img.Dispose()
    $ms.Dispose()
}

# Calculate data start offset: 6 (header) + 16 * count (directory entries)
$dataOffset = 6 + (16 * $sizes.Count)

# Write directory entries
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $w = if ($s -eq 256) { 0 } else { $s }
    $h = if ($s -eq 256) { 0 } else { $s }
    $writer.Write([byte]$w)
    $writer.Write([byte]$h)
    $writer.Write([byte]0)    # color palette
    $writer.Write([byte]0)    # reserved
    $writer.Write([int16]1)   # color planes
    $writer.Write([int16]32)  # bits per pixel
    $writer.Write([int32]$imageData[$i].Length)
    $writer.Write([int32]$dataOffset)
    $dataOffset += $imageData[$i].Length
}

# Write image pixel data
foreach ($data in $imageData) {
    $writer.Write($data)
}

$writer.Flush()
[System.IO.File]::WriteAllBytes($icoPath, $stream.ToArray())

$bitmap.Dispose()
$stream.Dispose()
$writer.Dispose()

Write-Host "SUCCESS: ICO saved to $icoPath"
Write-Host "File size: $((Get-Item $icoPath).Length) bytes"
