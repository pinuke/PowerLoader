function Ensure-Glob {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable] $Globs,
        [Parameter(Mandatory=$true)]
        [scriptblock] $EnsureScript,
        [Parameter(Mandatory=$true)]
        [scriptblock] $SuccessScript
    )

    foreach( $Glob in $Globs.GetEnumerator() ){

        $error.clear() | Out-Null
        $Paths = Resolve-Path $Glob.Value -ErrorAction SilentlyContinue
        If ( $error ) {
            Invoke-Command $EnsureScript
            $Paths = Resolve-Path $Glob.Value
            Invoke-Command $SuccessScript -ArgumentList @( $Paths )
        } else {
            Invoke-Command $SuccessScript -ArgumentList @( $Paths )
        }
    }
}