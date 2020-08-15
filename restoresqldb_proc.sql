 create or alter procedure restoration 
	 @dbname nvarchar(50),
	 @script tinyint = 1,
	 @copy_only tinyint = 0,
	 @tail_log tinyint = 0
 as
 set nocount on
 -- create a table variable
 declare  @backupset table 
	 (first_lsn nvarchar(150), 
	 database_backup_lsn nvarchar(150),
	 last_lsn nvarchar(150), 
	 database_name nvarchar(150), 
	 physical_device_name nvarchar(150),
	 differential_base_lsn nvarchar(150),
	 type nvarchar(10),
	 backup_start_date datetime, 
	 script nvarchar(150))

	 -- set database to single_user mode to rollback all transactions on the database
	 	 insert into @backupset 
		select distinct null, 
			null, 
			null, 
			null, 
			null, 
			null,
			'a', 
			null, 
			'use master
			ALTER DATABASE '+@dbname+' SET SINGLE_USER WITH ROLLBACK IMMEDIATE' as [script]
	 from msdb..backupset   
		where database_name = @dbname 

	 -- if tail log backup is flagged
 if (@tail_log = 1)
	 begin
		insert into @backupset 
			select distinct null, 
				null, 
				null, 
				null, 
				null, 
				null,
				'b', 
				null, 
			    'BACKUP LOG '+ @dbname+' TO  DISK = N''C:\temp\'+@dbname+'.bak'' WITH NOFORMAT, NOINIT,  NOSKIP, NOREWIND, NOUNLOAD,  NORECOVERY ,  STATS = 5' as [script]
	 end
 else
	 begin
	 print 'truncating tail_log'
	 end
 if (@copy_only = 0)
	 begin
		-- full backups
		 insert into @backupset 
			 select a.first_lsn, 
			 a.database_backup_lsn,
			 a.last_lsn, 
			 a.database_name, 
			 b.physical_device_name,
			 a.differential_base_lsn,
			 a.type,
			 a.backup_start_date, 
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with FILE = 1,  NORECOVERY,  NOUNLOAD,  REPLACE' as [script] 
		 from msdb..backupset a  
		 join msdb..backupmediafamily b on a.media_set_id = b.media_set_id 
				 where  backup_start_date >= (select max(backup_start_date) from msdb..backupset where database_name = @dbname and [type]= 'D' and is_copy_only = 0  ) 
					 and a.type ='D'
					 and a.database_name = @dbname  and is_copy_only = 0
		-- Differential Backups
		 insert into @backupset 
			 select top 1 a.first_lsn, 
			 a.database_backup_lsn,
			 a.last_lsn, 
			 a.database_name, 
			 b.physical_device_name,
			 a.differential_base_lsn,
			 a.type,
			 max(a.backup_start_date), 
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with FILE = 1,  NORECOVERY,  NOUNLOAD' as [script] 
		 from msdb..backupset a  
		 join msdb..backupmediafamily b on a.media_set_id = b.media_set_id 
				 where  backup_start_date >= (select max(backup_start_date) from msdb..backupset where database_name = @dbname and [type]= 'D' and is_copy_only = 0  ) 
					 and a.type ='I' 
					 and a.database_name = @dbname   
					 and is_copy_only = 0
						 group by a.first_lsn, 
						 a.database_backup_lsn,
						 a.last_lsn, 
						 a.database_name, 
						 b.physical_device_name,
						 a.differential_base_lsn, 
						 a.type
		-- Log backups
		 insert into @backupset 
			 select a.first_lsn, 
			 a.database_backup_lsn,
			 a.last_lsn, 
			 a.database_name, 
			 b.physical_device_name,
			 a.differential_base_lsn,
			 a.type,a.backup_start_date,
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with FILE = 1,  NORECOVERY,  NOUNLOAD' as [script] 
		 from msdb..backupset a  
		 join msdb..backupmediafamily b on a.media_set_id = b.media_set_id 
				 where  backup_start_date >= (select max(backup_start_date) from msdb..backupset where database_name = @dbname and [type] in ('I' ,'D') and is_copy_only = 0 ) 
					 and a.type ='L'
					 and a.database_name = @dbname 
					 and is_copy_only = 0
	end

else 
	begin
		 insert into @backupset 
			 select a.first_lsn, 
				 a.database_backup_lsn,
				 a.last_lsn, 
				 a.database_name, 
				 b.physical_device_name,
				 a.differential_base_lsn,
				 a.type,
				 a.backup_start_date, 
				 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with FILE = 1,  NORECOVERY,  NOUNLOAD' as [script] 
		 from msdb..backupset a  
		 join msdb..backupmediafamily b on a.media_set_id = b.media_set_id 
				 where  backup_start_date >= (select max(backup_start_date) from msdb..backupset where database_name = @dbname and [type]= 'D' ) 
					 and a.type ='D'
					 and a.database_name = @dbname  

	end

	-- now finally restore database	WITH RECOVERY
	 insert into @backupset 
		select distinct null, 
			null, 
			null, 
			null, 
			null, 
			null,
			'z', 
			null, 
			'restore database '+ database_name + ' with recovery' as [script] 
	 from msdb..backupset   
		where database_name = @dbname 

		-- set database back to multi_user
			 insert into @backupset 
		select distinct null, 
			null, 
			null, 
			null, 
			null, 
			null,
			'z', 
			null, 
			'ALTER DATABASE '+@dbname+' SET MULTI_USER' as [script] 
	 from msdb..backupset   
		where database_name = @dbname 

if (@script = 0)
	begin
		select * from @backupset order by type 
	end
if (@script = 1)
	begin
		select script from @backupset order by type 
	end




