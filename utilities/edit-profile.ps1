# If local profile doesn't exist, then make it
if (-not (Test-Path -Path "$PROFILE")) {
    Out-File $PROFILE
}

# With newly created file, append useful utility functions to it to assist with lab
$functions = @'
function Load-EnvFile {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Path = "./.env"
    )
    begin {
        if ([string]::IsNullOrEmpty($Path)) {
            Write-Error "Path is empty"
            throw
        } else {
            if (-not (Test-Path $Path)) {
                Write-Error "Path doesn't exist, check input"
                throw
            } 
        }
    }

    process {
        Write-Host "Setting env contents from file $Path"
        Get-Content $Path |% { if (-not $_.StartsWith('#')) {$name, $value = $_.split('='); Set-Item -Path "Env:$name" -Value $value.Trim('"')}}
    }
}

function Convert-SecureString {
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$SecureValue
    )

    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    )
    $plain
}

function Deploy-Bicep {
    param(
        [Parameter()]
        [string]$TemplateParameterFile = "./main.bicepparam",

        [Parameter()]
        [string]$TemplateFile = "./main.bicep",

        [Parameter()]
        [string]$EnvFile = "./.env",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Location = "uksouth"
    )

    $fileTargets = @(
        $TemplateParameterFile
        $TemplateFile
        $EnvFile
    )

    $missingFiles = @(
        foreach ($target in $fileTargets) {
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
                $target
            }
        }
    )

    if ($missingFiles.Count -gt 0) {
        throw "Required file(s) not found: $($missingFiles -join ', ')"
    }

    Load-EnvFile -Path $EnvFile

    $WorkloadCode = Read-Host "Please confirm your desired workload code name, e.g. bentest, jh26 or pgtest etc"
    Set-Item -Path "Env:WORKLOAD_CODE" -Value $WorkloadCode.Trim('"')

    az deployment sub create --location $Location --template-file $TemplateFile --parameters $TemplateParameterFile --name "$($Env:Username)-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

}

Set-Alias -Name git -Value "C:\Program Files\Git\cmd\git.exe" 
Set-Alias -Name az -Value "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
'@

$targets = @(
    "function Load-EnvFile"
    "Set-Alias -Name git"
    "Set-Alias -Name az"
    "function Convert-SecureString"
)

$Path = $PROFILE
# check whether these lines possibly already exist or no
$results = foreach ($target in $targets) {
    $hits = (Get-Content $Path | findstr /i /c:$target)
    if (($hits | Measure-Object).Count -gt 1) {
        Write-Host "possible clash detected for target - $target"
        $false
    } else { 
        Write-Host "no clash anticipated for target - $target"
        $true
    }
}

if ((($results |? {$_ -eq $true}) | Measure-Object).Count -lt $targets.Count) {
    Write-Error "Can't append, possible clash"
    throw
} else {
    $functions | Add-Content -Path $Path
}

