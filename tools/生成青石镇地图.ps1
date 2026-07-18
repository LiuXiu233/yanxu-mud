$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $root 'examples\青石镇\web'
$outputPath = Join-Path $outputDirectory 'qingshi-map.png'
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

$bitmap = [System.Drawing.Bitmap]::new(1600, 900)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(238, 243, 239))

    $random = [System.Random]::new(42)
    $texturePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(20, 49, 72, 64), 1)
    try {
        for ($index = 0; $index -lt 260; $index++) {
            $x = $random.Next(30, 1570)
            $y = $random.Next(30, 870)
            $length = $random.Next(5, 20)
            $graphics.DrawLine($texturePen, $x, $y, ($x + $length), ($y + $random.Next(-2, 3)))
        }
    }
    finally {
        $texturePen.Dispose()
    }

    $riverPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(72, 158, 177), 56)
    $riverHighlight = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(178, 222, 224), 7)
    try {
        $riverPoints = [System.Drawing.Point[]]@(
            [System.Drawing.Point]::new(-40, 790),
            [System.Drawing.Point]::new(280, 748),
            [System.Drawing.Point]::new(560, 770),
            [System.Drawing.Point]::new(850, 738),
            [System.Drawing.Point]::new(1160, 772),
            [System.Drawing.Point]::new(1640, 730)
        )
        $graphics.DrawCurve($riverPen, $riverPoints, 0.4)
        $graphics.DrawCurve($riverHighlight, $riverPoints, 0.4)
    }
    finally {
        $riverPen.Dispose()
        $riverHighlight.Dispose()
    }

    $rooms = [ordered]@{
        '竹林' = [System.Drawing.Point]::new(700, 80)
        '北郊' = [System.Drawing.Point]::new(700, 205)
        '镇守府' = [System.Drawing.Point]::new(700, 330)
        '茶馆' = [System.Drawing.Point]::new(700, 455)
        '中央街' = [System.Drawing.Point]::new(700, 590)
        '镇南门' = [System.Drawing.Point]::new(700, 705)
        '青石桥' = [System.Drawing.Point]::new(700, 820)
        '客栈' = [System.Drawing.Point]::new(445, 590)
        '集市' = [System.Drawing.Point]::new(955, 590)
        '铁匠铺' = [System.Drawing.Point]::new(1215, 590)
        '药铺' = [System.Drawing.Point]::new(955, 455)
        '祠堂' = [System.Drawing.Point]::new(955, 330)
        '废井' = [System.Drawing.Point]::new(1215, 330)
    }

    $edges = @(
        @('竹林', '北郊'), @('北郊', '镇守府'), @('镇守府', '茶馆'),
        @('茶馆', '中央街'), @('中央街', '镇南门'), @('镇南门', '青石桥'),
        @('中央街', '客栈'), @('中央街', '集市'), @('集市', '铁匠铺'),
        @('集市', '药铺'), @('茶馆', '祠堂'), @('祠堂', '废井')
    )

    $roadShadow = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(132, 144, 137), 22)
    $roadPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(218, 224, 217), 13)
    try {
        foreach ($edge in $edges) {
            $from = $rooms[$edge[0]]
            $to = $rooms[$edge[1]]
            $graphics.DrawLine($roadShadow, $from, $to)
            $graphics.DrawLine($roadPen, $from, $to)
        }
    }
    finally {
        $roadShadow.Dispose()
        $roadPen.Dispose()
    }

    $forestBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(59, 111, 79))
    $forestLight = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(111, 158, 111))
    try {
        for ($index = 0; $index -lt 30; $index++) {
            $x = 480 + $random.Next(0, 440)
            $y = 26 + $random.Next(0, 105)
            $graphics.FillEllipse($(if ($index % 3 -eq 0) { $forestLight } else { $forestBrush }), $x, $y, 18, 38)
        }
    }
    finally {
        $forestBrush.Dispose()
        $forestLight.Dispose()
    }

    $fontPath = Join-Path $env:WINDIR 'Fonts\msyh.ttc'
    $labelFont = if (Test-Path -LiteralPath $fontPath) {
        [System.Drawing.Font]::new('Microsoft YaHei', 24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    }
    else {
        [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericSansSerif, 24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    }
    $titleFont = [System.Drawing.Font]::new($labelFont.FontFamily, 42, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = [System.Drawing.Font]::new($labelFont.FontFamily, 18, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 47, 44))
    $mutedBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(78, 91, 86))
    $roomBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(250, 252, 249))
    $roomBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(45, 66, 59), 4)
    $accentBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(203, 82, 67))
    try {
        $graphics.DrawString('青石镇图', $titleFont, $textBrush, 78, 62)
        $graphics.DrawString('道路、郊野与镇中十三处地点', $smallFont, $mutedBrush, 82, 118)

        foreach ($entry in $rooms.GetEnumerator()) {
            $point = $entry.Value
            $isCenter = $entry.Key -eq '中央街'
            $width = if ($isCenter) { 152 } else { 126 }
            $height = 60
            $x = $point.X - [int]($width / 2)
            $y = $point.Y - [int]($height / 2)
            $graphics.FillRectangle($roomBrush, $x, $y, $width, $height)
            $graphics.DrawRectangle($roomBorder, $x, $y, $width, $height)
            if ($isCenter) {
                $graphics.FillRectangle($accentBrush, $x, $y, 8, $height)
            }
            $size = $graphics.MeasureString($entry.Key, $labelFont)
            $graphics.DrawString($entry.Key, $labelFont, $textBrush, ($point.X - ($size.Width / 2)), ($point.Y - ($size.Height / 2)))
        }

        $graphics.DrawString('浅溪', $smallFont, $mutedBrush, 1260, 785)
        $graphics.DrawString('北', $labelFont, $textBrush, 1480, 88)
        $graphics.DrawLine($roomBorder, 1492, 130, 1492, 195)
        $graphics.FillPolygon($accentBrush, [System.Drawing.Point[]]@(
            [System.Drawing.Point]::new(1492, 115),
            [System.Drawing.Point]::new(1481, 139),
            [System.Drawing.Point]::new(1503, 139)
        ))
    }
    finally {
        $labelFont.Dispose()
        $titleFont.Dispose()
        $smallFont.Dispose()
        $textBrush.Dispose()
        $mutedBrush.Dispose()
        $roomBrush.Dispose()
        $roomBorder.Dispose()
        $accentBrush.Dispose()
    }

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}

Get-Item -LiteralPath $outputPath | Select-Object FullName, Length
