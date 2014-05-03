$reuseInstanceName='PsVim'

$gvimPath = (Get-ItemProperty HKLM:\SOFTWARE\Vim\Gvim -Name Path).Path

$vimDir = Split-Path $gvimPath

Set-Alias gvim $vimDir\gvim.exe 
Set-Alias vim  $vimDir\vim.exe

. $PSScriptRoot\errorfile.ps1

Set-Alias stve Start-VimErrorFile

Export-ModuleMember Start-VimErrorFile,Set-VimReuseInstanceName
Export-ModuleMember -alias gvim, stve
