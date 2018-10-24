#!/usr/bin/pwsh

Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String[]]
    $file,
	[parameter(ParameterSetName="TrackNum")]
	[alias("Audio", "A")]
	[Int]
	$track = 1,
    [parameter(Mandatory=$true,
    ValueFromRemainingArguments=$true)]
    [String[]]
    $timespans
)

If($timespans.Count -eq 0) {
    Write-Host "Program usage:" -ForegroundColor Blue
    Write-Host "    videocut.ps1 video-filename interval1 interval2 ..." -ForegroundColor Green
    Write-Host "    Interval - two timespans delimited with whitespace" -ForegroundColor Blue
    Write-Host "    Format is hh:mm:ss[.f]? or mm:ss[.f]?" -ForegroundColor Blue
    Write-Host "Examples: 01:02:03 01:02:04.5 06:07 06:08.10"
    exit 0
}

If(-Not (Test-Path $file)) {
    Write-Host "File $file not found!" -ForegroundColor Red
    exit 1
}

If($timespans.Count % 2 -eq 1) {
    Write-Host "Check on even number of timespans failed!" -ForegroundColor Red
    Write-Host "Not enough arguments. You've probably mistaken in time intervals." -ForegroundColor Yellow
    Write-Host "Need two numbers in each interval." -ForegroundColor Yellow
    exit 1
}

$del = "\"
If($IsLinux) {
    $del = "/"
}

$ts = @()
For($i = 0; $i -lt $timespans.Count; $i++) {
    $timespan = $timespans[$i]
    If($timespan -Match "(2[0-3]|[0-1][0-9]):[0-5][0-9]:[0-5][0-9]([.]\d*)?") {
        $ts += ([TimeSpan]$timespan).TotalSeconds
    } ElseIf($timespan -Match "[0-5][0-9]:[0-5][0-9]([.]\d*)?") {
        $var = "00:" + $timespan
        $ts += ([TimeSpan]$var).TotalSeconds
    } Else {
        Write-Host "Check on timespan $timespan syntax failed on" -ForegroundColor Red
        Write-Host "                                   $($args[$i])" -ForegroundColor Cyan
        Write-Host "Timespan should be written in the following formats." -ForegroundColor Yellow
        Write-Host "General timespan format:" -ForegroundColor Yellow
        Write-Host "                         hh:mm:ss.f?" -ForegroundColor Green
        Write-Host "Custom timespan format:" -ForegroundColor Yellow
        Write-Host "                         mm:ss.f?" -ForegroundColor Green
        exit 1
    }
}

$IsMP4 = (Get-Item $file).Extension -eq ".MP4"

$intv = @()
$files = @()
For($i = 0; $i -lt $ts.Count / 2; $i++) {
    $var1 = $i * 2
    $var2 = $i * 2 + 1
    $t1 = $ts[$var1]
    $t2 = $ts[$var2] - $t1
    $intv += $intv[-1] + $t2
    $newfile = (Get-Item $file).DirectoryName + $del + "intermediate" + $i;
    If($IsMP4) {
        $newfile += ".ts"
        ffmpeg -ss $t1 -i $file -map 0:$track -c copy -bsf:v h264_mp4toannexb -t $t2 -f mpegts $newfile -y
    } Else {
        $newfile += (Get-Item $file).Extension
        ffmpeg -ss $t1 -i $file -map 0:$track -c copy -t $t2 $newfile -y
    }
    $files += "'" + $newfile + "'"
}

$txtfile = (Get-Item $file).DirectoryName + $del + "videolist.txt"
If(Test-Path $txtfile) {
    Remove-Item $txtfile
}
ForEach($f in $files) {
    $str = "file " + $f
    Out-File -FilePath $txtfile -InputObject $str -Append -Encoding ascii
}
$finalfile = (Get-Item $file).DirectoryName + $del + (Get-Item $file).Basename + "-final" + (Get-Item $file).Extension
If(Test-Path $finalfile) {
    Remove-Item $finalfile
}
If($IsMP4) {
    ffmpeg -safe 0 -f concat -i $txtfile -c copy -bsf:a aac_adtstoasc $finalfile -y
} Else {
    ffmpeg -safe 0 -f concat -i $txtfile -c copy $finalfile -y
}

If(Test-Path $finalfile) {
    Write-Host "Video concatenation successful." -ForegroundColor Blue
    Write-Host "Don't forget to check cutting on beginning, end" -ForegroundColor Blue
    If($ts.Count -ge 4) {
        $str = ""
        ForEach($i in $intv[0..($intv.Count - 2)]) {
            $t = New-TimeSpan -Seconds $i
            $str += " " + $t.ToString()
        }
        Write-Host $("and timespans:" + $str) -ForegroundColor Blue
    }
}