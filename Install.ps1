
$man = Test-ModuleManifest $PSScriptRoot/vim/vim.psd1

$name = $man.Name
[string]$version = $man.Version
$moduleSourceDir = "$PSScriptRoot/vim"
$moduleDir = "~/documents/WindowsPowerShell/Modules/$name/$version/"

$newLine = [Environment]::NewLine
$ofs = $newLine
[string]$about_content = Get-Content $PSScriptRoot/README.md | foreach {
    $_ -replace '```.*', ''    
} 

if (-not (Test-Path $moduleDir))
{
    $null = mkdir $moduleDir
}

Get-ChildItem $moduleSourceDir | copy -Destination $moduleDir
Set-Content -Path $moduleDir/about_${name}.help.txt -value $about_content

$cert =Get-ChildItem cert:\CurrentUser\My -CodeSigningCert
Get-ChildItem $moduleDir/*.ps?1 | Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll 