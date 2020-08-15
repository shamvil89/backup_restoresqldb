
create or alter procedure db_backup
	@path nvarchar(max), 
	@backuptype tinyint = 1, 
	@copy_only tinyint = 0,
	@db_name nvarchar(max)
as

begin

--declaration zone
declare @type char (4)
declare @filename nvarchar(80)
declare @datetime varchar (15)
declare @sql nvarchar(500)
declare @recmod tinyint
--logic 
if (@copy_only = 1)
	begin 
	set @backuptype = 4
	end
if @backuptype  not in (1,2,3,4)
	begin
	set @backuptype = 1
	print 'bad parameter input upgrading backuptype to full'
	end
set @recmod = (select recovery_model from sys.databases where name = @db_name)
if (@recmod = 3 and @backuptype = 3)
	begin set @backuptype = 1 
	print 'cannot take log backup of databases under simple recovery model' 
	end
set @type = (select  case when @backuptype = 1 then   'full'
		 when @backuptype = 2 then  'Diff'
		 when @backuptype = 3 then  'Log_'
		 when @backuptype = 4 then 'copy'
		ELSE
		 'full'
		END)
set @datetime = (select convert(varchar, datepart(dd,getdate())) + convert(varchar, datepart(mm,getdate())) + convert(varchar, datepart(yyyy,getdate())) + convert(varchar, datepart(hh,getdate())) + convert(varchar, datepart(MINUTE,getdate())))
set @filename = @db_name+'_'+@type+'_'+@datetime+'.bak'

if @db_name = 'tempdb'
	begin
		print 'cannot backup tempdb'
	end
else
	begin
		set @sql = (select  case when @backuptype = 1 then   ('backup database '+ @db_name + ' to disk = ''' + @path + @filename +''' with stats =5') -- full backup
			 when @backuptype = 2 then  ('backup database '+ @db_name + ' to disk = ''' + @path + @filename +''' with DIFFERENTIAL, stats =5') -- differential backup
			 when @backuptype = 3 then  ('backup LOG  '+ @db_name + ' to disk = ''' + @path + @filename +''' with stats =5') -- log backup
			 when @backuptype = 4 then  ('backup database '+ @db_name + ' to disk = ''' + @path + @filename +''' with copy_only ,stats =5')
			 ELSE
				 'full' -- bad input will escalate backup to full
	end)
end

--EXEC zone
print (@db_name)
print (@sql)
exec (@sql)


-- The end
END
	

-- exec db_backup @path='c:\temp\' , @db_name = 'stackoverflow2013', @backuptype = 3