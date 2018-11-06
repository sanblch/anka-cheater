#!/usr/bin/pwsh

$file = $args[0]
$num = $args[1]

$IsMP3 = (Split-Path $file -Extension) -like ".MP3"

if($IsMP3) {
    ffmpeg -ar 48000 -t $num -f s16le -acodec pcm_s16le -ac 2 -i /dev/zero -acodec libmp3lame -aq 4 $file
} else {
    Write-Host "Not implemented" -ForegroundColor Red
}


