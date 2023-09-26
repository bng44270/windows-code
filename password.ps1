###########################
# Generate Random Passwords in Powershell
#
# Usage:
#     1.  Load password.ps1 into memory (run ". password.ps1")
#
#         If this command returns a policy error, the contents of
#         password.ps1 may be copied and pasted into the Powershell
#         command line.
#
#     2.  Run Get-RandomPassword -Length <LENGTH>
#         <LENGTH> is the length of the password
###########################

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