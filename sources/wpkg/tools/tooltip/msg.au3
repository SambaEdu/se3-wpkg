; Script qui écrit la ligne passée en argument 1 à la fin de C:\windows\wpkg-msg.txt

$file=EnvGet("windir")&"\wpkg-msg.txt"

; si l'argument passé est vide, quitte silencieusement
If $CmdLine[1] == "" Then
	Exit
EndIf

;écrit l'argument fourni à la fin du fichier $file (et le crée si absent)
FileWriteLine( $file , $CmdLine[1] )
