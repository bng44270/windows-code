######################################
#
# datadef.psm1 - Use schema-enforced JSON object arrays created by datadef.js or datadef.py
#
# Importing module
#
#         Import-Module .\datadef.psm1
#
#         $dd = Get-DataDefClasses
#
#         # NOTE:  all forthcoming examples will use $dd for object instantiation
#
# Schema Usage:
#
#         # Load from JSON file
#         $s = $dd.DataDefSchema::FromFile("./schema.json")
#
#         # OR
#
#         # Load from JSON text in a variable
#         $s = $dd.DataDefSchema::FromJson($jsonText)
#
#         # OR
#
#         # Create schema manually (valid types are number, string, and boolean)
#         $s = $dd.DataDefSchema::new()
#         $s.AddField("name","string")
#         $s.AddField("age","number")
#
#
# Data Usage:
#
#         # Load Data from file
#         $d = $dd.DataDef::FromFile("./data.json")
#
#         # OR
#
#         # Load from JSON text in a variable
#         $d = $dd.DataDef::FromJson($jsonText)
#
#         # OR
#
#         # Create a DataDef manually while providing a schema object
#         $d = $dd.DataDef::new($s)
#         $row = $dd.DataDefRow::new()
#         $row['name'] = "bob"
#         $row['age'] = 43
#         $d.Insert($row)
#
#         # OR
#
#         # Create a DataDef and DataDefSchema manually
#         $d = $dd.DataDef::new()
#         $d.Schema.AddField("name","string")
#         $d.Schema.AddField("age","number")
#         $row = $dd.DataDefRow::new()
#         $row['name'] = "bob"
#         $row['age'] = 43
#         $d.Insert($row)
#
#
######################################

class DataDefSchema {
    [System.Collections.Hashtable] $Schema = [System.Collections.Hashtable]::new()
    [System.Collections.Hashtable] $Types = @{
        "Double"  = "number"
        "Int32"   = "number"
        "Int64"   = "number"
        "String"  = "string"
        "Boolean" = "boolean"
    }

    [bool] ValidateType($t) {
        return ($t -in $this.Types.Values)        
    }

    [bool] ValidateField($f,$v) {
        if (-not ($f -in $this.Schema.Keys)) {
            throw "Field not found in schema ($f)"
        }

        $dataType = $v.GetType().Name

        if (-not ($dataType -in $this.Types.Keys)) {
            throw "Data type not supported ($dataType)"
        }

        return ($this.Schema[$f] -eq $this.Types[$dataType])
    }
    
    [void] AddField($f,$t) {
        if (-not $this.ValidateType($t)) {
            throw "Invalid field type ($t)"
        }

        if ($f -in $this.Schema.Keys) {
            throw "Field already exists in schema ($f)"
        }

        $this.Schema[$f] = $t
    }

    [string] ToJson() {
        return ($this.Schema | ConvertTo-Json)
    }

    static [DataDefSchema] FromJson($j) {
        $ob = [DataDefSchema]::new()

        $s = $j | ConvertFrom-Json
        
        $s | Get-Member -MemberType NoteProperty | ForEach-Object {
            $field = $_.Name
            $type = $s."$field"

            $ob.AddField($field,$type)
        }

        return $ob
    }

    static [DataDefSchema] FromFile($p) {
        $jsonText = (Get-Content $p)

        return ([DataDefSchema]::FromJson($jsonText))
    }
}

class DataDefRow : System.Collections.Hashtable {
    DataDefRow() : base() { }
}

class DataDef {
    [DataDefSchema] $Schema
    [System.Collections.Generic.List[DataDefRow]] $Data

    DataDef() {
        $this.Schema = [DataDefSchema]::new()
        $this.Data = [System.Collections.Generic.List[DataDefRow]]::new()
    }

    DataDef([DataDefSchema]$s) {
        $this.Schema = $s
        $this.Data = [System.Collections.Generic.List[DataDefRow]]::new()
    }

    DataDef([DataDefSchema]$s,[System.Collections.Generic.List[DataDefRow]]$d) {
        $this.Schema = $s
        $this.Data = $d
    }

    [void] ValidateRow([DataDefRow]$r) {
        $r.Keys | ForEach-Object {
            $field = $_
            $value = $r."$field"
            
            $this.Schema.ValidateField($field,$value)
        }
    }

    [void] Insert([DataDefRow]$r) {
        $this.ValidateRow($r)

        $this.Data.Add($r)
    }

    [DataDef] Equal($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -eq $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [DataDef] Match($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -match $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [DataDef] GreaterThan($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -gt $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [DataDef] GreaterThanOrEqual($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -ge $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [DataDef] LessThan($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -lt $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [DataDef] LessThanOrEqual($f,$v) {
        $this.Schema.ValidateField($f,$v)

        $qdata = $this.Data | Where-Object { $_."$f" -le $v}
        
        return ([DataDef]::new($this.Schema,$qdata))
    }

    [string] ToJson() {
        return ($this.Data | ConvertTo-Json)
    }

    static [DataDef] FromJson([DataDefSchema]$s,$j) {
        $ob = [DataDef]::new($s)

        $rdata = (Get-Content $j | ConvertFrom-Json)

        $rdata | ForEach-Object {
            $row = $_
            $rowHash = [DataDefRow]::new()

            $s.Schema.Keys | ForEach-Object {
                $field = $_
                $value = $row."$field"

                $rowHash[$field] = $value
            }

            $ob.ValidateRow($rowHash)

            $ob.Add($rowHash)
        }

        return $ob
    }

    static [DataDef] FromFile($p) {
        $jsonText = (Get-Content $p)

        return ([DataDef]::FromJson($jsonText))
    }
}

function Get-DataDefClasses() {
    return [pscustomobject]@{
        "DataDefSchema"= [DataDefSchema]
        "DataDefRow" = [DataDefRow]
        "DataDef" = [DataDef]
    }
}
