# Script Module for LC Functions
$Script:PSDefaultParameterValues = $Global:PSDefaultParameterValues

Get-ChildItem (Split-Path $script:MyInvocation.MyCommand.Path) -Recurse | Where-Object { $_.Name -like "func_*" } | % {
    . $_.FullName
}