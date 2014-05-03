function LaunchVim
{
  param
  (
    [System.String]
    $errorFile,
    
    [System.Management.Automation.SwitchParameter]
    $NewInstance
  )
  
  if ($NewInstance)
  {
    gvim -q $errorfile	
  }
  else 
  {
    # Make sure we have a running instance to send commands to
    if(!(vim --serverlist | Select-String "$reuseInstanceName" -q)) 
    {
      gvim '--servername' $reuseInstanceName
      Start-Sleep -Milliseconds 1000
    }
    gvim --servername $reuseInstanceName --remote-send "<ESC><ESC><ESC>:cf $errorFile<CR>"
  }
}


function Start-VimErrorFile
{
<# 
.Synopsis 
    Starts the Vim editor with an error file. 
.Description 
    This command starts creates an errorfile from the pipeline input and starts gvim with that file as an argument.
    This enables easy navigations 

.Example 
    PS> Get-ChildItem *.txt | Start-VimWithErrorInfo
    
    PS> Select-String 'Foo' *.txt | Start-VimWithErrorInfo

.Link     

.Notes 
NAME:      Start-VimErrorInfo
#Requires -Version 2.0 
#>
  [CmdletBinding(             
  DefaultParameterSetName='input')] 
  param(
    [Parameter(ParameterSetName='ErrorFile',Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)] 
    [string] $errfile, 
    [Parameter(ParameterSetName='input',Position=0, Mandatory=$true, ValueFromPipeline=$true)] 
    [ValidateNotNull()]
    [PSObject[]] $data, 
    [switch] $NewInstance
  )
  
  begin{
    $lines = New-Object System.Collections.Generic.list[string] 100
  }
  process {
    if ($PsCmdLet.ParameterSetName -eq 'ErrorFile')
    {
      LaunchVim (Get-Item $errFile).FullName -forceNewInstance:$NewInstance
      return            
    }
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
      
      Write-Error -targetobject $data -message 'Invalid type of input'
      
    }
  }
  end 
  {		
    if($lines)
    {
      $outfile = [io.path]::GetTempFileName() + '.vimerror'
      $output = [string]::join("`n", $lines)
      Set-Content -encoding Ascii -Path $outfile -Value $output
      LaunchVim (Get-Item $outfile).fullname -NewInstance:$NewInstance
    }
  }
}

function Set-VimReuseInstanceName{
  param
  (
    [string] $name = 'PsVim'
  )
  
  $script:reuseInstanceName = $name
}
