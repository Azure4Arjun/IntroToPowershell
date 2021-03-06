﻿#Using SQL CMD
#sqlcmd - Just call within the script
sqlcmd -S TARKIN -d tempdb -Q "select count(1) from sys.objects"

$sql="
SET NOCOUNT ON
select sp.name,count(1) db_count
from sys.server_principals sp
join sys.databases d on (sp.sid = d.owner_sid)
group by sp.name
"
sqlcmd -S TARKIN -d tempdb -Q $sql

#Multi-instance execution
Clear-Host
$instances = @('TARKIN','VADER')
$instances | ForEach-Object {"Instance:$_";sqlcmd -S $_ -Q $sql;"`n"}

#Let's look at SQLPS/SQLServer
#Where does the module live?
Get-Module -ListAvailable *SQL*

#Lets look in that location and check out some of the files.
dir 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\21.0.17152'

powershell_ise 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\SqlServer.PS1'
powershell_ise 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\SqlServerPostScript.PS1'

#Cool, now load the module
Import-Module SqlServer

#If you're not using SSMS 2016, you'll probably see an error
Import-Module SqlServer -Verbose
Import-Module SqlServer -DisableNameChecking

#Providers and the SQL Provider
#--------------------------------------

Clear-Host

Get-PSDrive

Get-PSDrive C | Get-Member

Get-PSDrive ENV | Get-Member

cd ENV:\ #Same as 'Set-Location ENV:\'
dir 

dir HKLM:\SOFTWARE

#we can easily refer to provider elements in some cases
$env:COMPUTERNAME
$env:UserName
$env:PATH

#Change to the SQL Server Provider
CD SQLSERVER:\
dir

#We can browse our SQL Servers as if they were directories
Clear-Host
CD SQL\TARKIN\
dir

CD DEFAULT
dir

dir Databases
dir databases -Force
$dbout = dir databases -Force
$dbout | gm
$dbout | Where-Object {$_.Owner -ne 'sa'}

dir databases -Force| 
    select name,createdate,@{name='DataSizeMB';expression={$_.dataspaceusage/1024}} | Format-Table -AutoSize

#How does this show up in SQL Server?
#Let's go look at an XE session (Go into SSMS)

#let's work with logins
$dblogins = dir logins 
$dblogins
$dblogins | gm

dir logins -Force| Select-Object name,defaultdatabase


#set all default dbs for non-system logins to tempdb
foreach($dblogin in $dblogins){
    if($dblogin.issystemobject -eq $false){
        $dblogin.defaultdatabase = 'tempdb'
        $dblogin.Alter()
    }
}

dir logins -Force| Select-Object name,defaultdatabase

#We'll set them back now
foreach($dblogin in $dblogins){
    if($dblogin.issystemobject -eq $false){
        $dblogin.defaultdatabase = 'master'
        $dblogin.Alter()
    }
}

dir logins -Force| Select-Object name,defaultdatabase

#Some of the generic functions won't work
New-Item database\poshtest

#So we will need to use traditional methods
Invoke-Sqlcmd -ServerInstance TARKIN -Database tempdb -Query "CREATE DATABASE poshtest"
dir databases

#But other things do work
Remove-Item databases\poshtest
dir databases

#Let's look at the CMS
CD "SQLSERVER:\SQLRegistration\Central Management Server Group\TARKIN"
dir

#With the right approach, we can query across servers.
$servers= @((dir "SQLSERVER:\SQLRegistration\Central Management Server Group\TARKIN").Name)
$servers += 'TARKIN'

#Check your SQL Server versions
$servers | ForEach-Object {Get-Item “SQLSERVER:\SQL\$_\DEFAULT”} | Select-Object Name,VersionString,IsClustered,IsHADREnabled

#Report on all your databases
$servers | ForEach-Object {dir SQLSERVER:\SQL\$_\DEFAULT\DATABASES} | 
            Select-Object @{n='Server';e={$_.Parent.Name}},name,createdate,@{name='DataSizeMB';expression={$_.dataspaceusage/1024}},LastBackupDate | 
            Format-Table -AutoSize
