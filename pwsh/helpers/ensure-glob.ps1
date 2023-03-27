function Ensure-Glob {
    param(
        [Parameter(Mandatory=$true)]
        [array] $Globs,
        [Parameter(Mandatory=$true)]
        [scriptblock] $EnsureScript,
        [Parameter(Mandatory=$true)]
        [scriptblock] $SuccessScript
    )

    $Globs | ForEach-Object {

        $error.clear() | Out-Null
        $Paths = Resolve-Path $_ -ErrorAction SilentlyContinue
        If ( $error ) {
            Invoke-Command $EnsureScript
            $Paths = Resolve-Path $_
            Invoke-Command $SuccessScript -ArgumentList (, $Paths )
        } else {
            Invoke-Command $SuccessScript -ArgumentList (, $Paths )
        }
    }
}