#  Use 7zip to backup specific filetypes for some subfolders of all users and delete old backups.
#  version 0.3.10
#  Requeriments: 7zip
#
# Enrique Landestoy 
#  - e.landestoy@gmail.com

# Variables
 $source = "C:\Users" 
 $subfolders = "Desktop","Documents"
 $destination = "C:\Backup" 
 $7z = "C:\Program Files\7-Zip\7z.exe"
 $deldays = "31"
 $date = Get-Date -Format d.MMMM.yyyy 
 $hostname = $env:computername
 $7zfile = "$destination\Backup-$hostname-$date.7z"
 $ipaddress = $(ipconfig | where {$_ -match 'IPv4.+\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' } | out-null; $Matches[1])

# Backup Process
if (test-Path $destination) {} Else { mkdir $destination }
Get-ChildItem -Path $source | foreach-object {
   ForEach ($folder in $subfolders) {
       $currentfolder = ($_.Fullname+ "\" + $folder)
       cd $currentfolder
       Write-Output "Starting Bakup of $currentfolder on $hostname($ipaddress) on $date" >> "$destination\backup_log.txt"
       & $7z a -r $7zfile *.gif *.jpg *.xls* *.csv* *.doc* *.pdf* *.ppt* -ms -mmt >> "$destination\backup_log.txt"
       write-Output "Backup finish of $currentfolder on $hostname($ipaddress) on $date" >> "$destination\backup_log.txt"
       write-Output ""
   }
}

# Delete backups from 31 days olders
 Get-ChildItem "Backup-$hostname-*" -Path $destination | where-object {$_.LastWriteTime -lt (get-date).AddDays(-$deldays)} | Remove-Item
