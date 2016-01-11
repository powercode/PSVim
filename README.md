Vim Module
==========

Gems for using PowerShell with vim.

This module is intented for the gigantic intersection of PowerShell and Vim users.

Installation
------------
Install from the PowerShell Gallery
```powershell
Install-Module vim
```

Usage
-----
To start using the vim module, just import the module

```powershell
Import-Module vim
```

Invoke-Gvim
-----------

Using the -Errorfile option of gvim to quickly jump between files or matches from Select-String.

This uses the QuickFix vim feature.
The following errorformat is assumed: %f:%l:%c:%m

In the same way as you can jump between compilation errors in vim, you can now jump between files or matches piped into
Invoke-Gvim

```powershell
Get-ChildItem -Recurse -Filter *.cs | Select-String throw | Invoke-GVim
# The example above open gvim with all locations where an exception in the error list

Get-ChildItem -Recurse -Filter *.txt | Select-String 'aaa(bbb)ccc' | Invoke-GVim
# The example above open gvim with all textfiles containg 'aaabbbccc' with the selection on the first regex group.
# If the regex contains a group, the cursor placed on the start of the first group match.
# some text aaabbbccc
#              ^ cursor


ls *.txt | igv
# open all text files in the current directory

# Reuse a gvim window
ls *.ps1 | sls function | igv -ReuseInstance
```
The above examples open gvim with all locations where an exception in the error list

By adding the following to _vimrc it is quick and easy to jump between the hits with F2 or F3 
```
nnoremap <silent> <F2> :bn<CR>
nnoremap <silent> <S-F2> :bp<CR>
nnoremap <silent> <F3> :cn<CR>
nnoremap <silent> <S-F3> :cp<CR>
```
