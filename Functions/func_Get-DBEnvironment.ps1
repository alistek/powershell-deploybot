#Requires -Version 4.0

<#
 # Script FileName: func_Get-DBEnvironment.ps1
 # Current Version: A02
 # Description: Retrieve DeployBot Environment or Environments
 # Created By: Adam Listek
 # Version Notes
 #      A01 - Initial Release
 #      A02 - Further Refinement
 #>

Function Get-DBEnvironment {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )] # Terminate CmdletBinding

    Param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('environment_id')][Int]$ID,
        [Parameter(Position=1)][String]$Name,      
        [Parameter(Position=2)][String]$Branch = 'master',

        [Parameter(Position=3, Mandatory=$true)][String]$Organization,
        [Parameter(Position=4, Mandatory=$true)][String]$ApiKey,

        [Switch]$Automatic
    ) # Terminate Param

	Begin {
        If ($MyInvocation.BoundParameters.Verbose -EQ $true) {
            $local:VerbosePreference = "Continue"
            $local:verbose = $true
        } Else {
            $local:VerbosePreference = "SilentlyContinue"
            $local:verbose = $false
        } # Terminate If - Verbose Parameter Check

        If ($MyInvocation.BoundParameters.Debug -EQ $true) {
            $local:debug = $true
        } Else {
            $local:debug = $false
        } # Terminate If - Debug Parameter Check

        If ($MyInvocation.BoundParameters.WhatIf -EQ $true) {
            $local:whatif = $true
        } Else {
            $local:whatif = $false
        } # Terminate If - Debug Parameter Check

        # DeployBot Authorization
        $url = "https://$organization.deploybot.com/api/v1"

        $header = @{
            "X-Api-Token" = $apikey
        }
    } # Terminate Begin

    Process {
        Write-Verbose $apikey
        Write-Verbose $url
        Write-Verbose ($header | Out-String)

        If ($ID) { 
            $filter = "/$ID"   
        } Else {
            $filter = $null
        } # Terminate If - Filter

        $URI = "$url/environments$filter"

        Write-Verbose $URI

        If (-not $whatif) {
            Try {
                $response = Invoke-WebRequest -Uri $URI -Method GET -Headers $header -ErrorAction Stop -Verbose:$local:verbose -Debug:$local:debug `
                    | ConvertFrom-JSON
            } Catch {
                $errorInformation = $Error[0].Exception.Response
                $statusCode = $errorInformation.StatusCode.value__

                Switch ([Int]$statusCode) {
                    400 {
                        $description = "Malformed JSON Payload: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                    401 {
                        $description = "Missing or Invalid API Token: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                    403 {
                        $description = "Attempting to perform a restricted action: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                    422 {
                        $description = "Incorrect request data: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                    500 {
                        $description = "Server Error: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                    Default {
                        $description = "Unknown Error: $($errorInformation.StatusDescription)"
                        $errorID = $statusCode

                        Write-Error -Exception $description -ErrorId $errorID

                        Break
                    }
                }

                Break
            } # Terminate Try-Catch

            Write-Verbose ($response | Out-String)

            If ($response) {
                If ($name)      { $WhereArray += '$_.name -eq ' + "'$name'" }
                If ($branch)    { $WhereArray += '$_.branch_name -eq ' + "'$branch'" }
                If ($automatic) { $WhereArray += '$_.is_automatic -eq ' + "'$automatic'" }

                If ($WhereArray) {
                    Write-Verbose "WhereArray: $WhereArray"

                    $WhereString = $WhereArray -Join " -and "

                    Write-Verbose "WhereString: $WhereString"

                    $scriptBlock = [ScriptBlock]::Create($WhereString)
                } # Terminate If - Where Clause

                If ($scriptBlock) {
                    Write-Verbose "ScriptBlock: $($scriptBlock.ToString())"

                    If ($ID) {
                        $response | Where $scriptBlock
                    } Else {
                        $response | Select -ExpandProperty entries | Where $scriptBlock
                    } # Terminate If - ID
                } Else {
                    If ($ID) {
                        $response
                    } Else {
                        $response | Select -ExpandProperty entries
                    } # Terminate If - ID
                } # Terminate If - ScriptBlock
            } Else {
                Write-Error "No Response Received"
            } # Terminate If - Response
        } # Terminate If - WhatIf
    } # Terminate Process

    <#
        .SYNOPSIS
            
        .DESCRIPTION

        .PARAMETER

        .EXAMPLE

        .NOTES
    #>
} # Terminate Function