$NewInstanceName='gPsVim'

if (!(Test-Path alias:gvim))
{
    $gvimPath = (Get-ItemProperty HKLM:\SOFTWARE\Vim\Gvim -Name Path).Path
    Set-Alias gvim $gvimPath
}


function LaunchVim
{
  param
  (
    [string]
    $errorFile,
    [string]
    $ErrorFormat,
    [Switch]
    $NewInstance
  )  
    $vimArgs = @()
    if($NewInstance)
    {
        if($ErrorFormat){    
            $vimArgs = '-c', ":set errorformat=$ErrorFormat"
        }
        
        $vimArgs += '-c', ":cf $errorFile"
    }
    else
    {
        $vimArgs = '--servername', $NewInstanceName, '--remote-silent'
        if($ErrorFormat){
           $vimArgs += "+<C-\><C-N>:set errorformat=$ErrorFormat<CR>:cf $errorFile<CR>", $errorFile
        }
        else
        {
            $vimArgs += "+<C-\><C-N>:cf $errorFile<CR>", $errorFile
        }
    }
              
    Write-Verbose "gvim $vimArgs"
    gvim $vimArgs
}


function Invoke-Gvim
{
<#
.Synopsis
    Starts the Gvim editor.
.Description
    This command creates an errorfile from the pipeline input and invokes
    gvim with that file as an argument.
    This enables easy navigations in search results from multiple files

.Example
    PS> Get-ChildItem *.txt | Invoke-GVim

    Opens all text files in the current directory

.Example
    PS> Select-String 'Foo' *.txt | Invoke-GVim

    Opens all text files containing 'Foo' and enables navigation between the instances
    with :cn and :cp

.Example
    Get-ChildItem -Recurse -Filter *.txt | Select-String 'aaa(bbb)ccc' | Invoke-GVim

    The example above open gvim with all textfiles containg 'aaabbbccc' with the selection
    on the first regex group.

    some text aaabbbccc
                 ^ cursor


.Link

.INPUTS
System.IO.FileInfo
Microsoft.PowerShell.Commands.MatchInfo
System.String

Object with PSPath property


.Notes
NAME:      Invoke-GVim
#Requires -Version 2.0
#>
  [CmdletBinding()]
  param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [PSObject[]] $data,
    # Open results in new Gvim window
    [switch] $NewInstance
  )

  begin{
    $lines = New-Object System.Collections.Generic.list[string] 100
  }
  process {
    foreach($d in $data)
    {
      if($d -is [Microsoft.PowerShell.Commands.MatchInfo])
      {
        $groups =$d.Matches[0].Groups
        if($groups.Count -gt 1)
        {
            # use the first match if we have capture groups
            $group = $groups[1]
        }
        else{
            $group = $groups[0]
        }
        $column = $group.Index + 1
        $msg = $group.Value
        $lines += '{0}:{1}:{2}:{3}'  -f $d.path, $d.LineNumber, $column, $msg
        continue
      }
      if ($d -is [System.IO.FileInfo])
      {
        $lines += '{0}:{1}' -f $d.FullName, $d.Name
        continue
      }
      if ($d -is [System.IO.DirectoryInfo])
      {
        continue
      }
      if ($d.PSPath)
      {
        $lines += (Resolve-Path $d.PSPath).ProviderPath | ForEach-Object {'{0}:{1}' -f $_, (Split-Path -Leaf $_)}
        continue
      }
      if ($d -is [string]){
        $lines += $d
        continue
      }

      Write-Error -targetobject $d -message "Invalid input type: '$($d.GetType())'"

    }
  }
  end
  {
    if($lines)
    {
      $outfile = [io.path]::GetTempFileName() + '.psvimerror'
      $output = [string]::join("`n", $lines)
      $tmp=[io.path]::GetTempPath()
      Remove-Item -Path $tmp\*.psvimerror -ErrorAction SilentlyContinue
      Set-Content -encoding Ascii -Path $outfile -Value $output
      LaunchVim (Get-Item $outfile).fullname -NewInstance:$NewInstance -ErrorFormat '%f:%l:%c:%m,%f:%m'
    }
  }
}

function Set-VimNewInstanceName{
  param
  (
    [string] $name = 'PsVim'
  )

  $script:NewInstanceName = $name
}



Set-Alias igv Invoke-GVim
