##################################
#
# Create JsonFS File from Directory in PowerShell
#
# Usage:
#
#     New-JsonFSFile -Path <directory-path> -File <target-JSON-file> [-Unicode $True]
#
#     If the -Unicode option is omitted text files will be encoded ASCII values
#
# NOTE:  This script will only create JSON for directory structures 99 folders deep
#
# To interact with JSON filesystem use JsonFS (https://gist.github.com/bng44270/183eed06ec1bda30535278e36e1295cb)
#
##################################

function Get-FormattedDate($Date) {
    $Month = $Date.Month
    $Day = $Date.Day
    $Year = $Date.Year
    $Hour = $Date.Hour
    $Minute = $Date.Minute
    $Second = $Date.Second

    return "$Month/$Day/$Year $Hour`:$Minute`:$Second"
}

function Parse-Directory($Path,$Unicode) {
    $DirectoryObject = @{}

    $UseFolder = (Get-Item $Path)

    if ($UseFolder.PSIsContainer) {
        Get-ChildItem $Path | Foreach-Object {
            if ($_.PSIsContainer) {
                if ($Unicode) {
                    $DirectoryObject[$_.PSChildName] = (Parse-Directory -Path $_.PSPath -Unicode $True)
                }
                else {
                    $DirectoryObject[$_.PSChildName] = (Parse-Directory -Path $_.PSPath)
                }
            }
            else {
                $FileObject = @{}
                
                $FileContent = (Get-Content $_.PSPath)

                if ($Unicode) {
                    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($FileContent)
                }
                else {
                    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($FileContent)
                }

                $EncodedText =[Convert]::ToBase64String($Bytes)

                $FileObject['content'] = $EncodedText
                $FileObject['modified'] = (Get-FormattedDate -Date $_.LastWriteTime)
                $FileObject['size'] = if ($Unicode) { $_.Length } else { ($FileContent | Measure-Object -Character).Characters }

                $DirectoryObject[$_.PSChildName] = (New-Object pscustomobject -Property $FileObject)
            }
        }
    }

    return (New-Object pscustomobject -Property $DirectoryObject)
}

function New-JsonFSFile($Path,$File,$Unicode) {
    $JsonObj = @{}

    $JsonObj['type'] = 'jsonfs'

    if ($Unicode) {
        $JsonObj['fs'] = (Parse-Directory -Path $Path -Unicode $True)
    }
    else {
        $JsonObj['fs'] = (Parse-Directory -Path $Path)
    }

    $JsonText = ((New-Object pscustomobject -Property $JsonObj) | ConvertTo-Json -Depth 100)


    if ($File) {
        $JsonText | Out-File -FilePath $File
    }
    else {
        $JsonText
    }
}
