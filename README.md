# backup_restoresqldb
This repository is a combination of two stored procedures that are designed for taking backup of Microsoft SQL databases (On-premise) and create a restore script respectively

1. backupsqldb_proc file creates stored procedure called "db_backup"
    Mandatory Parameters:
      @path - mention path where you want to store your backup files. (this have not yet been tested on network path or tape)
      @db_name - the name of database that you want to take backup of.
                 you can use this stored procedure with another stored procedure 'ms_foreachdb' to execute against all databases on server.
                      Example:
                        You can create three seperate jobs for each type of backups and use below script
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 1 , @db_name =[?]'
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 2 , @db_name =[?]'
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 3 , @db_name =[?]'
    Optional Parameters:
      @backuptype - This parameter decides the type of backup. default is set to full backup
          Values -
           1 - Full backup
           2 - Differential Backup
           3 - Log Backup
           4 - Copy Only backup
      @copy_only - This parameter takes copy_only backup of a database (redundant feature)
   
   
2. restoresqldb_proc file creates stored procedure called "restoration"
    Mandatory Parameters:
      @db_name - the name of database that you want to take restore
                 
    Optional Parameters:
      @script - By default, only script will be displayed. However, if you want to analyse LSN related information you can change the value to 0
                Example:
                          restoration 'testdb', @script = 0
      @Copy_Only - If you want to get a restore script for copyonly backup, use parameter - @copy_only =1. By default the value is set to 0
      @tail_log - If you want to take a tail log backup before restoring the database, enable parameter @tail_log = 1. This will add tail log syntax on the script output.
      @tail_log_path -  By Default, all tail log backup will try to save the file on 'C:\Temp\' location. However you can specify by using @tail_log_path = 'any location of your choice'
      Example:
        restoration 'testdb', @tail_log = 1, @tail_log_path ='x:\backups\testdb\'
        
      
read Blog - https://shamvilkazmi.wordpress.com/2020/08/15/sql-backup-restore-made-easier/
