; Script qui �crit la ligne pass�e en dernier argument � la fin de C:\windows\wpkg-msg.txt

$file=EnvGet("windir")&"\wpkg-msg.txt"

; si l'argument pass� est vide, quitte silencieusement
If $CmdLine[$CmdLine[0]] == "" Then
	Exit
EndIf

;�crit le dernier argument fourni � la fin du fichier $file (et le cr�e si absent)
FileWriteLine( $file , $CmdLine[$CmdLine[0]] )
