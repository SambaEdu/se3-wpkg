; Script qui lit le contenu de C:windowswpkg-msg.txt et qui affiche la dernière ligne de ce fichier.
; ce script s'arrête quand une ligne "FIN WPKG" est lue

; force l'affichage de l'icone autoit à côté de l'horloge.
AutoItSetOption("TrayIconHide", 0)


$file=EnvGet("windir")&"\wpkg-msg.txt"

; on conserve la dernière ligne affichée pour ne pas ouvrir de nouveau un tooltip qui aurait été fermé par l'user.
$oldline=""

While 1
	If FileExists($file) Then
		;MsgBox(4096,"", $file & " existe.")
		$read = FileOpen($file, 0)

		; Vérifie si l'ouverture du fichier en OK pour la lecture
		If $read = -1 Then
			MsgBox(0, "Error", "Fichier " & $file & " inacessible en lecture. Cela ne doit normalement jamais se produire.")
			Exit
		EndIf

		; lit la dernière ligne du fichier ouvert $file
		$line = FileReadLine($read,-1)
		;MsgBox(4096,"", "Dernière ligne lue : " & $line)

		If $line == "FIN WPKG" Then
			; on affiche un message de fin d'install wpkg et on quitte proprement en fermant l'accès au fichier
			TrayTip("Information : ", "L'installation, la mise à jour et la désinstallation des applications en arrière plan est terminée.", 10, 1 + 16)
			FileClose($read)
			Sleep(5000)
			Exit(0)
		Else
			; si la dernière ligne lue il y a 3 secondes est la même que celle lue à l'instant, on n'affiche rien.
			If $line <> $oldline Or $line == "" Then
				; affiche la dernière ligne de $file à côté de l'horloge en supprimant le son (+16)
				TrayTip("Information : ", $line, Default, 0 + 16)
			EndIf
		EndIf
		$oldline = $line
		FileClose($read)
	;Else
	;	MsgBox(4096,"", $file & " n'existe pas.")
	;	Exit
	EndIf
	; actualisation de l'affichage toutes les secondes
	; ne pas mettre plus sans modifier wpkg-client.vbs qui fait une pause de 2 secondes dans la fonction TooltipEnd
	Sleep(1000)
WEnd