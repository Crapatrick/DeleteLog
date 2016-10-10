# Script: DeleteLog.ps1
# Version: 0.1
# Description: Deletes configured files (mainly logfiles)
# Author: Patrick Domnick

# Name: Main
# Description: Will be called at the beginning of the Script 
# Parameters: None
# Return: None
Function Main
{
    #Load Config
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value #Location of executed Script
    $currentDir = Split-Path $Invocation.MyCommand.Path #Where am I?
	[xml]$configFile = Get-Content "$currentDir\Config.xml" #Load File as XML

	#Get global config parameters
	$outputLog = $configFile.Settings.Global.OutputLog #Write to Folder
	$fileAge = $configFile.Settings.Global.FileAge #Standard maximum file age to delete
	$fileExtention = $configFile.Settings.Global.FileExtention #Standard file extention to delete

	#Echo config
	$outputLogFile = $outputLog + $(Get-Date -Format yyyyMMdd_HHmmss) + ".log" #Set file for logging
	CreateOutput ("Output Folder: " + $outputLog) $outputLogFile "Gray"
	CreateOutput ("Maxmium File Age: " + $fileAge) $outputLogFile "Gray"
	CreateOutput ("Standard File Extention: " + $fileExtention) $outputLogFile "Gray"

    #Prepare logfile removal and compression
    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    $now = Get-Date

    #Check Logs
    foreach ($directory in $configFile.Settings.LogFileDirectories.Directory)
    {#Iterate over all direcotries
        if (Test-Path $directory.Path)
        {#Check if path exists
            CreateOutput ("Cheking path: " + $directory.Path) $outputLogFile "Gray"
            $nowFileAge = If ($directory.FileAge) {$directory.FileAge} Else {$fileAge}
            $nowDelta = $now.AddDays(-$nowFileAge)
            $nowFileExtention = If ($directory.FileExtention) {$directory.FileExtention} Else {$fileExtention}
            $files = Get-ChildItem $directory.Path -include $nowFileExtention -recurse -ErrorAction SilentlyContinue | Where {$_.LastWriteTime -le “$nowDelta”}
            foreach ($file in $files)
            {#Delete each item
                CreateOutput (“Deleting file: " + $file) $outputLogFile "Yellow”
                #Remove-Item $File -ErrorAction SilentlyContinue | out-null
            }
        }
        else
        {#Wrong Path or Path unreachable
            CreateOutput ("Path: " + $directory.Path + " not found") $outputLogFile "Red" 
        }
    }
}

# Name: CreateOutput
# Description: Write String to CommandLine and to file
# Parameters: String Message, String FilePath, String Color 
# Return: None
Function CreateOutput ($message, $filePath, $color)
{
	#Write to Console
	Write-Host $message -ForegroundColor $color
	#Write to File
	Add-Content $filePath "$(Get-Date -f yyyy.MM.dd_HH:mm:ss) $message"
}

### Start Script
Main