Create Table ReplicationInformation (
ID INT IDENTITY(1,1) PRIMARY KEY,
SourceDB NVARCHAR(50),
TargetDB NVARCHAR(50),
TableName NVARCHAR(50),
PublicationName NVARCHAR(50),
ReplicationType NVARCHAR(50),
Schedule int);


INSERT INTO ReplicationInformation (SourceDB, TargetDB, TableName, PublicationName, ReplicationType, Schedule)
SELECT
p.publisher_db AS SourceDB,
s.subscriber_db AS TargetDB,
art.article AS TableName,
p.publication AS PublicationName,
CASE sch.freq_type
WHEN 1 THEN 'Tranactional Replication'
WHEN 2 THEN 'Snapshot Replication'
WHEN 3 THEN 'Merge replication'
ELSE 'Unknown Type'
END AS ReplicationType,
CASE sch.freq_subday_type
WHEN 1 THEN CONCAT(sch.freq_subday_interval, 'Once An Second')
WHEN 2 THEN CONCAT(sch.freq_subday_interval, 'Once An Minute')
WHEN 4 THEN CONCAT(sch.freq_subday_interval, 'Once An Hour')
ELSE 'Uncertain' 
END AS Schedule


FROM msdb.dbo.MSpublications p JOIN msdb.dbo.MSdistribution_agents s ON p.publication_id = s.publisher_database_id
JOIN distribution.dbo.MSarticles art ON p.publication_id = art.publication_id
JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
JOIN msdb.dbo.sysschedules sch ON js.schedule_id = sch.schedule_id;