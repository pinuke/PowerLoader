param(
    [switch] $Reinstall = $false,
    [string] $ConfigFile,
    [string] $ProjectDir
)

$Root = If ( $TestRoot ) { $TestRoot } else {
    If ( $PSScriptRoot ) { Resolve-Path "$PSScriptRoot/.." } else { Resolve-Path "./.." }
}

$ProjectDir = If ( $ProjectDir ) { $ProjectDir } else {
    Resolve-Path "$Root/.."
}

. "$Root/pwsh/helpers/ensure-glob.ps1"

. "$Root/pwsh/misc/native-library.ps1"
. "$Root/pwsh/misc/strings.ps1"

$error.Clear() | Out-Null
$ConfigFile = Resolve-Path $ConfigFile -ErrorAction SilentlyContinue
If( $error ){

    $error.Clear() | Out-Null
    $ConfigFile = Resolve-Path "$ProjectDir/powershell.json" -ErrorAction SilentlyContinue
    If( $error ){
        $ConfigFile = Resolve-Path "$Root/json/default.json"
    }

}

$Config = Import-Contents -Path $ConfigFile -As JSON

If ( $Reinstall ) {
    foreach( $dir in $Config.Destinations.GetEnumerator() ){
        Remove-Item -Recurse -Force "$ProjectDir/$( $dir.Value )"
    }
}

If ( $Config.Manifests ) {

    If ( !$Config.Dependencies ){
        $Config.Dependencies = @{}
    }

    foreach( $Manifest in $Config.Manifests.GetEnumerator() ){

        $RootedPath = If ( [System.IO.Path]::IsPathRooted( $Manifest.Value ) ){
            $Manifest.Value
        } else {
            Join-Path $ProjectDir $Manifest.Value
        }

        $Path = Resolve-Path ( $RootedPath )
        $Config.Dependencies[ $Manifest.Name ] = Import-Contents -Path $Path -As JSON
    }
}

If ( $Config.Dependencies ) {
    If ( $Config.Dependencies.Local ) {
        & "$Root/pwsh/dll/local.ps1" `
            -Dependencies $Config.Dependencies.Local
    } 
    If ( $Config.Dependencies.PSGallery ) {
        & "$Root/pwsh/dll/psgallery.ps1" `
            -Dependencies $Config.Dependencies.PSGallery `
            -SaveTo "$ProjectDir/$( $Config.Destinations.PSGallery )"
    }
    If ( $Config.Dependencies.NuGet ) {
        & "$Root/pwsh/dll/nuget.ps1" `
            -Dependencies $Config.Dependencies.NuGet `
            -SaveTo "$ProjectDir/$( $Config.Destinations.NuGet )"
    } 
}
