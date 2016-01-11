$man = Test-ModuleManifest $PSScriptRoot/vim/vim.psd1

$name = $man.Name
[string]$version = $man.Version

Publish-Module -Name $name -RequiredVersion $version -NuGetApiKey $NuGetApiKey -Repository PSGallery
