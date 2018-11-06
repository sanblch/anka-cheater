#!/usr/bin/pwsh

$file = $args[0]
$num = $args[1]

$IsMP3 = (Split-Path $file -Extension) -like ".MP3"
$IsOGG = (Split-Path $file -Extension) -like ".OGG"

if($IsMP3) {
    ffmpeg -f lavfi -i anullsrc=r=48000:cl=stereo -t $num -c:a libmp3lame $file
} elseif($IsOGG) {
    ffmpeg -f lavfi -i anullsrc=r=48000:cl=stereo -t $num -c:a libvorbis $file
} else {
    Write-Host "Not implemented" -ForegroundColor Red
}


