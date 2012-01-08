; Script qui lit le contenu de C:windowswpkg-msg.txt et qui affiche la derni�re ligne de ce fichier.
; ce script s'arr�te quand une ligne "FIN WPKG" est lue

; force l'affichage de l'icone autoit � c�t� de l'horloge.
AutoItSetOption("TrayIconHide", 0)


$file=EnvGet("windir")&"\wpkg-msg.txt"

; on conserve la derni�re ligne affich�e pour ne pas ouvrir de nouveau un tooltip qui aurait �t� ferm� par l'user.
$oldline=""

While 1
	If FileExists($file) Then
		;MsgBox(4096,"", $file & " existe.")
		$read = FileOpen($file, 0)

		; V�rifie si l'ouverture du fichier en OK pour la lecture
		If $read = -1 Then
			MsgBox(0, "Error", "Fichier " & $file & " inacessible en lecture. Cela ne doit normalement jamais se produire.")
			Exit
		EndIf

		; lit la derni�re ligne du fichier ouvert $file
		$line = FileReadLine($read,-1)
		;MsgBox(4096,"", "Derni�re ligne lue : " & $line)

		If $line == "FIN WPKG" Then
			; on affiche un message de fin d'install wpkg et on quitte proprement en fermant l'acc�s au fichier
			TrayTip("Information : ", "L'installation, la mise � jour et la d�sinstallation des applications en arri�re plan est termin�e.", 10, 1 + 16)
			FileClose($read)
			Sleep(5000)
			Exit(0)
		Else
			; si la derni�re ligne lue il y a 3 secondes est la m�me que celle lue � l'instant, on n'affiche rien.
			If $line <> $oldline Or $line == "" Then
				; affiche la derni�re ligne de $file � c�t� de l'horloge en supprimant le son (+16)
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