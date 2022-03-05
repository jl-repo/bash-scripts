#Script to test connectivity to Networker and Data Domain
#By Jared Leslie 
#Credit to Kevin Liew
#Date 17/02/2022


#Array Variables
$nwnames = @(
	'networker1.example.com'
	'networker2.example.com'
	)
$ddnames = @(
	'datadomain1.example.com'
    'datadomain2.example.com'
	)

#Software Variables
$software = "Networker Extended Client"
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null

#Port Variables
$nwport = 7937
$ddport1 = 111
$ddport2 = 2049
$ddport3 = 2052

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
		}
		else
		{
			Write-Host "Port $nwport is not working for $nwname" -fore red
		}
		
		if(-Not $installed) {
			Write-Host "'$software' is not installed." -fore red
			}
		else{
		Write-Host "nsrrpcinfo -p $nwname"  -fore green
		nsrrpcinfo -p $nwname
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