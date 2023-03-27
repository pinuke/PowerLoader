param(
    [Parameter(Mandatory=$true)]
    [System.Management.Automation.OrderedHashtable] $Dependencies,
    [Parameter(Mandatory=$true)]
    [string] $SaveTo
)

foreach( $Dependency in $Dependencies.GetEnumerator() ){

    $CaseInsensitiveTable = [hashtable]::new( [System.StringComparer]::InvariantCultureIgnoreCase ) # Case Insensitive Table for Compatibility
    foreach ( $pair in $Dependency.Value.GetEnumerator() ) { $CaseInsensitiveTable[ $pair.Key ] = $pair.Value }

    $Dependency.Value = $CaseInsensitiveTable

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
                    Invoke-WebRequest $URL -OutFile $tmp -ErrorAction Stop | Out-Null
                    New-Item -ItemType Directory -Force -Path "$SaveTo/$( $Dependency.Name )" | Out-Null
                    $tmp | Expand-Archive -DestinationPath "$SaveTo/$( $Dependency.Name )"
                    $tmp | Remove-Item | Out-Null
                    $ProgressPreference = 'Continue'

                    Write-Host "$( $Dependency.Name ) downloaded." -BackgroundColor Green -ForegroundColor Black

                } `
                -SuccessScript {
                    param( $Paths )

                    Write-Host "Importing $( $Dependency.Name )..." -BackgroundColor DarkYellow -ForegroundColor White

                    If( !$Paths.Length -or ( $Paths -eq $null ) ){
                        Write-Host " - no files loaded for this dependency"
                        return;
                    }

                    $Paths | ForEach-Object {
                        Write-Host " - $( $_.Path )"
                        If ( $Job.Value.Type -eq "Managed" ){
                            Import-Module $_.Path | Out-Null
                        } else {
                            Import-NativeLibrary $_.Path | Out-Null
                        }
                    }
                }
        }
    }
}
