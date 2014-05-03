PSVim
=====

Gems for using PowerShell with vim.

This module is intented for the gigantic intersection of PowerShell and Vim users.

Usage
-----
To start using, just import the module

```powershell
Import-Module vim
```

Start-VimErrorFile
------------------

Using the --errorfile option of gvim to quickly jump between files or matches from Select-String.

In the same way as you can jump between compilation errors in vim, you can now jump between files or matches piped into
Start-VimErrorFile

```powershell
Get-ChildItem -Recurse -Filter *.cs | Select-String throw | Start-VimErrorFile

ls *.txt | stve

# open a new gvim window
ls *.ps1 | sls function | stve -newinstance
```
The above examples open gvim with all locations where an exception in the error list

By adding the following to _vimrc it is quick and easy to jump between the hits with F2 or F3 
```
nnoremap <silent> <F2> :bn<CR>
nnoremap <silent> <S-F2> :bp<CR>
nnoremap <silent> <F3> :cn<CR>
nnoremap <silent> <S-F3> :cp<CR>
```
