######################################
#
# datadef.ps1 - Use schema-enforced JSON object arrays created by datadef.js or datadef.py
#
# Usage:
#
#         # Load Schema from JSON file
#         $s = (Get-DataDefSchema -JsonFile ./test.json)
#
#         # OR
#
#         # Create schema manually (valid types are number, string, and boolean)
#         $s = (New-DataDefSchema)
#         $s.AddField("name","string")
#         $s.AddField("age","number")
#
#  MORE DOCS TO COME
#
######################################
function New-DataDefSchema() {
    $ob = [pscustomobject]@{
        "Schema" = [pscustomobject]@{}
        "Types" = [pscustomobject]@{
            "Double" = "number"
            "Int32" = "number"
            "Int64" = "number"
            "String" = "string"
            "Boolean" = "boolean"
        }
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "ValidateType" -Value {
        param($t)
        
        return ($t -in ($this.Types | Get-Member -MemberType NoteProperty | ForEach-Object {
            $t = $_.Name
            $this.Types.$t
        })   ? $True : $False)
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "AddField" -Value {
        param($f,$t)
        
        if (-not $this.ValidateType($t)) {
            throw "Invalid Type ($t)"
        }
        
        $this.Schema | Add-Member -MemberType NoteProperty -Name $f -Value $t
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "ValidateField" -Value {
        param($f,$v)
        
        $fieldExists = ($this.Schema | Get-Member -MemberType NoteProperty -Name $f)
        
        if (-not $fieldExists) {
            throw "Field not found ($f)"
        }
        
        $fieldType = $this.Schema.$f
        $dataType = $v.GetType().Name
        $testType = $this.Types.$dataType
        if ($fieldType -ne $testType) {
            throw "Invalid type for field $f (expected $fieldType but found $testType)"
        }
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "ToJson" -Value {
        $this.Schema | ConvertTo-Json
    }
    
    return $ob
}

function Get-DataDefSchema($JsonFile) {
    $schema = (New-DataDefSchema)
    
    $readOb = (Get-Content $JsonFile | ConvertFrom-Json)
    
    $readOb | Get-Member -MemberType NoteProperty | ForEach-Object {
        $f = $_.Name
        $t = $readOb.$f
        $schema.AddField($f,$t)
    }
    
    return $schema
}

function New-DataDefRow() {
    $ob = [pscustomobject]@{
        "Data" = [pscustomobject]@{}
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "SetValue" -Value {
        param($f,$v)
        
        $this.Data | Add-Member -MemberType NoteProperty -Name $f -Value $v
    }
    
    return $ob
}

function New-DataDef($Schema) {
    $ob = [pscustomobject]@{
        "Schema" = $Schema
        "Data" = @()
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "ValidateRecord" -Value {
        param($r)
        
        $r.Data | Get-Member -MemberType NoteProperty | ForEach-Object {
            $f = $_.Name
            $v = $r.Data.$f
            
            $this.Schema.ValidateField($f,$v)
        }
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "Insert" -Value {
        param($r)
        
        $this.ValidateRecord($r)
        
        $this.Data += $r.Data
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "Equal" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | Where-Object { $_.$f -eq $v })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "Match" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | ForEach-Object {
            if ($_.$f -match $v) {
                $_
            }
        })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "GreaterThan" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | Where-Object { $_.$f -gt $v })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "GreaterThanOrEqual" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | Where-Object { $_.$f -ge $v })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "LessThan" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | Where-Object { $_.$f -lt $v })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "LessThanOrEqual" -Value {
        param($f,$v)
        
        $newData = (New-DataDef -Schema $this.Schema)
        $newData.Data = ($this.Data | Where-Object { $_.$f -le $v })
        
        return $newData
    }
    
    $ob | Add-Member -MemberType ScriptMethod -Name "ToJson" -Value {
        $this.Data | ConvertTo-Json
    }
    
    return $ob
}

function Get-DataDef($Schema, $JsonFile) {
    $ob = (New-DataDef -Schema $Schema)
    
    Get-Content $JsonFile | ConvertFrom-Json | ForEach-Object {
        $rowOb = $_
        
        $r = (New-DataDefRow)
        
        $rowOb | Get-Member -MemberType NoteProperty | ForEach-Object {
            $f = $_.Name
            $v = $rowOb.$f
            
            $r.SetValue($f,$v)
        }
        
        $ob.Insert($r)
    }
    
    return $ob
}
