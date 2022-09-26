<#
.SYNOPSIS
	This Azure Automation runbook automates Azure SQL database backup to Blob storage and deletes old backups from blob storage. 

.DESCRIPTION
	You should use this Runbook if you want manage Azure SQL database backups in Blob storage. 
	This is a PowerShell runbook, as opposed to a PowerShell Workflow runbook.

.OUTPUTS
	Human-readable informational and error messages produced during the job. Not intended to be consumed by another runbook.

#>

Import-Module Az.SQL

$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$DatabaseServerName = Get-AutomationVariable -Name 'DatabaseServerName'
$DatabaseAdminUsername = Get-AutomationVariable -Name 'DatabaseAdminUsername'
$DatabaseAdminPassword = Get-AutomationVariable -Name 'DatabaseAdminPassword'
$DatabaseNames = Get-AutomationVariable -Name 'DatabaseNames'
$StorageAccountName = Get-AutomationVariable -Name 'StorageAccountName'
$BlobStorageEndpoint = Get-AutomationVariable -Name 'BlobStorageEndpoint'
$StorageKey =  Get-AutomationVariable -Name 'StorageKey'
$BlobContainerName = Get-AutomationVariable -Name 'BlobContainerName'
$RetentionDays = Get-AutomationVariable -Name 'RetentionDays'
$ErrorActionPreference = Get-AutomationVariable -Name 'ErrorActionPreference'

$MailBody = Get-AutomationVariable -Name 'MailBody'
$SmtpServer = Get-AutomationVariable -Name 'SmtpServer'
$SmtpUser = Get-AutomationVariable -Name 'SmtpUser'
$SmtpPassword = Get-AutomationVariable -Name 'SmtpPassword'
$MailFrom = Get-AutomationVariable -Name 'MailFrom'
$MailTo = Get-AutomationVariable -Name 'MailTo'
$MailSubject = Get-AutomationVariable -Name 'MailSubject'

Connect-AzAccount -Identity

function Create-Blob-Container([string]$blobContainerName, $storageContext) {
	Write-Verbose "Checking if blob container '$blobContainerName' already exists" -Verbose
	if (Get-AzureStorageContainer -ErrorAction "Stop" -Context $storageContext | Where-Object { $_.Name -eq $blobContainerName }) {
		Write-Verbose "Container '$blobContainerName' already exists" -Verbose
	} else {
		New-AzureStorageContainer -ErrorAction "Stop" -Name $blobContainerName -Permission Off -Context $storageContext
		Write-Verbose "Container '$blobContainerName' created" -Verbose
	}
}

function Export-To-Blob-Storage([string]$resourceGroupName, [string]$databaseServerName, [string]$databaseAdminUsername, [string]$databaseAdminPassword, [string[]]$databaseNames, [string]$storageKey, [string]$blobStorageEndpoint, [string]$blobContainerName) {
	Write-Verbose "Starting database export to databases '$databaseNames'" -Verbose
	$securePassword = ConvertTo-SecureString –String $databaseAdminPassword –AsPlainText -Force 
	$creds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $databaseAdminUsername, $securePassword

	foreach ($databaseName in $databaseNames.Split(",").Trim()) {
		Write-Output "Creating request to backup database '$databaseName'"

		$bacpacFilename = $databaseName + (Get-Date).ToString("yyyyMMddHHmm") + ".bacpac"
		$bacpacUri = $blobStorageEndpoint + $blobContainerName + "/" + $bacpacFilename

		$exportRequest = New-AzSqlDatabaseExport -ResourceGroupName $resourceGroupName –ServerName $databaseServerName `
			–DatabaseName $databaseName –StorageKeytype "StorageAccessKey" –storageKey $storageKey -StorageUri $BacpacUri `
			–AdministratorLogin $creds.UserName –AdministratorLoginPassword $creds.Password -ErrorAction "Stop"
		
		# Print status of the export
		Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink -ErrorAction "Stop"
	}
}

function Delete-Old-Backups([int]$retentionDays, [string]$blobContainerName, $storageContext) {
	Write-Output "Removing backups older than '$retentionDays' days from blob: '$blobContainerName'"
	$isOldDate = [DateTime]::UtcNow.AddDays(-$retentionDays)
	$blobs = Get-AzureStorageBlob -Container $blobContainerName -Context $storageContext
	foreach ($blob in ($blobs | Where-Object { $_.LastModified.UtcDateTime -lt $isOldDate -and $_.BlobType -eq "BlockBlob" })) {
		Write-Verbose ("Removing blob: " + $blob.Name) -Verbose
		Remove-AzureStorageBlob -Blob $blob.Name -Container $blobContainerName -Context $storageContext
	}
}

Write-Verbose "Starting database backup" -Verbose

$StorageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey

Create-Blob-Container `
	-blobContainerName $blobContainerName `
	-storageContext $storageContext
	
Export-To-Blob-Storage `
	-resourceGroupName $ResourceGroupName `
	-databaseServerName $DatabaseServerName `
	-databaseAdminUsername $DatabaseAdminUsername `
	-databaseAdminPassword $DatabaseAdminPassword `
	-databaseNames $DatabaseNames `
	-storageKey $StorageKey `
	-blobStorageEndpoint $BlobStorageEndpoint `
	-blobContainerName $BlobContainerName
	
Delete-Old-Backups `
	-retentionDays $RetentionDays `
	-storageContext $StorageContext `
	-blobContainerName $BlobContainerName
	
Write-Verbose "Database backup script finished" -Verbose

#Send notification email
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($SmtpPassword | ConvertTo-SecureString -AsPlainText -Force)  
Send-MailMessage -To "$MailTo" -from "$MailFrom" -Subject $MailSubject -Body "$MailBody" -SmtpServer $SmtpServer -BodyAsHtml -UseSsl -Credential $Credentials -port 587
