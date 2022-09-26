# powershell-azure-sql-export

Export Azure SQL database to a blob container, create the blob container if necessary. Delete older backup.

Email notification after export is done.

You will need to create in Automation Account > Shared Resources > Variables.

Variables required:
ResourceGroupName = Name of Resource Group where the Azure SQL is located.
DatabaseServerName = Name of Azure SQL database server.
DatabaseAdminUsername = Administrator username of the Azure SQL Database Server.
DatabaseAdminPassword = Administrator password of the Azure SQL Database Server.
DatabaseNames = Comma separated list of databases script will backup.
StorageAccountName = Name of the storage account where backup file will be uploaded.
BlobStorageEndpoint = Base URL of the storage account.
StorageKey =  Storage key of the storage account, get it from Storage Account.
BlobContainerName = Container name of the storage account where backup file will be uploaded. Container will be created if it does not exist.
RetentionDays = Number of days how long backups are kept in blob storage. Script will remove all older files from container. 
	For this reason dedicated container should be only used for this script.
ErrorActionPreference = stop

MailBody = Body of email.
SmtpServer = SMTP server.
SmtpUser = SMTP user name.
SmtpPassword = SMTP Password.
MailFrom = Email address of sender.
MailTo = Email address of recipient.
MailSubject = Email subject.
