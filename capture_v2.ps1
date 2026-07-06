Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Helper {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool AllowSetForegroundWindow(int dwProcessId);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
}
"@

$workspace = "C:\Users\jedsa\OneDrive\Desktop\Code\weightlifting_tracker"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$sw = $screen.Width; $sh = $screen.Height

# Win+D: show desktop, clear all windows
[Win32Helper]::keybd_event(0x5B, 0, 0, 0)
[Win32Helper]::keybd_event(0x44, 0, 0, 0)
[Win32Helper]::keybd_event(0x44, 0, 2, 0)
[Win32Helper]::keybd_event(0x5B, 0, 2, 0)
Start-Sleep -Seconds 3

for ($i = 1; $i -le 11; $i++) {
    # Kill Edge completely
    Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    # Allow background process to steal foreground
    [Win32Helper]::AllowSetForegroundWindow(-1)

    # Open the HTML file directly in Edge, maximized
    $htmlFile = Join-Path $workspace "diagram_$i.html"
    $url = "file:///" + $htmlFile.Replace("\", "/")
    $proc = Start-Process -FilePath $edge -ArgumentList "--new-window", "--start-maximized", $url -PassThru

    # Wait for page to load
    Start-Sleep -Seconds 12

    # Force Edge to foreground via all handles
    $edgeProcs = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
    foreach ($ep in $edgeProcs) {
        if ($ep.MainWindowHandle -ne [IntPtr]::Zero) {
            [Win32Helper]::ShowWindow($ep.MainWindowHandle, 3)
            [Win32Helper]::BringWindowToTop($ep.MainWindowHandle)
            [Win32Helper]::SetForegroundWindow($ep.MainWindowHandle)
        }
    }
    Start-Sleep -Seconds 2

    # Capture screen
    $bmp = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, [System.Drawing.Size]::new($sw, $sh))
    $g.Dispose()

    # Check if capture is valid (center pixel not pure black)
    $centerColor = $bmp.GetPixel($sw / 2, $sh / 2)
    $brightness = ($centerColor.R + $centerColor.G + $centerColor.B) / 3
    if ($brightness -lt 30) {
        Write-Output "WARNING: diagram_$i capture looks black (brightness=$brightness), retrying..."
        Start-Sleep -Seconds 5
        $g2 = [System.Drawing.Graphics]::FromImage($bmp)
        $g2.CopyFromScreen(0, 0, 0, 0, [System.Drawing.Size]::new($sw, $sh))
        $g2.Dispose()
    }

    # Crop: remove Edge toolbar (top ~82px) and taskbar (bottom ~40px)
    $cropY = 82; $cropH = $sh - 82 - 40
    $cropRect = New-Object System.Drawing.Rectangle(0, $cropY, $sw, $cropH)
    $cropped = $bmp.Clone($cropRect, $bmp.PixelFormat)
    $bmp.Dispose()

    $outFile = Join-Path $workspace "diagram_$i.png"
    $cropped.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $cropped.Dispose()
    Write-Output "Saved diagram_$i.png (brightness=$brightness)"
}

Write-Output "DONE"
