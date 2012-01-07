; Script qui écrit la ligne passée en dernier argument à la fin de C:\windows\wpkg-msg.txt

$file=EnvGet("windir")&"\wpkg-msg.txt"

; si l'argument passé est vide, quitte silencieusement
If $CmdLine[$CmdLine[0]] == "" Then
	Exit
EndIf

;écrit le dernier argument fourni à la fin du fichier $file (et le crée si absent)
FileWriteLine( $file , $CmdLine[$CmdLine[0]] )
