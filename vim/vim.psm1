$NewInstanceName='PsVim'

$gvimPath = (Get-ItemProperty HKLM:\SOFTWARE\Vim\Gvim -Name Path).Path

$vimDir = Split-Path $gvimPath

Set-Alias gvim $vimDir\gvim.exe 
Set-Alias vim  $vimDir\vim.exe


function LaunchVim
{
  param
  (
    [string]
    $errorFile,
    
    [Switch]
    $NewInstance
  )
  
  if ($NewInstance)
  {
    gvim -q $errorfile	
  }
  else 
  {
    # Make sure we have a running instance to send commands to
    if(!(vim --serverlist | Select-String -Pattern $NewInstanceName -Quiet)) 
    {
      gvim --servername $NewInstanceName
      Start-Sleep -Milliseconds 1000
    }
    gvim --servername $NewInstanceName --remote-send "<ESC><ESC><ESC>:cf $errorFile<CR>"
  }
}


function Invoke-Gvim
{
<# 
.Synopsis 
    Starts the Gvim editor. 
.Description 
    This command starts creates an errorfile from the pipeline input and starts 
    gvim with that file as an argument.
    This enables easy navigations in search results from multiple files 

.Example 
    PS> Get-ChildItem *.txt | Invoke-GVim

    Opens all text files in the current directory

.Example    
    PS> Select-String 'Foo' *.txt | Invoke-GVim
    
    Opens all text files containing 'Foo' and enables navigation between the instances 
    with :cn and :cp

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
        $lines += '{0}({1}) : {2}' -f $d.path, $d.LineNumber, $d.Line
        continue
      }
      if ($d -is [System.IO.FileInfo])
      {                            
        $lines += '{0}(1) : File: {1}' -f $d.FullName, $d.Name
        continue
      }
      if ($d -is [System.IO.DirectoryInfo])
      {                                    
        continue
      }
      if ($d.PSPath)
      {
        $lines += (Resolve-Path $d.PSPath).ProviderPath | ForEach-Object {'{0}(1) : File: {1}' -f $_, (Split-Path -Leaf $_)}
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
      Remove-Item -Path $tmp\*.psvimerror     
      Set-Content -encoding Ascii -Path $outfile -Value $output
      LaunchVim (Get-Item $outfile).fullname -NewInstance:$NewInstance      
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