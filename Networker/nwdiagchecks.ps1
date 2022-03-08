#Networker Client Diagnostics Script
#By Jared Leslie 
#Credit to Kevin Liew
#Date 07/03/2022


#Array Variables
$nwnames = @(
    "networker1.example.com"
    "networker2.example.com"
	)
$ddnames = @(
    "datadomain1.example.com"
    "datadomain2.example.com"
    "datadomain3.example.com"
	)

#Software Detection Variables
$software2 = "NetWorker Client"
$installed2 = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software2 }) -ne $null
$software = "Networker Extended Client"
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null
$location = Get-ItemProperty HKLM:SOFTWARE\Legato\Networker\ | % {$_.Path} -ErrorAction SilentlyContinue;
$pathFix1 = Join-Path $location logs\daemon.raw


#Service Variables
$ServiceName = 'nsrexecd'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue;


#Port Variables
$nwport = 7937
$ddport1 = 111
$ddport2 = 2049
$ddport3 = 2052

#Networker Service Checks
if (-Not $installed2) {
	Write-Host "'$software2' is not installed." -fore red
}
else {
	Write-Host "'$software2' is installed." -fore green
	Write-Host $msg
		if ($arrService.Status -ne 'Running') {
			Start-Service $ServiceName
			write-host $arrService.status
			write-host 'Service starting...'
			Start-Sleep -seconds 60
		}
		else {
			Write-Host "'$software2' Service is Running." -fore green
		}
	#Networker Version Check
	Write-Host $msg
	Write-Host "Networker Client Version." -fore green
	Get-ItemProperty HKLM:SOFTWARE\Legato\Networker\ | % {$_.Release}
	Write-Host $msg
	#Networker Port Check
	Write-Host "Networker Client Ports." -fore green
	nsrports
	Write-Host $msg
	#Networker Daemon Log Check
	Write-Host "Daemon Log Render (20 Lines)." -fore green
	nsr_render_log "$pathFix1" | Select-Object -Last 20
	Write-Host $msg
	#Networker Server File Check
	Write-Host "Networker Servers File" -fore green
	Get-Content "$location\res\servers" | Select-String -pattern "#" -notmatch
	Write-Host $msg
	#VSS Writer Check and Display Failed Writers
	Write-Host "Checking for failed VSS Writers..."
	& vssadmin list writers | Select-String -Context 0,4 '^writer name:' | ? {
		$_.Context.PostContext[2].Trim() -ne "state: [1] stable" -or
		$_.Context.PostContext[3].Trim() -ne "last error: no error"
	  }
	Write-Host $msg
}

#Networker Check Connectivity 
foreach ($nwname in $nwnames)
    {
		Write-Host "Testing connectivity for $nwname"
		$error.clear()
		try
		{
			$tmp = Resolve-DnsName $nwname -ErrorAction Stop | Select-Object IPAddress -ExpandProperty IPAddress
		} catch { Write-Host $nwname does not resolve on DNS. }
		if (!$error){Write-Host $nwname resolves to $tmp -fore green}
		

        $t = New-Object System.Net.Sockets.TcpClient
		
		try
		{
			$t.Connect("$nwname","$nwport")
		} catch {}
		
		if($t.Connected)
		{
			$t.Close()
			Write-Host "Port $nwport is operational for $nwname" -fore green
			if(-Not $installed) {
				Write-Host "'$software' is not installed." -fore red
				}
			else{
				Write-Host "nsrrpcinfo -p $nwname"  -fore green
				nsrrpcinfo -p $nwname
			}
		}
		else
		{
			Write-Host "Port $nwport is not working for $nwname" -fore red
		}
		Write-Host $msg
    }

#Data Domain Check Connectivity
foreach ($ddname in $ddnames)
    {
		Write-Host "Testing connectivity for $ddname"
		$error.clear()
		try
		{
			$tmp = Resolve-DnsName $ddname -ErrorAction Stop | Select-Object IPAddress -ExpandProperty IPAddress
		} catch { Write-Host $ddname does not resolve on DNS. }
		if (!$error){Write-Host $ddname resolves to $tmp -fore green}
		


        $t = New-Object System.Net.Sockets.TcpClient
		
		try
		{
			$t.Connect("$ddname","$ddport1")
		} catch {}
		
		if($t.Connected)
		{
			$t.Close()
			Write-Host "Port $ddport1 is operational for $ddname" -fore green
		}
		else
		{
			Write-Host "Port $ddport1 is not working for $ddname" -fore red
		}

		
		$t = New-Object System.Net.Sockets.TcpClient
		try
		{
			$t.Connect("$ddname","$ddport2")			
		} catch {}
		
		if($t.Connected)
			{
				$t.Close()
				Write-Host "Port $ddport2 is operational for $ddname" -fore green
			}
			else
			{
				Write-Host "Port $ddport2 is not working for $ddname" -fore red
			}
			
		$t = New-Object System.Net.Sockets.TcpClient
		try
			{
				$t.Connect("$ddname","$ddport3")			
			} catch {}
		
		if($t.Connected)
			{
				$t.Close()
				Write-Host "Port $ddport3 is operational for $ddname" -fore green
			}
			else
			{
				Write-Host "Port $ddport3 is not working for $ddname" -fore red
			}			
		Write-Host $msg
    }

Read-Host -Prompt "Press Enter to exit"