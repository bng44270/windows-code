#############################################
#
# Create WinForms app windows
#
# Supported controls:
#
#    Button
#    Text Box
#    Label
#
# Usage:
#
#    1. Loading Module
#
#        Import-Module \path\to\appwindow.psm1
#
#        $inc = Get-AppWindowClasses
#
#    2. Creating a window (WIDTH and HEIGHT are integers)
#
#        $winsize = [System.Drawing.Size]::new(WIDTH,HEIGHT)
#
#        $win = $inc.AppWindow::new($winSize)
#
#        # Optionally you can specify a ScriptBlock to execute on form load
#
#        $win = $inc.AppWindow::new($winSize,{
#            # this code can interact with form elements
#            # and execute other PowerShell commands
#        })
#
#    3. Add a Label control to the window
#
#        $lblSize = [System.Drawing.Size]::new(WIDTH, HEIGHT)
#        $lblLocation = [System.Drawing.Point]::(X,Y)
#        $lblName = "lblField1"
#        $lblText = "Phone Number"
#        $win.AddLabel($lblName,$lblLocation,$lblSize,$lblText)
#
#    4. Add a Text Box control to the window
#
#        $txtSize = [System.Drawing.Size]::new(WIDTH, HEIGHT)
#        $txtLocation = [System.Drawing.Point]::(X,Y)
#        $txtName = "txtField1"
#        $win.AddTextBox($txtName,$txtLocation,$txtSize)
#
#    5. Add a Button control to the window
#
#        $btnSize = [System.Drawing.Size]::new(WIDTH, HEIGHT)
#        $btnLocation = [System.Drawing.Point]::(X,Y)
#        $btnName = "btnSubmit"
#        $btnText = "Go!"
#        $btnClick = {
#            # this code can interact with form elements
#            # and execute other PowerShell commands           
#        }
#        $win.AddButton($btnName,$btnLocation,$btnSize,$btnText,$btnClick)
#
#    6. Show Window
#
#        $win.Open()
#
#############################################

class AppWindow : System.Windows.Forms.Form {
    [System.Collections.Hashtable] $Elements

    AppWindow([System.Drawing.Size] $s) : base() {
        $this.Elements = [System.Collections.Hashtable]::new()
        $this.Size = $s
    }

    AppWindow([System.Drawing.Size] $s, [scriptblock] $c) : base() {
        $this.Elements = [System.Collections.Hashtable]::new()
        $this.Size = $s
        
        $this.Add_Load($c)
    }

    [void] AddLabel([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s, [string] $t) {
        $d = [System.Windows.Forms.Label]::new()
        $d.Location = $l
        $d.Size = $s
        $d.Text = $t

        $this.Elements[$n] = $d
        $this.Controls.Add($d)
    }

    [void] AddTextBox([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s) {
        $b = [System.Windows.Forms.TextBox]::new()
        $b.Location = $l
        $b.Size = $s

        $this.Elements[$n] = $b
        $this.Controls.Add($b)
    }

    [void] AddButton([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s, [string] $t, [scriptblock] $c) {
        $b = [System.Windows.Forms.Button]::new()
        $b.Location = $l
        $b.Size = $s
        $b.Text = $t
        $b.Add_Click($c)
        
        $this.Elements[$n] = $b
        $this.Controls.Add($b)
    }

    [void] Open() {
        $this.Topmost = $true
        $this.ShowDialog() | Out-Null
    }

    [void] Close() {
        $this.Dispose()
    }

    static [AppWindow] FromJson([string] $p) {
        $json = (Get-Content $p | ConvertFrom-Json)

        $winvar = $json.var
        $formSize = [System.Drawing.Size]::new($json.size.width,$json.size.height)
        
        $w = [AppWindow]::new($formSize)

        $hasFormLoad = (($json | Get-Member -MemberType NoteProperty -Name "load") -and ($json.load.GetType().Name -eq "String"))

        if ($hasFormLoad) {
            $w.Add_Load([scriptblock]::Create($json.load))
        }

        $json.elements | ForEach-Object {
            $thisElem = $_

            if ($thisElem.type -eq "label") {
                $name = $thisElem.name
                $size =[System.Drawing.Size]::new($thisElem.size.width,$thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x,$thisElem.loc.y)
                $labeltext = $thisElem.text

                $w.AddLabel($name,$loc,$size,$labeltext)
            }
            elseif ($thisElem.type -eq "textbox") {
                $name = $thisElem.name
                $size =[System.Drawing.Size]::new($thisElem.size.width,$thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x,$thisElem.loc.y)
                $w.AddTextBox($name,$loc,$size)
            }
            elseif ($thisElem.type -eq "button") {
                $name = $thisElem.name
                $size =[System.Drawing.Size]::new($thisElem.size.width,$thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x,$thisElem.loc.y)
                $label = $thisElem.text
                $onclick = ([scriptblock]::Create($thisElem.click.toString()))

                $w.AddButton($name,$loc,$size,$label,$onclick)
            }
        }

        Write-Host "Notice:  if variable containing this AppWindow instance is not `$$winvar, functionality may be limited" -ForegroundColor Red -BackgroundColor Cyan
        return $w
    }
}

function Get-AppWindowClasses() {
    return [PSCustomObject]@{
        AppWindow = [AppWindow]
    }
}
