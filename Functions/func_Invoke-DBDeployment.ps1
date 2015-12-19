#Requires -Version 4.0

<#
 # Script FileName: func_Invoke-DBDeployment.ps1
 # Current Version: A02
 # Description: Start a DeployBot Deployment
 # Created By: Adam Listek
 # Version Notes
 #      A01 - Initial Release
 #      A02 - Further Refinement
 #>

Function Invoke-DBDeployment {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High"
    )] # Terminate CmdletBinding

    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('environment_id')][Int]$Environment,
        [Parameter(Position=1)][Int]$User,
        [Parameter(Position=2)][String]$Version,
        [Parameter(Position=3)][String]$Comment,

        [Parameter(Position=4, Mandatory=$true)][String]$Organization,
        [Parameter(Position=5, Mandatory=$true)][String]$ApiKey,

        [Switch]$DeployFromScratch,
        [Switch]$TriggerNotifications
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

        $body = [Ordered]@{
            "environment_id" = $Environment
        }

        If ($User) {
            $body.Add("user_id",$User)
        } # Terminate If - User

        If ($Version) {
            $body.Add("deployed_version",$Version)
        } # Terminate If - Version

        If ($Comment) {
            $body.Add("comment",$Comment)
        } # Terminate If - Comment

        If ($DeployFromScratch) {
            $body.Add("deploy_from_scratch",$True)
        } # Terminate If - Deploy From Scratch

        If ($TriggerNotifications) {
            $body.Add("trigger_notifications",$True)
        } Else {
            $body.Add("trigger_notifications",$False)
        } # Terminate If - Trigger Notifications

        $URI = "$url/deployments"

        Write-Verbose $URI
        Write-Verbose ($body | Out-String)

        If (-not $whatif) {
            Try {
                $response = Invoke-WebRequest -Uri $URI -Method POST -Headers $header -Body $body -ErrorAction Stop -Verbose:$local:verbose -Debug:$local:debug `
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
                $response
            } Else {
                Write-Error "No Response Received"
            } # Terminate If - Response
        } # Terminate If - Whatif
    } # Terminate Process

    <#
        .SYNOPSIS
            
        .DESCRIPTION

        .PARAMETER

        .EXAMPLE

        .NOTES
    #>
} # Terminate Function