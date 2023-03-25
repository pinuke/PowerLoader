param(
    [Parameter(Mandatory=$true)]
    [hashtable] $Dependencies,
    [Parameter(Mandatory=$true)]
    [string] $SaveTo
)

foreach( $Dependency in $Dependencies.GetEnumerator() ){
    
    $URL = If ( $Dependency.Value.Source ) {
        $Dependency.Value.Source
    } else {
        "https://www.nuget.org/api/v2/package/$( $Dependency.Name )"
    }

    $JobTable = @{}
    If ( $Dependency.Value.Target ){
        $JobTable[ "$SaveTo/$( $Dependency.Name )/lib/$( $Dependency.Value.target )/" ] = @{
            "Globs" = $Dependency.Value.assemblies
            "Type" = "Managed"
        }
    }

    If ( $Dependency.Value.Natives ){
        $JobTable[ "$SaveTo/$( $Dependency.Name )/runtimes/win-x64/native/" ] = @{
            "Globs" = $Dependency.Value.natives
            "Type" = "Unmanaged"
        }
    }

    foreach( $Job in $JobTable.GetEnumerator() ){

        Write-Host
        If( $Job.Value.Type -eq "Managed" ){
            Write-Host "Importing Managed NuGet Dependency:" -BackgroundColor DarkBlue -ForegroundColor White
        } else {
            Write-Host "Importing Unmanaged (Native) NuGet Dependency:" -BackgroundColor DarkBlue -ForegroundColor White
        }

        $Job.Value.Globs | ForEach-Object {
            Ensure-Glob -Globs @( "$( $Job.Name )/$_" ) `
                -EnsureScript {

                    Write-Host "Downloading $( $Dependency.Name ), because it is missing..." -BackgroundColor DarkRed -ForegroundColor White

                    $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest $URL -OutFile $tmp | Out-Null
                    New-Item -ItemType Directory -Force -Path "$SaveTo/$( $Dependency.Name )"
                    $tmp | Expand-Archive -DestinationPath "$SaveTo/$( $Dependency.Name )"
                    $tmp | Remove-Item | Out-Null
                    $ProgressPreference = 'Continue'

                    Write-Host "$( $Dependency.Name ) downloaded." -BackgroundColor Green -ForegroundColor Black

                } `
                -SuccessScript {
                    param( $Paths )

                    Write-Host "Importing $( $Dependency.Name )..." -BackgroundColor DarkYellow -ForegroundColor White
                    $Paths | ForEach-Object {
                        Write-Host " - $( $_.Path )"
                        If ( $Job.Value.Type -eq "Managed" ){
                            Import-Module $_.Path
                        } else {
                            Import-NativeLibrary $_.Path
                        }
                    }

                    If( !$Targets.Length ){
                        Write-Host " - no files loaded for this dependency"
                    }
                }
        }
    }
}
