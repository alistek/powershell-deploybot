#Requires -Version 4.0

<#
 # Script FileName: func_Get-DBDeployment.ps1
 # Current Version: A02
 # Description: Retrieve DeployBot Deployment or Deployments
 # Created By: Adam Listek
 # Version Notes
 #      A01 - Initial Release
 #      A02 - Further Refinement
 #>

Function Get-DBDeployment {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )] # Terminate CmdletBinding

    Param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('repository_id')][Int]$Repository,
        [Parameter(Position=1)]
        [Alias('environment_id')][Int]$Environment,
        [Parameter(Position=2)][Int]$ID,

        [Parameter(Position=3, Mandatory=$true)][String]$Organization,
        [Parameter(Position=4, Mandatory=$true)][String]$ApiKey
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

        If (-not ($Repository -or $Environment)) {
            Write-Error "Repository or Environment is required."
            Break
        } # Terminate If - Neither Repository or Environment Defined

        If ($ID) { 
            $filter = "/$ID"   
        } Else {
            $filter = $null
        } # Terminate If - Filter

        If ($Repository) {
            $repositoryFilter = "repository_id=$($Repository)"
        } Else {
            $repositoryFilter = $null
        } # Terminate If - Repository

        If ($Environment) {
            $environmentFilter = "environment_id=$($Environment)"
        } Else {
            $environmentFilter = $null
        } # Terminate If - Repository

        If ($Repository -and $Environment) {
            $both = "&"
        } # Terminate If - Both

        $URI = "$url/deployments$($filter)?$($repositoryFilter)$($both)$($environmentFilter)"

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
                If ($ID) {
                    $response
                } Else {
                    $response | Select -ExpandProperty entries
                } # Terminate If - ID
            } Else {
                Write-Error "No Response Received"
            } # Terminate If - Response
        } # Terminate If - WhatIf
    } # Terminate Process

    <#
        .SYNOPSIS
            This function will retrieve a specified DeployBot deployment or all deployments in a given repository.

        .DESCRIPTION
            This function will retrieve a specified DeployBot deployment or all deployments in a given repository.         

        .EXAMPLE
            Get-DBDeployment

        .NOTES
            I recommend putting in your Powershell profile (both ISE & console) the following so that the functions
            do not prompt for the ApiKey and Organization every time.

            $PSDefaultParameterValues = @{
                '*-DB*:ApiKey'       = 'apikey'
                '*-DB*:Organization' = 'organization'
            }
    #>
} # Terminate Function