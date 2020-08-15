 create or alter procedure restoration 
	 @dbname nvarchar(50),
	 @script tinyint = 1,
	 @copy_only tinyint = 0
 as

 declare  @backupset table 
	 (first_lsn nvarchar(100), 
	 database_backup_lsn nvarchar(100),
	 last_lsn nvarchar(100), 
	 database_name nvarchar(100), 
	 physical_device_name nvarchar(100),
	 differential_base_lsn nvarchar(100),
	 type nvarchar(10),
	 backup_start_date datetime, 
	 script nvarchar(100))

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
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with norecovery' as [script] 
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
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with norecovery' as [script] 
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
			 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with norecovery' as [script] 
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
				 'restore database ' + a.database_name + ' from disk = ''' + b.physical_device_name +''' with norecovery' as [script] 
		 from msdb..backupset a  
		 join msdb..backupmediafamily b on a.media_set_id = b.media_set_id 
				 where  backup_start_date >= (select max(backup_start_date) from msdb..backupset where database_name = @dbname and [type]= 'D' ) 
					 and a.type ='D'
					 and a.database_name = @dbname  

	end

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

if (@script = 0)
	begin
		select * from @backupset order by type 
	end
if (@script = 1)
	begin
		select script from @backupset order by type 
	end