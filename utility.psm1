##########################
#
# Utility Classes
#
# Importing module
#
#  Import-Module \path\to\utility.psm1
#
#  $util = Get-UtilityClasses
#
# SecurePassword usage:
#
#   Setting with a clear-text in a variable
#
#        $p = $util.SecurePassword::SetPasswordFromText($passvar)
#
#   Setting with a SecureString in a variable
#
#        $p = $util.SecurePassword::SetPassword($secpass)
#
#   Generating a random password by supplying a length (if length is omitted, default length is 32)
#
#        $p = $util.SecurePassword::NewRandomPassword($passlength)
#
#   Returning the SecureString value of the password
#
#        $p.Password
#
#   Returning a clear-text instance of the password
#
#        $p.Get()
#
# Range usage:
#
#   Create a range beginning at 0 and continuing for 20 numbers
#
#        $r = $util.Range::new(20)
#
#   Create a range beginning at 1 and continuing for 20 numbers
#
#        $r = $util.Range::new(1,20)
#
#   Create a range beginning at zero and continuing every 3 numbers for 11 numbers (0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30)
#
#        $r = $util.Range::new(0,3,11)
#
#        # NOTE:  This returns all multiples of 3 where Index * 3 = Range Value
#
#
# SimpleMath usage:
#
#   Creating a list of numbers (used for Sum and Average methods):
#
#        $numlist = [System.Collections.ArrayList] @(1,2,3,4,5)
#
#   Calculating a sum:
#
#        $s = $util.SimpleMath::Sum($numlist)
#
#   Calculating an average
#
#        $a = $util.SimpleMath::Average($numlist)
#
##########################

class SecurePassword {
  [securestring] $Password
  [int32] $RandomLength
  [pscustomobject] $RandomChars = @{
    alpha   = "ABCDEFGHJKMNPQRSTWXYZ"
    nums    = "0123456789"
    special = "`$%&*+=#@!?~"
  }

  SecurePassword() {  }

  static [SecurePassword] SetPassword([SecureString]$p) {
    $n = [SecurePassword]::new()
    $n.Password = $p
    return $n
  }

  static [SecurePassword] SetPasswordFromText([string]$p) {
    $n = [SecurePassword]::new($p)
    $n.Password = ($p | ConvertTo-SecureString -AsPlainText -Force)
    return $n
  }

  static [SecurePassword] NewRandomPassword([Int32]$r) {
    $n = [SecurePassword]::new()
    $n.RandomLength = $r
    $n.GenerateRandom()
    return $n
  }

  static [SecurePassword] NewRandomPassword() {
    $n = [SecurePassword]::new()
    $n.RandomLength = 32
    $n.GenerateRandom()
    return $n
  }

  [string] Get() {
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($this.Password)
    $returnValue = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

    return $returnValue
  }

  [string] GetRandomCharString() {
    return ($this.RandomChars.alpha + $this.RandomChars.nums + $this.RandomChars.special + $this.RandomChars.alpha.ToLower())
  }

  [bool] ValidateRandom($p) {
    $hasAlphaLow = $false
    $hasAlphaUpper = $false
    $hasNumber = $false
    $hasSpecial = $false

    $passAr = ($p -split "") 
    $alphaLowAr = ($this.RandomChars.alpha.ToLower() -split "")
    $alphaUpperAr = ($this.RandomChars.alpha -split "")
    $numberAr = ($this.RandomChars.nums -split "")
    $specialAr = ($this.RandomChars.special -split "")

    for ($i = 0; $i -lt $passAr.Length; $i++) {
      if ((-not $hasAlphaLow) -and ($passAr[$i] -in $alphaUpperAr)) {
        $hasAlphaLow = $true
      }

      if ((-not $hasAlphaUpper) -and ($passAr[$i] -in $alphaLowAr)) {
        $hasAlphaUpper = $true
      }

      if ((-not $hasNumber) -and ($passAr[$i] -in $numberAr)) {
        $hasNumber = $true
      }

      if ((-not $hasSpecial) -and ($passAr[$i] -in $specialAr)) {
        $hasSpecial = $true
      }
    }

    return ($hasAlphaLow -and $hasAlphaUpper -and $hasNumber -and $hasSpecial)
  }

  [void] GenerateRandom() {
    $useChars = $this.GetRandomCharString()
    $randpass = ""
  
    while ($true) {	
      $counter = 0
    
      $rand = [System.Random]::new()
      while ($counter -lt $this.RandomLength) {
        $randpass += $useChars[$rand.next(0, ($useChars.Length - 1))]
        $counter++
      }

      if ($this.ValidateRandom($randpass)) {
        break
      }
      else {
        $randpass = ""
      }
    }
    
    $this.Password = ($randpass | ConvertTo-SecureString -AsPlainText -Force)
  }
}

class Range : System.Collections.ArrayList {
  Range($Count) : base() {
    $this.build(0, 1, $Count)
  }

  Range($Start, $Count) : base() {
    $this.build($Start, 1, $Count)
  }

  Range($Start, $Step, $Count) : base() {
    $this.build($Start, $Step, $Count)
  }

  hidden [void] build($Start, $Step, $Count) {
    for ($i = 0; $i -lt $Count; $i++) {
      $this.Add($Start)
      $Start += $Step
    }
  }
}

class SimpleMath {
  static [double] Sum([System.Collections.ArrayList]$Numbers) {
    [double] $tot = 0
    $Numbers | ForEach-Object {
      $tot += ([double]$_)
    }
    return $tot
  }

  static [double] Average([System.Collections.ArrayList]$Numbers) {
    $tot = [SimpleMath]::Sum($Numbers)
    return ($tot / ($Numbers.Count))
  }
}

function Format-Int($Value) {
  [string]$num = $Value
  $ar = $num.toCharArray()
  [array]::Reverse($ar)
  $newAr = [regex]::Replace( -join ($ar), "([0-9]{3})", "`$1,").toCharArray()
  [array]::Reverse($newAr)
  return -join ($newAr) -replace "^,", ""
}

enum PerfUnits {
  Milliseconds = 0
  Seconds = 1
  Minutes = 2
  Hours = 3
  Ticks = 4
}

function Measure-Performance([PerfUnits]$Unit, $Code={}, $Attempts = 1, $Verbose) {
  $UnitMap = @("TotalMilliseconds", "TotalSeconds", "TotalMinutes", "TotalHours", "Ticks")

  $useunit = $UnitMap[$Unit]

  $samples = [System.Collections.ArrayList]::new()

  for ($i = 1 ; $i -le $Attempts; $i++) {
    $startsec = (Get-Date).TimeOfDay."$useunit"
    & $Code
    $endsec = (Get-Date).TimeOfDay."$useunit"

    $elapse = ([double]($endsec - $startsec))
    
    [void] $samples.Add($elapse)
  }

  $average = [System.Math]::Round([SimpleMath]::Average($samples), 3)

  if ($Verbose) {
    Write-Output ("Average Time:  " + $average.ToString() + " " + ($UnitMap[$Unit] -replace '^Total', '') + (($Attempts -eq 1) ? "" : (" over " + $Attempts + " attempt(s)")))
  }
  else {
    Write-Output $average.ToString()
  }
}

function Get-Xml($File) {
    [xml]([string](Get-Content $File))
}

function Get-UtilityClasses() {
  return [pscustomobject]@{
    "SecurePassword" = [SecurePassword]
    "Range"          = [Range]
    "SimpleMath"     = [SimpleMath]
  }
}
