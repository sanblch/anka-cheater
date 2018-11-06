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
$list = "concat-list"
If(Test-Path $list) {
    Remove-Item $list
}
ForEach($file in $files) {
    $str = "file " + $file
    Out-File -FilePath $list -InputObject $str -Append -Encoding UTF8
}

# main concatenation operation
ffmpeg -safe 0 -f concat -i $list -c copy $outfile -y

# remove temporaries
If(Test-Path $list) {
    Remove-Item $list
}
