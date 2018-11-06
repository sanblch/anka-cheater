#!/usr/bin/pwsh

Param(
    [parameter(Mandatory=$true,
               ParameterSetName="Output")]
	  [alias("O")]
	  [String[]]
    $outfile,
    [parameter(Mandatory=$true,
               ValueFromRemainingArguments=$true)]
    [String[]]
    $files
)

# create list of files
$count = 0
$list = "concat-list"
If(Test-Path $list) {
    Remove-Item $list
}
$ext = (Get-Item $files[0]).Extension
ForEach($file in $files) {
    $newfile = "file" + $count + $ext
    $count++
    Copy-Item $file -Destination $newfile
    $str = "file " + $newfile
    Out-File -FilePath $list -InputObject $str -Append -Encoding ascii
}

# main concatenation operation
ffmpeg -safe 0 -f concat -i $list -c copy $outfile -y

# remove temporaries
for($item = 0; $item -lt $count; $item++) {
    $file = "file" + $item + $ext
    Remove-Item $file
}
If(Test-Path $list) {
    Remove-Item $list
}
