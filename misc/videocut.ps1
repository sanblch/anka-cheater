#!/usr/bin/pwsh

$file = $args[0]
$t1 = $args[1]
$t2 = $args[2]

If($args.Count % 2 -eq 0) {
    Write-Host "Check on odd number of arguments failed!" -ForegroundColor Red
    Write-Host "Not enough arguments. You've probably mistaken in time intervals." -ForegroundColor Yellow
    Write-Host "Need two numbers in each interval." -ForegroundColor Yellow
    exit 1
}

$ts = @()
For($i = 1; $i -lt $args.Count; $i++) {
    If($args[$i] -Match "(2[0-3]|[0-1][0-9]):[0-5][0-9]:[0-5][0-9]([.]\d*)?") {
        $ts += ([TimeSpan]$args[$i]).TotalSeconds
    } ElseIf($args[$i] -Match "[0-5][0-9]:[0-5][0-9]([.]\d*)?") {
        $var = "00:" + $args[$i]
        $ts += ([TimeSpan]$var).TotalSeconds
    } Else {
        Write-Host "Check on timespan syntax failed on" -ForegroundColor Red
        Write-Host "                                   $($args[$i])" -ForegroundColor Cyan
        Write-Host "Timespan should be written in the following formats." -ForegroundColor Yellow
        Write-Host "General timespan format:" -ForegroundColor Yellow
        Write-Host "                         hh:mm:ss.f?" -ForegroundColor Green
        Write-Host "Custom timespan format:" -ForegroundColor Yellow
        Write-Host "                         mm:ss.f?" -ForegroundColor Green
        exit 1
    }
}

$isMP4 = (Get-Item $file).Extension -eq ".MP4"

$files = @()
For($i = 0; $i -lt $ts.Count / 2; $i++) {
    $var1 = $i * 2
    $var2 = $i * 2 + 1
    $t1 = $ts[$var1]
    $t2 = $ts[$var2] - $t1
    $newfile = (Get-Item $file).DirectoryName + "/" + "intermediate" + $i;
    If($isMP4) {
        $newfile += ".ts"
        ffmpeg -ss $t1 -i $file -c copy -bsf:v h264_mp4toannexb -t $t2 -f mpegts $newfile -y
    } Else {
        $newfile += (Get-Item $file).Extension
        ffmpeg -ss $t1 -i $file -c copy -t $t2 $newfile -y
    }
    $files += "'" + $newfile + "'"
}

$txtfile = (Get-Item $file).DirectoryName + "/" + "videolist.txt"
If(Test-Path $txtfile) {
    Remove-Item $txtfile
}
ForEach($f in $files) {
    $str = "file " + $f
    Out-File -FilePath $txtfile -InputObject $str -Append
}
$finalfile = (Get-Item $file).DirectoryName + "/" + (Get-Item $file).Basename + "-final" + (Get-Item $file).Extension
If($isMP4) {
    ffmpeg -safe 0 -f concat -i $txtfile -c copy -bsf:a aac_adtstoasc $finalfile -y
} Else {
    ffmpeg -safe 0 -f concat -i $txtfile -c copy $finalfile -y
}
