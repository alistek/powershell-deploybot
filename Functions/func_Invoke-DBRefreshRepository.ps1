#Requires -Version 4.0

<#
 # Script FileName: func_Invoke-DBRefreshRepository.ps1
 # Current Version: A01
 # Description: Refresh DeployBot Repositories
 # Created By: Adam Listek
 # Version Notes
 #      A01 - Initial Release
 #>

Function Invoke-DBRefreshRepository {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )] # Terminate CmdletBinding

    Param(
        [Parameter(Position=0)][String]$Name,
        [Parameter(Position=1)][Int]$ID,

        [Parameter(Position=2, Mandatory=$true)][String]$Organization,
        [Parameter(Position=3, Mandatory=$true)][String]$ApiKey
    ) # Terminate Param

	Begin {
        If ($MyInvocation.BoundParameters.Verbose -match $true) {
            $local:VerbosePreference = "Continue"
            $local:ErrorActionPreference = "Continue"
            $local:verbose = $true
        } Else {
            $local:VerbosePreference = "SilentlyContinue"
            $local:ErrorActionPreference = "SilentlyContinue"
            $local:verbose = $false
        } # Terminate If - Verbose Parameter Check

        If ($MyInvocation.BoundParameters.Debug -eq $true) {
            $local:debug = $true
        } Else {
            $local:debug = $false
        } # Terminate Preferences

        If ($MyInvocation.BoundParameters.WhatIf -eq $true) {
            $local:whatif = $true
        } Else {
            $local:whatif = $false
        } # Terminate Preferences

        # Current Script Name
        $scriptName = $MyInvocation.MyCommand.Name
    } # Terminate Begin

    Process {
        If (-not $name -and -not $id) {
            If (Get-ChildItem ".git") {
                $name = ((Get-Location).Path -split "\\")[-1]   
            } Else {
                Write-Host "A name, ID or location in valid GIT repository is required" -BackgroundColor Red
                Break            
            }# Terminate If - Git
        } # Terminate If - No Name or ID

        Write-Verbose $name

        If ($name) {
            $repository = Get-DBRepository -Name $name -Verbose:$verbose -Organization:$Organization -ApiKey:$ApiKey
        } ElseIf ($id) {
            $repository = Get-DBRepository -ID $id -Verbose:$verbose -Organization:$Organization -ApiKey:$ApiKey
        } # Terminate If - Name or ID

        Write-Verbose $repository

        If ($repository) {
            Try {
                $response = Invoke-WebRequest -Uri $repository.refresh_webhook_url -Method GET -Verbose:$verbose
            } Catch {
                Write-Host $error[0] -BackgroundColor Red
                Break
            } # Terminate Try-Catch

            If ($response.Content -EQ "Thank you") {
                Write-Host "Repository Updated"
            } Else {
                Write-Host "Something went wrong..." -BackgroundColor Red
            } # Terminate If - Response
        } Else {
            Write-Host "Unable to retrieve repository" -BackgroundColor Red
        } # Terminate If - Repository
    } # Terminate Process
} # Terminate Function