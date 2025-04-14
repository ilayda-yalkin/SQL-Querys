 --Database Properties
 SELECT
    name AS DatabaseName,
	state_desc AS DatabaseState,
	recovery_model_desc AS RecoveryModel,
	compatibility_level AS CompatibilityLevel,
	create_date AS CreateDate
FROM sys.databases;

--Tables and Columns
SELECT
    t.name AS TableName,
	c.name AS CloumnName,
	c.column_id AS ColumnID,
	ty.name AS DataType,
	c.max_length AS MaxLength,
	c.is_nullable AS IsNullAble,
	c.is_identity AS IsIdentity
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY t.name, c.column_id;

--Indexes
SELECT
   t.name AS TableName,
   i.name AS IndexName,
   i.type_desc AS IndexType,
   i.is_primary_key AS IsPrimaryKey,
   i.is_unique AS IsUnique,
   s.fill_factor AS FillFactor,
   i.is_disabled AS IsDisabled
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
LEFT JOIN sys.stats s ON i.object_id = s.object_id AND i.index_id = s.stats_id
ORDER BY t.name, i.name;

--Restrictions and Keys
SELECT
   t.name AS TableName,
   c.name AS ColumnName,
   con.name AS ConstraintName,
   con.type_desc AS ConstraintType
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id 
JOIN sys.constraints con ON c.column_id = con.parent_column_id AND c.object_id = con.parent_object_id
ORDER BY t.name, con.name;

--Views
SELECT
   v.name AS ViewName,
   m.definition AS ViewDefinition
FROM sys.views v
JOIN sys.sql_modules m ON v.object_id = m.object_id
ORDER BY v.name;

--Stored Prosedures
SELECT
   p.name AS ProsedurName,
   m.definition AS ProsedurDefinition
FROM sys.procedures p 
JOIN sys.sql_modules m ON p.object_id = m.object_id
ORDER BY p.name;

--Functions
SELECT
   f.name AS FunctionName,
   m.definition AS FunctionDefinition
   FROM sys.objects f 
JOIN sys.sql_modules m ON f.object_id = m.object_id
WHERE f.type IN ('FN', 'IF', 'TF')
ORDER BY f.name;

--Triggers
SELECT
   t.name AS TriggerName,
   m.definition AS TriggerDefinition,
   o.name AS TableName
FROM sys.triggers t
JOIN sys.sql_modules m ON t.object_id = m.object_id
JOIN sys.objects o ON t.parent_id = o.object_id
ORDER BY t.name;

--Users ande Roles
SELECT
   u.name AS UserName,
   r.name AS RoleName
FROM sys.database_principals u
JOIN sys.database_role_members rm ON u.principal_id = rm.member_principal_id
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE u.type IN ('S', 'U')
ORDER BY u.name;

--Database Backups
SELECT 
   database_name,
   backup_finish_date,
   backup_type AS BackupType,
   physical_device_name
FROM msdb.dbo.backupset b
JOIN msdb.dbo.backupmediafamily m ON b.media_set_id = m.media_set_id
ORDER BY backup_finish_date DESC;

--Replication Information
--Publications
SELECT 
   publication AS PublicationName,
   publication_type AS PublicationType
   publisher_db AS PublisherDatabase
FROM distribution.dbo.syspublications;

--Subscriptons
SELECT
   s.srvname AS SubscriberServer,
   d.name AS SubscriptionDatabase
   FROM distribution.dbo.MSsubcriptions ms
   JOIN master.dbo.sysservers s ON ms.subcriber_id = s.srvid
   JOIN master.sys.databases d ON ms.subscriber_dbid = d.database_id;

--User-Defined Types
SELECT
   name,
   system_type_id,
   user_type_id
FROM sys.types
WHERE is_user_defined = 1;

--Full-Text Index
SELECT
   ft.object_id AS FullTextIndexID,
   t.name AS TableName
FROM sys.fulltext_indexes ft 
JOIN sys.tables t ON ft.object_id = t.object_id;

--External Links
SELECT * FROM sys.servers WHERE is_linked = 1;

--SQL Server Agent Jobs
SELECT
   job.name AS JobName,
   job.enabled AS IsEnabled
FROM msdb.dbo.sysjobs job;

--System Tables and Views
SELECT
   name AS SystemObjectName,
   type_desc AS ObjectType
FROM sys.objects
WHERE is_ms_shipped = 1
ORDER BY name;

--Database Operation (logs)
SELECT*FROM sys.fn_dblog(NULL,NULL);

--Query Tracking Information
SELECT
   spid,
   blocked,
   waittime,
   lastwaittype,
   cpu,
   physical_io
FROM sys.sysprocesses
WHERE dbid = DB_ID('DatabaseName');

--Active Connections and Server Sessions
SELECT
   login_name,
   host_name,
   program_name,
   status,
   login_time,
   last_request_start_time
FROM sys.dm_exec_sessions
ORDER BY login_time DESC;