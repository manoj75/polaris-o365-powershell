Get-ChildItem -Path $PSScriptRoot\Function\*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function *