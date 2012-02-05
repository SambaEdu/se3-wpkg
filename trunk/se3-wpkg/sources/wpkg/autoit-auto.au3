; Installation de n'importe quel programme à l'aide d'un autoit générique qui lit un fichier ini par application
; Comportement :
; 1. pour chaque prog.xml nécessaire, on descend un fichier /var/se3/unattended/install/packages/prog/prog.ini contenant les noms des fenêtres et
;     boutons à cliquer, étape par étape (voir structure ci-dessous)
; 2. Dans le cas où une clé de licence est demandée, l'administrateur doit effectuer une copie de ce fichier en /var/se3/unattended/install/packages/prog/prog-perso.ini
;     puis compléter la clé de licence dans la ligne "key=......"
;  Rque : le fait de renommer le fichier ini évite qu'il soit écrasé lors d'une prochaine mise à jour du prog.xml

; Fonctionnement côté développement :
; 1. le xml de l'application doit appeler <install cmd='%z%\wpkg\autoit-auto.exe %z%\packages\prog\prog.ini' />
; 2.  Dans ce dossier %Z%\packages\prog, il faut créer un fichier prog.ini qui contient les sections et fenêtres à fermer.

; Structure du fichier prog.ini
; [section1]
; titre=titre de la fenetre
; 

; mode debug = 0 par defaut.
$debug = 1

If EnvGet("Z") = "" Then 
	EnvSet( "Z", "\\se3\install")
EndIf

; options autoit
Opt("WinWaitDelay",2000)
Opt("WinTitleMatchMode",4)
Opt("WinDetectHiddenText",1)
;Opt("RunErrorsFatal",0)

If $CmdLine[0] <> 0 Then
	$file_ini = $CmdLine[1]
Else
	; pour mes tests en VM sans argument
	;$file_ini = "Y:\SambaEdu3\wpkg-packages\files\generis\generis-remove.ini"
	$file_ini = "Y:\SambaEdu3\wpkg-packages\files\generis\generis.ini"
EndIf

IniReadSectionNames($file_ini)
If @error Then  
	_Message("Fichier passé en argument 1 absent : " & $file_ini & ".")
	Exit(1)
Else
	_Message("Installation en cours à partir de " & $file_ini)
EndIf

; En argument deux, on peut passer deux choses :
; 0. Si pas d'argument 2, le script teste si %Z%\packages\prog\prog-key.ini (le même que passé en argument 1 mais avec le suffixe "-key") existe
; 1. le nom du fichier ini perso qui contient la clé de licence : ne sera pas écrasé lors d'une maj wpkg du package.
; 2. le Nom du programme afin que l'autoit aille chercher la clé de licence dans le fichier "%Z%\site\wpkg_apps.ini"
; (partie 2 non implémentée pour le moment)

; initialisation de la variable pour savoir si un fichier de licence est fourni
$nokey=0

If $CmdLine[0] < 2 Then
	;_Message("Il y a 0 ou 1 argument :" & $CmdLine[0])
	;Sleep(3000)
	; si l'argument 2 est vide, on teste le fichier -key.ini sinon le fichier wpkg_apps.ini
	; fichier perso de licence propre à l'appli
	$cheminZ=StringRegExpReplace($file_ini ,"\\", "\\\\" )
	$licence_ini = StringRegExpReplace($cheminZ ,".ini", "" ) & "-key.ini"
	If $debug > 1 Then
		_Message("Argument facultatif n°2 absent. Tentative d'utilisation du fichier: " & $licence_ini)
	EndIf
	IniReadSectionNames($licence_ini)
	If @error Then
		; fichier commun à toutes les applis : la section doit porter le nom de la section correspondante dans prog.ini et comporter une clé "key"
		$licence_ini = EnvGet("Z") & "\site\wpkg_apps.ini"
		IniReadSectionNames($licence_ini)
		If @error Then 
			If $debug > 1 Then 
				_Message("Fichier avec suffixe -key absent et " & @CRLF & $licence_ini & " absent.")
			EndIf
			$nokey=1
			; tous les progs n'ont pas besoin d'une clé : on mémorise qu'il n'y a pas de fichier de clé fournie
		Else
			If $debug = "1" Then 
				_Message("Installation en cours à partir du fichier de licence : " & $licence_ini)
			EndIf
		EndIf
	Else
		If $debug = "1" Then 
			_Message("Installation en cours à partir du fichier de licence : " & $licence_ini)
		EndIf
	EndIf
Else
	;_Message("Il y a 2 arguments :" & $CmdLine[2])
	;Sleep(3000)
	; l'argument 2 n'est pas vide : on teste si le fichier existe ; dans le cas contraire, on sort avec une erreur
	$licence_ini=$CmdLine[2]
	IniReadSectionNames($licence_ini)
	If @error Then
		_Message("Fichier passé en argument 2 absent : " & $licence_ini)
		Exit(1)
	Else
		If $debug > 1 Then 
			_Message("Installation en cours à partir du fichier de licence : " & $licence_ini)
		EndIf
	EndIf
EndIf

IniReadSectionNames($licence_ini)
If @error Then 
	If $debug = "1" Then
		_Message("Fichier " & $licence_ini & " absent.")
	EndIf
Else
	If $debug > 1 Then
		_Message("Installation en cours à partir du fichier de licence : " & $licence_ini)
	EndIf
EndIf

; on essaie de trouver le numero de licence dans "Z:\site\wpkg_apps.ini" sinon dans "Z:\packages\prog\prog-key.ini"
; A IMPLEMENTER : il faut chercher la section quand on en a besoin dans action_programmee()
;$section = "test"
;IniReadSection($licence_ini, $section)
;If @error Then 
	;$licence_ini = EnvGet("Z") & "\packages\" & $prog & "\" & $prog & "-key.ini"
	;IniReadSection($licence_ini, $section)
	;If @error Then 
		;If $debug = "1" Then 
		;	_Message("Section " & $section & " introuvable dans " & $licence_ini & ".")
		;EndIf
		;$nokey=1
		; tous les progs n'ont pas besoin d'une clé
		;Exit(1)
	;EndIf
;EndIf

;on boucle sur toutes les sections et on fait ce qui est demandé dans l'ordre avec des boucles pour attendre le programme d'install
$sectionsliste = IniReadSectionNames($file_ini)
If @error Then
    If $debug = "1" Then
		_Message("Ne peut pas se produire vu les tests du début. Error occurred, probably no INI file.")
	EndIf
Else
    For $i = 1 To $sectionsliste[0]
        ;MsgBox(4096, "", $sectionsliste[$i])
		; lecture du timeout sinon on fixe un timeout par défaut à 900 secondes=15 minutes
		$timeout = 900
		; par défaut, on attend 1 seconde après avoir réalisé l'action de la section courante
		$afterwait = 1
		; réinitialisation des actions à mener entre deux sections.
		$actiontexte = ""
		$actionrun = ""
		$actiontitre = ""
		$actionbouton = ""
		$actionkey = ""
		$actionname = ""
		$actionkeymultizone = 0
		;If $debug = "1" Then
			;_Message( "Toutes variables initialisées :" & $actionrun )
		;EndIf
		
		; lecture des actions programmees : plusieurs variables peuvent être nécessaires pour une action
		$var = IniReadSection($file_ini, $sectionsliste[$i])
		For $j = 1 To $var[0][0]
		    ;MsgBox(4096, "", $sectionsliste[$i] & @CRLF & "Key: " & $var[$j][0] & @CRLF & "Value: " & $var[$j][1])
			; une fonction lit la clé et affecte les bonnes variables pour exécution en fin de section.
			_ActionProgrammee($var[$j][0] , $var[$j][1])
		Next
		
		; A IMPLEMENTER
		; si $nokey=0
		; Alors on teste si, dans $licence_ini , une section $sectionsliste[$i] existe
		; 	si oui, on lit la clé key et on met sa valeur dans $actionkey
		; 	si non , on passe à la suite.
		
		; lancement des actions programmees
		_ActionLanceur()
    Next
EndIf

Func _ActionProgrammee($key , $value)
	; action timeout personnalisé
	If $key = "timeout" Then
		$timeout = $value
	EndIf	
	
	; action afterwait : permet d'attendre x secondes après l'action en cours dans la section
	If $key = "afterwait" Then
		$afterwait = $value
	EndIf	
	
	; action run
	If $key = "run" Then
		$actionrun = "" & $value & ""
	EndIf
	
	; action clic sur un bouton
	If $key = "titre" Then
		$actiontitre = $value
	EndIf
	If $key = "bouton" Then
		$actionbouton = $value
	EndIf
	If $key = "texte" Then
		$actiontexte = $value
	EndIf
	
	; action saisie clé de licence avec nom d'utilisateur
	If $key = "key" Then
		$actionkey = $value
		$actionkeytab = StringSplit( $actionkey , "-" )
	EndIf
	If $key = "name" Then
		$actionname = $value
	EndIf
	; indique qu'il faudra tabuler pour saisir la clé dès qu'un tiret sera rencontré. Sinon, on saisit la clé dans un seul et unique champ.
	If $key = "keymultizone" Then
		$actionkeymultizone = $value
	EndIf
	
EndFunc

Func _ActionLanceur()
	; initialisation du compteur temps à chaque fenêtre
	$begin = TimerInit()
	
	; action timeout personnalisé
	If $timeout <> 900 Then
		If $debug = "1" Then
			_Message("Timeout perso :" & $timeout )
		EndIf
	Else
		If $debug > 1 Then
			_Message("Timeout par défaut :" & $timeout )
		EndIf
	EndIf	

	; action run
	If $actionrun <> "" Then
		; problème avec l'antislash compris dans EnvGet("Z") qui est interprété : il faut donc le doubler.
		$cheminZ=StringRegExpReplace(EnvGet("Z") ,"\\", "\\\\" )
		$cheminProgramFiles=StringRegExpReplace(EnvGet("ProgramFiles") ,"\\", "\\\\" )
		$Commande=StringRegExpReplace(StringRegExpReplace($actionrun,"%Z%", $cheminZ ),"%ProgramFiles%", $cheminProgramFiles )
		If $debug = "1" Then
			_Message("Action run : " & $actionrun & "." & @CRLF & "interprété : " & $Commande )
		EndIf
		$pid = Run($Commande, EnvGet("SystemRoot"))
	EndIf
	
	; action saisie clé de licence
	If $actionkey <> "" Then
	If $actiontitre <> "" And $actionkey <> "" Then
		If $debug = "1" Then
			_Message("Action clé de licence perso :" & $actionkey & " dans la fenêtre : " & $actiontitre )
		EndIf
		; A VERIFIER : non testé 
		If WinExists($actiontitre,$actiontexte) Then
			; on clique sur le champ de saisie désiré
			ControlClick($actiontitre, $actiontexte, $actionbouton)
			If $actionkeymultizone = 1 Then
				; la clé est à saisir dans plusieurs cases : on va tabuler entre chacune.
				;on saisit en tabulant à chaque tiret rencontré.
				For z = 1 to $actionkeytab[0]
					; peut etre rajouter l'activation de la fenêtre.
					; WinActivate etc...
					ControlSetText($actiontitre, $actiontexte, "", $actionkeytab[$z])
					ControlSetText($actiontitre, $actiontexte, "", "tab")
				Next
			Else
				; on saisit la clé direct dans l'unique champ présent
				ControlSetText($actiontitre, $actiontexte, $actionbouton, $actionkey)
			EndIf
		EndIf
	ElseIf $actiontitre = "" Or $actionkey <> "" Then
		; dans le cas où une key est fournie , il faut absoluement renseigner un titre de fenêtre.
		If $debug = "1" Then
			_Message("La clé key est fournie mais le titre de la fenêtre n'est pas fourni dans la section : " & $sectionsliste[$i] & ". Il est nécessaire de définir les deux pour que la clé de licence soit saisie")
		EndIf
	EndIf
	;Else
		;If $debug = "1" Then
		;	_Message("pas de key fournie dans la section : " & $sectionsliste[$i] & ".")
		;EndIf
	EndIf
	
	; action clic sur un bouton
	If $actiontitre <> "" And $actionbouton <> "" Then
		; le texte du bouton est facultatif mais préférable.
		If $debug = "1" Then
			_Message( "Action clic bouton programmee sur le bouton :" & $actiontexte & "(Advanced mode :" & $actionbouton & "), dans la fenêtre : " & $actiontitre )
		EndIf
		
		; variable permettant de savoir si on sort de la boucle par timeout ou par succès d'apparition de la fenêtre.
		$success = 0

		While 1
			$timediff = Int(TimerDiff($begin) / 1000)
			; existence de la fenêtre ?
		    If WinExists($actiontitre, $actiontexte) Then
		      ; décoche l'option installer 'Installez le logiciel gratuit Norton Security Scan'
		      ControlClick($actiontitre, $actiontexte, $actionbouton)
			  ; on passe à la section suivante en validant le success dans la variable.
			  $success=1
			  If $debug = "1" Then
				_Message("ControlClick(" & $actiontitre & "," &  $actiontexte & "," & $actionbouton & ") effectué. " & @CRLF & "On passe à la section qui suit la section " & $sectionsliste[$i] )
			  EndIf
			  ExitLoop
		    EndIf
			_Message("Attente de la fenêtre : " & $actiontitre & @CRLF & "depuis " & $timediff & " secondes avec un timeout de " & Number($timeout) & " secondes.")
			
			; dépassement du timeout ?
			If $timediff > Number($timeout) Then
				_Message("Timeout atteint : " & $timediff & ">" & Number($timeout))
				Sleep(1000)
				ExitLoop
			EndIf
			Sleep(500)
		WEnd
		If $success=0 Then
			If $debug = "1" Then
				_Message("Timeout atteint : la fenêtre espérée n'existe toujours pas après " & $timeout & " secondes." )
				Sleep(1000)
			EndIf
			Exit(1)
		EndIf
	ElseIf $actiontitre <> "" Or $actionbouton <> "" Then
		If $debug = "1" Then
			_Message("Seule une des deux clés bouton ou titre est définie dans la section : " & $sectionsliste[$i] & ". Il est nécessaire de définir les deux pour que l'autoit puisse cliquer sur le bouton désiré." )
		EndIf
	EndIf
	
	; action attente après action personnalisée : $afterwait
	If $afterwait <> 1 Then
		If $debug = "1" Then
			_Message("Afterwait personnalisé : script en pause durant " & $afterwait & " secondes.")
			Sleep(4000)
		EndIf
	EndIf
	Sleep($afterwait * 1000)
EndFunc

; messages
Func _Message($mess)
	SplashTextOn("Informations Autoit-auto", $mess ,500,100,-1,0)
	Sleep(2000)
EndFunc

Exit(0)