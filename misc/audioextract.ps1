#!/usr/bin/pwsh

$file = $args[0]

$del = "\"
If($IsLinux) {
    $del = "/"
}

$finalfile = (Get-Item $file).DirectoryName + $del + (Get-Item $file).Basename + ".mp3"

ffmpeg -i $file -q:a 0 -map a $finalfile