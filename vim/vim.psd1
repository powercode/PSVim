
@{

# Script module or binary module file associated with this manifest.
RootModule = 'vim.psm1'

# Version number of this module.
ModuleVersion = '2.0.0'

# ID used to uniquely identify this module
GUID = '365a4946-0f1e-4448-8aee-6dcfd34b840c'

# Author of this module
Author = 'PowerCode'

# Company or vendor of this module
CompanyName = 'PowerCode'

# Copyright statement for this module
Copyright = '(c) 2016 PowerCode. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Open files in gvim from the PowerShell pipeline.'

# Functions to export from this module
FunctionsToExport = 'Invoke-Gvim'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = 'igv','gvim','vim'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @('vim.psd1', 'vim.psm1', 'about_vim.help.txt')


 
PrivateData = @{ 
     PSData = @{         
         Tags = @('gvim','vi','errorfile')         
         LicenseUri = 'https://github.com/powercode/PSVim/blob/master/LICENSE' 
         ProjectUri = 'https://github.com/powercode/PSVim'   
         ReleaseNotes = @'
Initial PSGallery release of Vim module, providing pipelining into gvim. 
By using the errorfile feature in gvim, it is possible to quickly navigate between
files and MatchResults from Select-String.

PS>gci *.ps1 -recurse | sls MyClass | Invoke-Gvim

In gvim, you can now use :cn and :cp to navigate between the matches, and use :bn, :bp
to navigate between the files 
'@                 
     } # End of PSData hashtable 
 
 
} # End of PrivateData hashtable 
}

