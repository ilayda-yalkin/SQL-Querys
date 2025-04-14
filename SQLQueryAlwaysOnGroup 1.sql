DECLARE @sql NVARCHAR(max);
DECLARE @loginName NVARCHAR(255);
DECLARE @defaultDB NVARCHAR(255);
DECLARE @defaultLang NVARCHAR(255);
DECLARE @passwordHash VARBINARY(max);
DECLARE @SID VARBINARY(85);
DECLARE @roleName NVARCHAR(255);

--PRIMARY (Server1) -> SECONDARY (Server2)
BEGIN TRY
DECLARE login_cursor CURSOR FOR 
    SELECT name , default_database_name, default_language_name, pssword_hash, sid  FROM [server1].sys.server_principals WHERE type IN ('S' , 'U') AND NOT LIKE '##%';
OPEN login_cursor;
FETCH NEXT FROM login_cursor INTO @loginName, @defaultDB, @defaultLang, @passwordHash, @SID;

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @passwordHash IS NOT NULL
	BEGIN
		SET @sql = N'IF NOT EXISTS (SELECT * FROM [server2].sys.server_principals WHERE name = @loginName)
		BEGIN
	    CREATE LOGIN [' + @loginName + '] WITH PASSWORD = 0x ' + CONVERT(NVARCHAR(MAX), @passwordHash, 2) +' HASHED,
		SID = 0x' + CONVERT(NVARCHAR(MAX), @SID, 2)+',
		DEFAULT_DATABASE = [' + @defaultDB + '], DEFAULT_LANGUAGE = [' + @defaultLang + '];
	END';
EXEC sp_executesql @sql, N'@loginName NVARCHAR(255), @passwordHash VARBINARY(MAX), @SID VARBINARY (85), @defaultDB NVARCHAR(255), defaultLang NVARCHAR(255)', @loginName, @passwordHash, @SID, @defaultDB, @defaultLang;
END;

--Kullan?c?n?n Rollerini Kopyal?yor
DECLARE role_cursor CURSOR FOR
    SELECT r.name FROM [server1].sys.server_role_members rm JOIN [server1].sys.server_principals r ON rm.role_principal_id = r.principal_id
	WHERE rm.member_principal_id = (SELECT principal_id FROM [server1].sys.server_principals WHERE name = @loginName);
OPEN role_cursor;
FETCH NEXT FROM role_cursor INTO @roleName;

WHILE @@FETCH_STATUS = 0
BEGIN 
    SET @sql = N'EXEC [server2].sq_addsrvrolemember @loginName, @roleName';
	EXEC sp_executesql @sql, N'@loginName NVARCHAR(255), @roleName NVARCHAR(255)', @loginName, @roleName;

	FETCH NEXT FROM role_cursor INTO @roleName;
END
CLOSE role_cursor;
DEALLOCATE role_cursor;

FETCH NEXT FROM login_cursor INTO @loginName, @defaultDB, @defaultLang, @passwordHash, @SID;
END
CLOSE login_cursor;
DEALLOCATE login_cursor;

--SECONDARY (Server2) -> PRIMARY (Server1)
DECLARE login_cursor_2 CURSOR FOR SELECT name ,default_database_name, default_language_name FROM [server2].sys.server_principals WHERE type IN ('S', 'U') AND name NOT LIKE '##%'

OPEN login_cursor_2;
FETCH NEXT FROM login_cursor_2 INTO @loginName, @defaultDB, @defaultLang;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @passwordHash = password_hash, @SID = sid FROM [server2].sys.sql_logins WHERE name = @loginName;
	IF @passwordHash IS NOT NULL BEGIN
		SET @sql = N'IF NOT EXISTS (SELECT * FROM [server1].sys.server_principals WHERE name = @loginName);
		BEGIN 
			CREATE LOGIN [' + @loginName + '] WITH PASSWORD = 0x ' + CONVERT(NVARCHAR(MAX), @passwordHash, 2) + ' HASHED,
			SID = 0x'+ CONVERT(NVARCHAR(MAX), @SID,2) +',
			WITH DEFAULT_DATABASE = [' + @defaultDB + '], DEFAULT_LANGUAGE = [' + @defaultLang + '];
			END';
		EXEC sp_executesql @sql, N'@loginName NVARCHAR(255), @passwordHash VARBINARY(MAX), @SID VARBINARY(85),@defaultDB NVARCHAR(255), @defaultLang NVARCHAR(255)', @loginName, @passwordHash, @SID, @defaultDB, @defaultLang;

		--Kullan?c? Rollerini Kopyal?yor
		DECLARE role_cursor_2 CURSOR FOR
			SELECT r.name FROM [server2].sys.server_role_members rm
			JOIN [server2].sys.server_principals r ON rm.role_principal_id = r.principal_id
			WHERE rm.member_principal_id = (SELECT principal_id FROM [server2].sys.server_principals WHERE name = @loginName);
		
		OPEN role_cursor_2;
		FETCH NEXT FROM role_cursor_2 INTO @roleName;

		While @@FETCH_STATUS = 0
		BEGIN
			SET @sql = N'EXEC [server1].sp_addsrvrolemember @loginName, @roleName';
			EXEC sp_executesql @sql, N'@loginName nvarchar(255), @roleName nvarchar(255)', @loginName, @roleName;
			FETCH NEXT FROM role_cursor_2 INTO @roleName;
			END
			CLOSE role_cursor_2;
			DEALLOCATE role_cursor_2;
			END
			FETCH NEXT FROM login_cursor_2 INTO @loginName, @defaultDB, @defaultLang;
			END
			CLOSE login_cursor_2;
			DEALLOCATE login_cursor_2;
			PRINT 'Kullan?c? e?itleme i?lemi tamamland?!';
		END TRY
		BEGIN CATCH
			PRINT 'Hata olu?tu:' + ERROR_MESSAGE();
		END CATCH;
				