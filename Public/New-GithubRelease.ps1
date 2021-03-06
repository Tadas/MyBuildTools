﻿function New-GithubRelease {
	Param(
		[Parameter(Mandatory=$true)]
		[string]$ProjectName,

		[Parameter(Mandatory=$true)]
		[string]$Uri,

		[Parameter(Mandatory=$true)]
		[Version]$NewVersion,

		[string]$ReleaseNotes = "",

		[bool]$Draft = $false,

		[bool]$PreRelease = $false,

		[Parameter(Mandatory=$true)]
		[string]$ArtifactPath,

		[Parameter(Mandatory=$true)]
		[string]$UserName,

		[Parameter(Mandatory=$true)]
		[string]$ApiKey
	)

	$gitHubApiKey = Get-GitHubAPIKey

	$ReleaseParams = @{
		Uri         = $Uri
		Method      = 'POST'
		Headers     = @{
			Authorization = 'Basic {0}' -f ([System.Convert]::ToBase64String([char[]]"${$UserName}:$ApiKey"))
		}
		Body        = @{
			tag_name         = $NewVersion.ToString()
			target_commitish = git rev-parse HEAD
			name             = [string]::Format("{0} v{1}", $ProjectName, $NewVersion)
			body             = $ReleaseNotes
			draft            = $Draft
			prerelease       = $PreRelease
		} | ConvertTo-Json -Compress
		ContentType = 'application/json'
	}

	[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
	Write-Verbose "Creating a release: $($ReleaseParams | ConvertTo-Json)"
	$NewReleaseResult = Invoke-RestMethod @releaseParams

	Write-Verbose "Received an upload url → $($NewReleaseResult.upload_url)" 

	$UploadParams = @{
		Uri        = $NewReleaseResult.upload_url -replace '\{\?name,label\}', "?name=$(Split-Path -Leaf $ArtifactPath)"; Method = 'POST';
		Headers    = @{
			Authorization = 'Basic {0}' -f ([System.Convert]::ToBase64String([char[]]"${$UserName}:$ApiKey"))
		}
		InFile      = $ArtifactPath
		ContentType = 'application/zip'
	}

	$UploadResult = Invoke-RestMethod @uploadParams
}