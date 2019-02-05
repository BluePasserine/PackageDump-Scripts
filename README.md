# PackageDump-Scripts
A PowerShell script for locating NuGet and NPM packages and calling the PackageDump API.

## Usage
``` powershell
$folder = "root_path_to_codebase"
$group = "My Group"
$ignore = $null
$apiKey = "your_api_key"

Invoke-PackageDump -Path (Join-Path 'c:\path_to_build_artifacts' 'Report.html') -Folder $folder -Group $group -Ignore $ignore -ApiKey $apiKey -PackageManagers @("nuget","npm")
```

### Parameters
* Folder - The root folder to recursively look through.
* Group - A group is a container of analysis reports. Create one Group for each application or codebase, it's really up to you.
* Ignore - A wildcard filter, typically of your own package prefix, to ignore in the report. For example BluePasserine* will ignore any packages that start with BluePasserine.
* ApiKey - Your API key from https://www.packagedump.com/Account/Licensing
* Path - The optional output HTML report file to use
* PackageManagers - The list of Package Managers to target, specify just "nuget" or "npm" or both

### Testing
To test your CI/CD setup without actually making an analysis request against your usage quota, pass the `-WhatIf` parameter. This will output the API request details, without actually
making the request to the PackageDump system.

For more verbose output, set the `$VerbosityPreference` PowerShell variable and pass the `-Verbose` flag
```
$VerbosePreference = "Continue"
Invoke-PackageDump -Folder $folder -Group $group -Ignore $ignore -ApiKey $apiKey -WhatIf -Verbose
```

## Teamcity Example
$folder = "%teamcity.build.workingDir%"
$group = "BluePasserine.PackageDump"
$ignore = "BluePasserine*"
$apiKey = "your_api_key"

Invoke-PackageDump -Path (Join-Path '%teamcity.build.checkoutDir%' 'Report.html') -Folder $folder -Group $group -Ignore $ignore -ApiKey $apiKey -PackageManagers @("nuget")