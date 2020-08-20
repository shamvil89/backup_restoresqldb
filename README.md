# sp_dbundo

Generic syntax <br>
msdb..sp_dbundo 'database_name' <-- this will build script to restore the database to how it was 15 minutes before <br><br>
to tell a specific time, use following <br>
msdb..sp_dbundo 'database_name' , @stopat = 'DateTime of your choice'<br><br>

view this blog for how to use - <br>
https://shamvilkazmi.wordpress.com/2020/08/20/sp_dbundo/



# backup_restoresqldb
This repository is a combination of two stored procedures that are designed for taking backup of Microsoft SQL databases (On-premise) and create a restore script respectively<br><br>

1. backupsqldb_proc file creates stored procedure called "db_backup"<br>
 <tab>   Mandatory Parameters:<br>
      @path - mention path where you want to store your backup files. (this have not yet been tested on network path or tape)<br>
      @db_name - the name of database that you want to take backup of.<br>
                 you can use this stored procedure with another stored procedure 'ms_foreachdb' to execute against all databases on server.<br>
                      Example:<br>
                        You can create three seperate jobs for each type of backups and use below script<br>
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 1 , @db_name =[?]'<br>
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 2 , @db_name =[?]'<br>
                            exec sp_msforeachdb 'exec db_backup @path=''c:\temp\'', @backuptype = 3 , @db_name =[?]'<br><br>
    Optional Parameters:<br>
      @backuptype - This parameter decides the type of backup. default is set to full backup<br>
          Values -<br>
           1 - Full backup<br>
           2 - Differential Backup<br>
           3 - Log Backup<br>
           4 - Copy Only backup<br>
      @copy_only - This parameter takes copy_only backup of a database (redundant feature)<br><br>
   
   
2. restoresqldb_proc file creates stored procedure called "restoration"<br>
    Mandatory Parameters:<br>
      @db_name - the name of database that you want to take restore<br><br>
                 
    Optional Parameters:<br>
      @script - By default, only script will be displayed. However, if you want to analyse LSN related information you can change the value to 0<br>
                Example:<br>
                          restoration 'testdb', @script = 0<br>
      @Copy_Only - If you want to get a restore script for copyonly backup, use parameter - @copy_only =1. By default the value is set to 0<br>
      @tail_log - If you want to take a tail log backup before restoring the database, enable parameter @tail_log = 1. This will add tail log syntax on the script output.<br>
      @tail_log_path -  By Default, all tail log backup will try to save the file on 'C:\Temp\' location. However you can specify by using @tail_log_path = 'any location of your choice'<br>
      Example:<br>
        restoration 'testdb', @tail_log = 1, @tail_log_path ='x:\backups\testdb\'<br><br><br>
        
      
read Blog - https://shamvilkazmi.wordpress.com/2020/08/15/sql-backup-restore-made-easier/
