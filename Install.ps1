[cmdletbinding()]
param()
$man = Test-ModuleManifest $PSScriptRoot/vim/vim.psd1 -ErrorAction 0

$name = "vim"
[string]$version = $man.Version
$moduleSourceDir = "$PSScriptRoot/vim"
$moduleDir = "~/documents/PowerShell/Modules/$name/$version/"

$newLine = [Environment]::NewLine
$ofs = $newLine
[string]$about_content = Get-Content $PSScriptRoot/README.md | ForEach-Object {
    $_ -replace '```.*', '' 
} 

if (-not (Test-Path $moduleDir))
{
    $null = mkdir $moduleDir
}

Get-ChildItem $moduleSourceDir | copy -Destination $moduleDir
Set-Content -Path $moduleDir/about_${name}.help.txt -value $about_content -Verbose

$cert =Get-ChildItem cert:\CurrentUser\My -CodeSigningCert
if($cert -ne $null)
{
    Get-ChildItem $moduleDir/*.ps?1 | Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll
} 