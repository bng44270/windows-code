function Format-Int($Value) {
  [string]$num = $Value
  $ar = $num.toCharArray()
  [array]::Reverse($ar)
  $newAr = [regex]::Replace(-join($ar),"([0-9]{3})","`$1,").toCharArray()
  [array]::Reverse($newAr)
  return -join($newAr) -replace "^,",""
}

function Contains-OneOf($String,$LookupString) {
  $found = $False
  foreach ($char in $LookupString.toCharArray()) {
    if ($String.Contains($char)) {
      $found = $True
      break
    }
  }
  return $found
}

function Get-RandomPassword($Length) {		
  if ($Length -eq $null) {
    $Length = 8
  }
  $ALPHA="ABCDEFGHJKMNPQRSTWXYZ"
  $NUM="0123456789"
  $SPECIAL="`$%&*+=#@!?~"
  $chars=($ALPHA.toLower() + $NUM + $SPECIAL + $ALPHA)
  $randpass=""
  
  while ($True) {	
    $counter=0
    
    $rand = New-Object System.Random
    while ($counter -lt $Length) {
      $randpass += $chars[$rand.next(0,48)]
      $counter++
    }
    
    if ((Contains-OneOf -String $randpass -LookupString $ALPHA) -and 
      (Contains-OneOf -String $randpass -LookupString $ALPHA.toLower()) -and
      (Contains-OneOf -String $randpass -LookupString $SPECIAL) -and
      (Contains-OneOf -String $randpass -LookupString $NUM)) {
      break
    }
    else {
      $randpass = ""
    }
  }
  return $randpass
}

function Get-ADUserAccountControl($Identity) {
  $uac_str_ar = @()
  
  $uac = @(@{"index"=0;"name"="SCRIPT"},@{"index"=1;"name"="ACCOUNTDISABLE"},@{"index"=3;"name"="HOMEDIR_REQUIRED"},@{"index"=4;"name"="LOCKOUT"},@{"index"=5;"name"="PASSWD_NOTREQD"},@{"index"=6;"name"="PASSWD_CANT_CHANGE"},@{"index"=7;"name"="ENCRYPTED_TEXT_PWD_ALLOWED"},@{"index"=8;"name"="TEMP_DUPLICATE_ACCOUNT"},@{"index"=9;"name"="NORMAL_ACCOUNT"},@{"index"=11;"name"="INTERDOMAIN_TRUST_ACCOUNT"},@{"index"=12;"name"="WORKSTATION_TRUST_ACCOUNT"},@{"index"=13;"name"="SERVER_TRUST_ACCOUNT"},@{"index"=16;"name"="DONT_EXPIRE_PASSWORD"},@{"index"=17;"name"="MNS_LOGON_ACCOUNT"},@{"index"=18;"name"="SMARTCARD_REQUIRED"},@{"index"=19;"name"="TRUSTED_FOR_DELEGATION"},@{"index"=20;"name"="NOT_DELEGATED"},@{"index"=21;"name"="USE_DES_KEY_ONLY"},@{"index"=22;"name"="DONT_REQ_PREAUTH"},@{"index"=23;"name"="PASSWORD_EXPIRED"},@{"index"=24;"name"="TRUSTED_TO_AUTH_FOR_DELEGATION"},@{"index"=26;"name"="PARTIAL_SECRETS_ACCOUNT"})
  $uac_ar = ([convert]::ToString((Get-ADUser -Identity $Identity -Properties useraccountcontrol).useraccountcontrol,2).toCharArray())
  [array]::Reverse($uac_ar)
  
  for ($i = 0; $i -lt $uac_ar.length; $i++) {
    if ($uac_ar[$i] -eq '1') {
      $uac_str_ar += [pscustomobject]@{'UacFlag'=($uac | Where-Object { $_.index -eq $i }).name}
    }
  }
  
  return $uac_str_ar
}

function Get-ADComputerInSubnet($SearchBase,$Subnets) {
  $returnAr = @()
	
	Get-ADComputer -SearchBase $SearchBase -Filter *  | ForEach-Object {
		$CompName = (Get-CimInstance -ComputerName $_.Name -Namespace root\CIMv2 -ClassName Win32_IP4RouteTable | Where-Object { $Subnets.Contains($_.Destination) }).PSComputerName
		$returnAr += [PSCustomObject]@{
			ComputerName = $CompName
		}
	}
	
	return $returnAr
}

function Get-DiskUtilization($DriveLetter) {
	if (-not $DriveLetter) {
		Get-WmiObject Win32_LogicalDisk | ForEach-Object {
			[pscustomobject]@{
				DriveLetter = $_.DeviceID
				FreeSpace = $_.FreeSpace
				UsedSpace = ($_.Size - $_.FreeSpace)
				TotalSpace = $_.Size
				PercentFree = (($_.FreeSpace/$_.Size)*100)
				PercentUsed = ((($_.Size - $_.FreeSpace)/$_.Size)*100)
			}
		}
	}
	else {
		Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq ($DriveLetter + ":") } |ForEach-Object {
			[pscustomobject]@{
				DriveLetter = $_.DeviceID
				FreeSpace = $_.FreeSpace
				UsedSpace = ($_.Size - $_.FreeSpace)
				TotalSpace = $_.Size
				PercentFree = (($_.FreeSpace/$_.Size)*100)
				PercentUsed = ((($_.Size - $_.FreeSpace)/$_.Size)*100)
			}
		}
	}
}
