; Script qui �crit la ligne pass�e en argument 1 � la fin de C:\windows\wpkg-msg.txt

$file=EnvGet("windir")&"\wpkg-msg.txt"

; si l'argument pass� est vide, quitte silencieusement
If $CmdLine[1] == "" Then
	Exit
EndIf

;�crit l'argument fourni � la fin du fichier $file (et le cr�e si absent)
FileWriteLine( $file , $CmdLine[1] )
