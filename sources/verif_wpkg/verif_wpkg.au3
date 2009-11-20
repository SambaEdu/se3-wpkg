; Script lanceur
; Auteur: Stephane Boireau
;         Et pour la partie la plus technique sur les processus ADMINSE3:
;         Jean Le Bail
; Dernière modification: 11/04/2009

If @OSTYPE == "WIN32_WINDOWS" Then
	MsgBox(0,"Information","Ce programme concerne les OS NT/2K/XP uniquement.")
	Exit
Else
	;Include constants
	#include <GUIConstants.au3>

	;Initialize variables
	Global $GUIWidth
	Global $GUIHeight

	;$GUIWidth = 300
	$GUIWidth = 300
	$GUIHeight = 245
	;$GUIHeight = 700

	$NOM_FENETRE = "Choix de contrôle WPKG sur " & @ComputerName
	GUICreate($NOM_FENETRE, $GUIWidth, $GUIHeight)

	$x0=10
	$y0=10
	$y1=$y0+3
	$hauteur_txt=20
	$ecart=20
	$largeur_zone_checkbox=160
	;==================================

	Dim $strComputer, $ProcessUser
	Dim $objWMIService, $colProcessList, $objProcess, $colProperties
	Dim $strNameOfUser, $strUserDomain
	$list = ""
	
	$Champ_InfosPoste = GUICtrlCreateButton("Infos sur le poste", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGlog = GUICtrlCreateButton("Editer le " & @WindowsDir & "\wpkg.log", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGtxt = GUICtrlCreateButton("Editer le " & @WindowsDir & "\wpkg.txt", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGxml = GUICtrlCreateButton("Editer le " & @WindowsDir & "\system32\wpkg.xml", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGsupprxml = GUICtrlCreateButton("Supprimer le " & @WindowsDir & "\system32\wpkg.xml", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Label_WPKGsupprxml = GuiCtrlCreateLabel("(pour tester toutes les applis au prochain lancement wpkg)", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGprocess = GUICtrlCreateButton("Contrôler les processus ADMINSE3", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGreg = GUICtrlCreateButton("Contrôler la clé Running", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Champ_WPKGreg2 = GUICtrlCreateButton("Corriger la clé Running", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	; Passer la clé Running en False

	$Champ_WPKGsuppr = GUICtrlCreateButton("Supprimer le client WPKG", $x0, $y1, 280, 20)
	$y0 = $y0 + $ecart
	$y1=$y0+3
	$Label_WPKGsuppr = GuiCtrlCreateLabel("(pour en forcer la réinstallation au prochain login)", $x0, $y1, 280, 20)
	If IsAdmin() Then
		$bidon=""
	Else
		GUICtrlSetState($Champ_WPKGreg2,$GUI_DISABLE)
		GUICtrlSetState($Champ_WPKGsuppr,$GUI_DISABLE)
	EndIf

	; Ouvrir le Gestionnaire de tâches pour contrôler
	; Relancer via RUNAS...

	;==================================

	;	$y0 = $GUIHeight - 35
	;	$x=($GUIWidth-2*70-35)/2

	;	; Création du bouton "OK"
	;	$OK_Btn = GUICtrlCreateButton("OK", $x, $y0, 70, 25)


	;	$x=$x+70+35

	;	; Création du bouton "CANCEL"
	;	$Cancel_Btn = GUICtrlCreateButton("Cancel", $x, $y0, 70, 25)

	;==================================

		; On rend la fenêtre visible (modification de statut)
		GUISetState(@SW_SHOW)

		; On fait une boucle jusqu'à ce que:
		; - l'utilisateur presse ESC
		; - l'utilisateur presse ALT+F4
		; - l'utilisateur clique sur le bouton de fermeture de la fenêtre
		While 1
			; Après chaque boucle, on contrôle si l'utilisateur a cliqué sur quelque chose
			$msg = GUIGetMsg()

			Select
				; On teste si l'utilisateur a cliqué sur le bouton $Champ_WPKGlog
				; Infos sur le poste
				Case $msg = $Champ_InfosPoste
					;...
					$affichage="ComputerName:     " & @ComputerName
					$affichage&=@CRLF & "OSVersion:             " & @OSVersion
					$affichage&=@CRLF & "Domaine Windows: " & @LogonDomain
					$affichage&=@CRLF & "Domaine DNS:     " & @LogonDNSDomain
					$affichage&=@CRLF & "IP1:                        " & @IPAddress1 
					If @IPAddress2 <> "0.0.0.0" Then
						$affichage&=@CRLF & "IP2:                        " & @IPAddress2
					EndIf
					If @IPAddress3 <> "0.0.0.0" Then
						$affichage&=@CRLF & "IP3:                        " & @IPAddress3
					EndIf
					If @IPAddress4 <> "0.0.0.0" Then
						$affichage&=@CRLF & "IP4:                        " & @IPAddress4
					EndIf
					$affichage&=@CRLF & "Le " & @MDAY & "/" & @MON & "/" & @YEAR & " à " & @HOUR & ":" & @MIN & ":" & @SEC
					
					MsgBox(0,"Infos",$affichage)

				; Edition du wpkg.log
				Case $msg = $Champ_WPKGlog
					Run("notepad.exe " & @WindowsDir & "\wpkg.log")

				; Edition du wpkg.txt
				Case $msg = $Champ_WPKGtxt
					Run("notepad.exe " & @WindowsDir & "\wpkg.txt")

				; Contrôle des processus tournant sous l'identité de adminse3
				Case $msg = $Champ_WPKGprocess
					$list = ""
					$ObjWMIService = ObjGet ( "winmgmts:{impersonationLevel = impersonate}!\\.\root\cimv2" )
					$ColSettings = $ObjWMIService.ExecQuery ( "SELECT * FROM Win32_Process" )
					For $objProcess In $ColSettings
						$strNameOfUser = ""
						$strUserDomain = ""
						$colProperties = $objProcess.GetOwner($strNameOfUser, $strUserDomain)
						If StringLower($strNameOfUser) = "adminse3" Then
							$list &= $objProcess.Name & @CRLF
						EndIf
					Next
					If $list = "" Then
						MsgBox ( 0 , "Processus d'adminse3" , "Aucun processus trouvé !" )
					Else
						MsgBox ( 0 , "Processus d'adminse3" , $list )
					EndIf
					;$SCRIPT=@ScriptDir & "\listProcessAdminse3.vbs"
					;Run(@ComSpec & " cmd /c @echo **************************** & @echo Liste des processus ADMINSE3 & @echo **************************** & cscript " & $SCRIPT & " & pause", "", @SW_MAXIMIZE)

				; Lecture de la clé RUNNING
				Case $msg = $Champ_WPKGreg
					$valeur=RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WPKG","Running")
					$chaine="La valeur de la clé" & @CRLF & "   HKEY_LOCAL_MACHINE\SOFTWARE\WPKG" & @CRLF & "est:" & @CRLF & "   " & $valeur
					If $valeur == "true" Then
						$chaine=$chaine & @CRLF & "Si plus aucune tâche ne tourne sous l'identité ADMINSE3," & @CRLF & "cette clé devrait être à FALSE."
					EndIf
					MsgBox(0,"Info",$chaine)

				; Correction de la clé RUNNING
				Case $msg = $Champ_WPKGreg2
					$valeur=RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WPKG","Running")
					If $valeur == "false" Then
						MsgBox(0,"Info","La valeur de " & @CRLF & "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running" & @CRLF & "est déjà FALSE.")
					Else
						$ecriture=RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\WPKG","running","REG_SZ","false")
						If $ecriture <> 1 Then
							MsgBox(0,"Erreur","Il s'est produit une erreur lors de la tentative de passage à FALSE de la valeur" & @CRLF & "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running")
						EndIf
					EndIf

				; Suppression du client wpkg
				Case $msg = $Champ_WPKGsuppr
					If FileExists(@WindowsDir & "\wpkg-client.vbs") Then
						FileRecycle(@WindowsDir & "\wpkg-client.vbs")
						;If @error == 1 Then
						Sleep(1000)
						If FileExists(@WindowsDir & "\wpkg-client.vbs") Then
							MsgBox(0,"Erreur","Il s'est produit une erreur lors de la tentative de suppression de" & @CRLF & "   " & @WindowsDir & "\wpkg-client.vbs")
						Else
							MsgBox(0,"Succès","La suppression de " & @CRLF & "   " & @WindowsDir & "\wpkg-client.vbs" & @CRLF & "a réussi." & @CRLF & "Le VBS sera réinstallé à la prochaine connexion.")
						EndIf
					Else
						MsgBox(0,"Info","Le fichier" & @CRLF & "   " & @WindowsDir & "\wpkg-client.vbs" & @CRLF & "n'est pas présent.")
					EndIf

				; Edition du wpkg.xml
				Case $msg = $Champ_WPKGxml
					Run("notepad.exe " & @WindowsDir & "\system32\wpkg.xml")

				; Suppression du wpkg.xml
				Case $msg = $Champ_WPKGsupprxml
					If FileExists(@WindowsDir & "\system32\wpkg.xml") Then
						FileRecycle(@WindowsDir & "\system32\wpkg.xml")
						;If @error == 1 Then
						Sleep(1000)
						If FileExists(@WindowsDir & "\system32\wpkg.xml") Then
							MsgBox(0,"Erreur","Il s'est produit une erreur lors de la tentative de suppression de" & @CRLF & "   " & @WindowsDir & "\system32\wpkg.xml")
						Else
							MsgBox(0,"Succès","La suppression de " & @CRLF & "   " & @WindowsDir & "\system32\wpkg.xml" & @CRLF & "a réussi." & @CRLF & "Lors de la prochaine exécution de WPKG, toutes les applications seront testées sans tenir compte d'éventuels enregistrements d'une précédente exécution.")
						EndIf
					Else
						MsgBox(0,"Info","Le fichier" & @CRLF & "   " & @WindowsDir & "\wpkg-client.vbs" & @CRLF & "n'est pas présent.")
					EndIf

					;ExitLoop
					;GUIDelete()

				; On teste si l'utilisateur a cliqué sur le bouton CANCEL
				;Case $msg = $Cancel_Btn
				;	;MsgBox(64, "Abandon!", "Vous avez souhaité abandonner la mise en place.")
				;	GUIDelete()
				;	Exit


				; On teste si l'utilisateur a cliqué sur le bouton CANCEL
				Case $msg = $GUI_EVENT_CLOSE
					;ExitLoop
					GUIDelete()
					Exit
			EndSelect
		WEnd
EndIf
Exit
