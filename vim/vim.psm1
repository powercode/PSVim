using namespace System.Management.Automation;
using namespace System.Collections.Generic;
$NewInstanceName = 'gPsVim'

if (!(Test-Path alias:gvim)) {
  $gvimPath = (Get-ItemProperty HKLM:\SOFTWARE\Vim\Gvim -Name Path).Path
  Set-Alias gvim $gvimPath
}


function LaunchVim {
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
  if ($NewInstance) {
    if ($ErrorFormat) {
      $vimArgs = '-c', ":set errorformat=$ErrorFormat"
    }

    $vimArgs += '-c', ":cf $errorFile"
  }
  else {
    $vimArgs = '--servername', $NewInstanceName, '--remote-silent'
    if ($ErrorFormat) {
      $vimArgs += "+<C-\><C-N>:set errorformat=$ErrorFormat<CR>:cf $errorFile<CR>", $errorFile
    }
    else {
      $vimArgs += "+<C-\><C-N>:cf $errorFile<CR>", $errorFile
    }
  }

  Write-Verbose "gvim $vimArgs"
  gvim $vimArgs
}

class GvimErrorFile {
  hidden [List[string]] $ErrorLines = [List[string]]::new(100)

  hidden [List[ErrorRecord]] $Errors

  [bool] HasLines() {    
    return $this.ErrorLines && $this.ErrorLines.Count -gt 0
  }

  [string] WriteErrorLinesToTemporaryFile() {
    $outfile = [io.path]::GetTempFileName() + '.psvimerror'
    $tmp = [io.path]::GetTempPath()
    Remove-Item -Path $tmp\*.psvimerror -ErrorAction SilentlyContinue
    [System.IO.File]::WriteAllLines($outfile, $this.ErrorLines, [System.Text.Encoding]::UTF8)
    return $outFile
  }

  [System.Management.Automation.ErrorRecord[]] AddData([psobject[]] $psobject) {
    foreach ($o in $psobject) {
      if ($this.TryAddMatchInfoLine($o)) { continue }
      if ($this.TryAddFileLine($o)) { continue }
      if ($this.IsDirectory($o)) { continue }
      if ($this.TryAddObjectWithPSPath($o)) { continue }
      if ($this.TryAddString($o)) { continue }
      
      $this.AddError($o)
    }

    return $this.GetErrors()
  }

  [ErrorRecord[]] GetErrors() {
    $retVal = [Array]::Empty[ErrorRecord]()

    if ($this.Errors) {
      $retVal = $this.Errors.ToArray()
      $this.Errors.Clear()
    }

    return $retVal
  }

  [void] AddError([psobject] $obj) {
    if (!$this.Errors) {
      $this.Errors = [List[ErrorRecord]]::new(10)
    }
    $typeName = $obj.psobject.TypeNames[0]
    $er = [ErrorRecord]::new([InvalidOperationException]::new("The type '$typeName' is not valid as input. MatchInfo, FileInfo, a full path as a string,`nand any object with a PSPath property will work."), 'InvalidType', [ErrorCategory]::InvalidArgument, $obj)
    $this.Errors.Add($er)
  }

  hidden [bool] IsDirectory([psobject] $obj) {
    return $obj -is [System.IO.DirectoryInfo]
  }

  hidden [bool] TryAddString([psobject] $obj) {
    if ($obj -is [string]) {
      $this.ErrorLines.Add($obj)
      return $true
    }
    return $false
  }

  hidden [bool] TryAddObjectWithPSPath([PSObject] $obj) {
    if (!$obj.psobject.Properties["PSPath"]) { return $false }
    
    $path = (Resolve-Path $obj.PSPath).ProviderPath
    $lines = $path.Foreach{ '{0}:{1}' -f $_, [System.IO.Path]::GetFileName($_) }
    $this.ErrorLines.Add($lines)
    return $true
  }

  hidden [bool] TryAddMatchInfoLine([PSObject] $psobject) {
    $matchInfo = $psobject -as [Microsoft.PowerShell.Commands.MatchInfo]
    if (!$matchInfo) { return $false }

    $line = $this.ToErrorLine($matchInfo)
    $this.ErrorLines.Add($line)
    return $true
  }

  hidden [bool] TryAddFileLine([PSObject] $obj) {
    $file = $obj -as [System.IO.FileInfo]
    if (!$file) { return $false }

    $line = $this.ToErrorLine($file)
    $this.ErrorLines.Add($line)
    return $true
  }

  hidden [string] ToErrorLine([Microsoft.PowerShell.Commands.MatchInfo] $matchInfo) {
    $groups = $matchInfo.Matches[0].Groups
    if ($groups.Count -gt 1) {
      # use the first match if we have capture groups
      $column = $groups[1].Index + 1
    }
    else {
      $column = $groups[0].Index + 1
    }

    $msg = $groups[0].Value + ' - ' + $matchInfo.Line
    $line = '{0}:{1}:{2}:{3}' -f $matchInfo.path, $matchInfo.LineNumber, $column, $msg
    return $line
  }

  hidden [string] ToErrorLine([System.IO.FileInfo] $fileInfo) {
    return '{0}:{1}' -f $fileInfo.FullName, $fileInfo.Name
  }
}


function Invoke-Gvim {
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
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNull()]
    [PSObject[]] $data,
    # Open results in new Gvim window
    [switch] $NewInstance
  )

  begin {
    $gvimErrorFile = [GvimErrorFile]::new()
  }
  process {
    $errors = $gvimErrorFile.AddData($data)
    foreach ($err in $errors) {
      Write-Error -ErrorRecord $err
    }
  }
  end {
    if ($gvimErrorFile.HasLines()) {
      $errorsFile = $gvimErrorFile.WriteErrorLinesToTemporaryFile()
      $PSCmdlet.WriteDebug([System.IO.File]::ReadAllText($errorsFile))
      LaunchVim $errorsFile -NewInstance:$NewInstance -ErrorFormat '%f:%l:%c:%m,%f:%m'
    }
  }
}

function Set-VimNewInstanceName {
  param
  (
    [string] $name = 'PsVim'
  )

  $script:NewInstanceName = $name
}



Set-Alias igv Invoke-GVim
