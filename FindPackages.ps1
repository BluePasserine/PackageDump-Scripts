
Function Invoke-PackageDump {
  [CmdletBinding(SupportsShouldProcess)]
<#
.SYNOPSIS
  Iterate all NuGet and NPM packages under a local folder and call the PackageDump API.

.DESCRIPTION
  Locate all NuGet packages from Packages.config or csproj files, NPM packages from packages.json. Then call the PackageDump API.

.PARAMETER Folder
  The root folder to recursively look through.

.PARAMETER Group
  Link together a number of different analysis reports for future comparison. Create one Group for each application or codebase, it's really up to you.
    
.PARAMETER Ignore
   A wildcard filter, typically of your own package prefix, to ignore in the report. For example BluePasserine* will ignore any packages.
    
.PARAMETER ApiKey
  Your API key from https://www.packagedump.com/Account/Licensing
  
.PARAMETER Path
  The optional path to the HTML output file to write, e.g. C:\Work\output.html
  
.PARAMETER PackageManagers
   An optional list of package managers to target: @("nuget", "npm")
    
.PARAMETER WhatIf
  Collect all packages and output the JSON for review, but do not call the API
#>
Param ([string]$Folder,
       [string]$Group,
       [string]$Ignore,
       [string]$ApiKey,
       [string]$Path,
       [string[]]$PackageManagers = @("nuget", "npm"))

  $name = Get-Date -Format o | ForEach { $_ -Replace ":", "." }
  
  $requestObj = @{ group = "$Group"; name = "$name"; projects = @() }
  
  If ($PackageManagers.Contains("nuget")){
    Write-Host "Looking for NuGet Packages..."
    $packageManager = "NuGet"

    Get-ChildItem -Path $Folder -Include *.csproj -Recurse -File -ErrorAction SilentlyContinue | 
      ForEach-Object {
      Write-Verbose "Found csproj $($_.FullName)"
      
      $projectName = $_.BaseName
      $projectObj = @{ name = "$projectName"; packages = @() }
      $directoryName = Split-Path $_.FullName
      $packagesConfig = Join-Path $directoryName "packages.config"
  
      If (Test-Path $packagesConfig) {
        Write-Verbose "Found packages.config $($_.FullName)"
  
        $packagesList = @()
        [xml]$packagesXml = Get-Content $packagesConfig
        ForEach($package in $packagesXml.packages.package) {
          If ($package.id -NotMatch $Ignore){
            $packageObj = New-Object PSObject -Property @{id = $package.id; version = $package.version; packageManager = "$packageManager"}
            $projectObj.packages += $packageObj
          }
        }
  
        
        $requestObj.projects += $projectObj
      } Else {
        [xml]$csProjXml = Get-Content $_.FullName
        ForEach($package in $csProjXml.Project.ItemGroup.PackageReference) {
          If ($package.id -NotMatch $Ignore){
            $packageObj = New-Object PSObject -Property @{id = $package.Include; version = $package.Version; packageManager = "$packageManager"}
            $projectObj.packages += $packageObj
          }
        }
      }
    }
  }
  
  If ($PackageManagers.Contains("npm")){
    Write-Host "Looking for NPM Packages..."
    $packageManager = "NPM"

    Get-ChildItem -Path $Folder -Include "package.json" -Recurse -Exclude "node_modules" -File -ErrorAction SilentlyContinue | 
      ForEach-Object {
      Write-Verbose "Found package.json $($_.FullName)"
      
      $projectName = $_.BaseName
      $projectObj = @{ name = "$projectName"; packages = @() }
      $directoryName = Split-Path $_.FullName

      $packagesList = @()
      $json = (Get-Content $_.FullName) -join "`n" | ConvertFrom-Json
      
      If ($json -and $json.dependencies) {
        [PSCustomObject]$obj
        $json.dependencies | Get-Member -MemberType NoteProperty | ForEach-Object {
          $key = $_.Name
          $package = [PSCustomObject]@{Key = $key; Value = $json.dependencies."$key"}
          
          $packageObj = New-Object PSObject -Property @{id = $package.Key; version = $package.Value; packageManager = "$packageManager"}
          $projectObj.packages += $packageObj
        }
        
        $requestObj.projects += $projectObj
      }
    }
  }

  $body = $requestObj | ConvertTo-Json -Depth 4
    
  If ($PSCmdlet.ShouldProcess($body)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest -UseBasicParsing 'https://api.packagedump.com/api/packages' -Body $body -Method "POST" -Headers @{ "x-bppd-a" = "$ApiKey" } -ErrorAction Stop
      
    If ($response.StatusCode -ne 201){
      Write-Error "An error occured: $($response.Content)"
      Exit -1
    } Else {
      $responseObj = $response.Content | ConvertFrom-Json
      
      Write-Host "Analysis Request Created"
      Write-Host "------------------------"
      Write-Host "Id: $($responseObj.AnalysisId)"
      Write-Host "ReportUrl: $($responseObj.ReportUrl)"
      Write-Host "EmbedUrl: $($responseObj.EmbedUrl)"
      
      $outputHtml = '<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>PackageDump - Analysis Report</title>
  <style type="text/css">
  body { 
    margin: 0;
  }
  iframe {
    display: block;
    border: none;
    height: 100vh;
    width: 100vw;
  }
  </style>
</head>
<body>
  <iframe src="$($responseObj.EmbedUrl)"></iframe>
</body>'
      If ($Path){
        Out-File -FilePath $Path -InputObject $outputHtml -Encoding UTF8
      }
    }
  }
}