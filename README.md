# PackageDump-Scripts
Contains a PowerShell script for locating NuGet and NPM packages and calling the PackageDump API.

## Usage
``` powershell
$folder = "root_path_to_codebase"
$group = "My Group"
$ignore = $null
$apiKey = ""

Invoke-PackageDump -Folder $folder -Group $group -Ignore $ignore -ApiKey $apiKey
```

### Parameters
* Folder - The root folder to recursively look through.
* Group - Link together a number of different analysis reports for future comparison. Create one Group for each application or codebase, it's really up to you.
* Ignore - A wildcard filter, typically of your own package prefix, to ignore in the report. For example BluePasserine* will ignore any packages that start with BluePasserine.
* ApiKey - Your API key from https://www.packagedump.com/Account/Licensing

### Testing
To test your CI/CD setup without actually making an analysis request against your usage quota, pass the `-WhatIf` parameter. This will output the API request details, without actually
making the request to the PackageDump system.

For more verbose output, set the `$VerbosityPreference` PowerShell variable and pass the `-Verbose` flag
```
$VerbosePreference = "Continue"
Invoke-PackageDump -Folder $folder -Group $group -Ignore $ignore -ApiKey $apiKey -WhatIf -Verbose
```