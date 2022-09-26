# powershell-azure-sql-export
What the script does:
Export Azure SQL database to a blob container, create the blob container if necessary. Delete older backup.
Email notification after export is done.

You will need to create in Automation Account > Shared Resources > Variables.

**Variables required:**<br />
ResourceGroupName = Name of Resource Group where the Azure SQL is located.<br />
DatabaseServerName = Name of Azure SQL database server.<br />
DatabaseAdminUsername = Administrator username of the Azure SQL Database Server.<br />
DatabaseAdminPassword = Administrator password of the Azure SQL Database Server.<br />
DatabaseNames = Comma separated list of databases script will backup.<br />
StorageAccountName = Name of the storage account where backup file will be uploaded.<br />
BlobStorageEndpoint = Base URL of the storage account.<br />
StorageKey =  Storage key of the storage account, get it from Storage Account.<br />
BlobContainerName = Container name of the storage account where backup file will be uploaded. Container will be created if it does not exist.<br />
RetentionDays = Number of days how long backups are kept in blob storage. Script will remove all older files from container. For this reason dedicated container should be only used for this script.<br />
ErrorActionPreference = stop<br />

MailBody = Body of email.<br />
SmtpServer = SMTP server.<br />
SmtpUser = SMTP user name.<br />
SmtpPassword = SMTP Password.<br />
MailFrom = Email address of sender.<br />
MailTo = Email address of recipient.<br />
MailSubject = Email subject.<br />
