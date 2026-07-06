Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$workspace = "C:\Users\jedsa\OneDrive\Desktop\Code\weightlifting_tracker"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Get actual screen dimensions
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$sw = $screen.Width
$sh = $screen.Height

Write-Host "Screen: ${sw}x${sh}"

# Crop: below Edge address bar, full width
# Edge tabs+toolbar ~82px from top
$cropX = 0
$cropY = 82
$cropW = $sw
$cropH = $sh - 82 - 40  # subtract taskbar ~40px

for ($i = 1; $i -le 11; $i++) {
    $htmlFile = Join-Path $workspace "diagram_$i.html"
    
    # Open in Edge
    Start-Process -FilePath $edge -ArgumentList "`"$htmlFile`""
    
    # Wait for Edge to fully render
    Start-Sleep -Seconds 7
    
    # Take full screenshot
    $bmp = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, [System.Drawing.Size]::new($sw, $sh))
    $g.Dispose()
    
    # Crop to Edge content area
    $cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)
    $cropped = $bmp.Clone($cropRect, $bmp.PixelFormat)
    $bmp.Dispose()
    
    # Save as PNG
    $outputFile = Join-Path $workspace "diagram_$i.png"
    $cropped.Save($outputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $cropped.Dispose()
    
    Write-Host "Saved diagram_$i.png"
}

Write-Host "All 11 diagrams captured!"
