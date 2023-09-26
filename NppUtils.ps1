# Usage:
#  1) Include this script
#  2) Run:
#          Npp-Workspace -SetPath <root-folder>  -WsFile <workspace-file>
#  3) Run from Notepad++ and save as command (will build/rebuild project)

function Npp-Directory($ProjectPath,$WsFile) {
	dir $ProjectPath | ForEach-Object {
		$childname = $_.FullName
		if ($_.PSIsContainer) {
			$dirname = $_.BaseName
			"<Folder name=`"$dirname`">" | Out-File -Encoding Ascii -append $WsFile
			Npp-Directory -ProjectPath $childname -WsFile "$WsFile"
			"</Folder>" | Out-File -Encoding Ascii -append $WsFile
		}
		else {
			"<File name=`"$childname`" />" | Out-File -Encoding Ascii -append $WsFile
		}
	}
}

function Npp-Projects($WsPath,$WsFile) {
	dir $WsPath | ForEach-Object {
		$childname = $_.BaseName
		"<Project name=`"$childname`">" | Out-File -Encoding Ascii -append $WsFile
		Npp-Directory -ProjectPath $_.FullName -WsFile "$WsFile"
		"</Project>" | Out-File -Encoding Ascii -append $WsFile
	}
}

function Npp-Workspace($SetPath,$WsFile) {
	if (Test-Path $WsFile) {
		Remove-Item $WsFile
	}
	"<NotepadPlus>" | Out-File -Encoding Ascii -append $WsFile
	Npp-Projects -WsPath $SetPath -WsFile "$WsFile"
	"</NotepadPlus>" | Out-File -Encoding Ascii -append $WsFile
}