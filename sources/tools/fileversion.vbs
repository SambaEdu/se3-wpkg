' cscript fileversion.vbs NomFichier [GT|GE|LT|LE|EQ valeur]
' Retourne 0 si la version du Fichier vérifie le test

Set objArgs = WScript.Arguments
Dim Fich, Op, Oper, Valeur, ValVersion

Dim nArgs : nArgs = objArgs.Count
Dim f

If nArgs = 0 Then
	Syntaxe
Else
	If nArgs >= 1 Then
		Fich = objArgs(0)
		If TestFileExist(Fich) Then
			ValVersion = FileVersion(Fich)
			If nArgs = 1 Then
				WScript.Echo ValVersion
			End If
		Else
			WScript.Echo "Fichier absent !"
			WScript.Quit 4 ' Fichier absent
		End If
	End If
	If nArgs = 2 Then
		Syntaxe
	Else
		If nArgs = 3 Then
			If TestFileExist(Fich) Then
				
				Op = UCase(objArgs(1))
				'WScript.Echo "Op=" & Op
				Select Case Op
					Case "GT" Oper = ">"
					Case "GE" Oper = ">="
					Case "LT" Oper = "<"
					Case "LE" Oper = "<="
					Case "EQ" Oper = "="
					Case Else
						syntaxe
						WScript.Quit 3 ' Test inconnu
				End Select
				'WScript.Echo "Oper=" & Oper
			Else
				WScript.Echo "Fichier absent !"
				WScript.Quit 4 ' Fichier absent
			End If
			Valeur = objArgs(2)
			'WScript.Echo "ValVersion=" & ValVersion
			If Valeur <> "" Then
				'WScript.Echo ValVersion
				If Valeur <> "" Then
					If TestFileExist(Valeur) Then
						' Remplace le nom du fichier par son n° de version
						Valeur = FileVersion(Valeur)
					End If
				Else
					Syntaxe
					WScript.Quit 3 ' Test inconnu
				End If
			End If
			If Eval("TestVersion(ValVersion, Valeur) "& Oper &" 0") Then
				WScript.Echo ValVersion & " " & Oper & " " & Valeur & " : VRAI"
				WScript.Quit 0
			Else
				WScript.Echo ValVersion & " " & Oper & " " & Valeur & " : FAUX"
				WScript.Quit 1
			End If
		End If
	End If
End If

Function Syntaxe()
	WScript.Echo "cscript fileversion.vbs NomFichier [GT|GE|LT|LE|EQ valeur]"
	WScript.Echo "    valeur peut être égal à un nom de fichier ou à un n° de version."
	WScript.Echo "    Retourne 0 si le test réussit"
End Function
Function TestVersion(v1, v2)
	'Compare les chaines de version v1 et v2 et reourne +1, -1 ou 0
	Dim i1, i2, va1, va2, vn1, vn2
	Dim retour
	'WScript.Echo "v1=" & v1 & ", v2="& v2
	i1 = InStr(v1, ".")
	i2 = InStr(v2, ".")
	If i1 > 0 Then
		va1 = Left(v1, i1-1)
		vn1 = Mid(v1, i1+1)
	Else
		va1 = v1
		vn1 = ""
	End If
	If i2 > 0 Then
		va2 = Left(v2, i2-1)
		vn2 = Mid(v2, i2+1)
	Else
		va2 = v2
		vn2 = ""
	End If
	If va1 = "" Then va1 = 0
	If va2 = "" Then va2 = 0
	If CInt(va1) = CInt(va2) Then
		If vn1 = "" And vn2 = "" Then
			retour = 0
		Else
			retour = TestVersion(vn1, vn2)
		End If
	Else
		If CInt(va1) > CInt(va2) Then
			retour = 1
		Else
			retour = -1
		End If
	End If
	TestVersion = retour
	'WScript.Echo "retour =" & retour
End Function
Function TestFileExist(Fichier)
	Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
	TestFileExist = fso.FileExists(Fichier)
End Function
Function FileVersion(Fichier)
	'Retourne la version d'un fichier ou "" sinon
	Dim version
	'pr "Fichier=" & Fichier & vbCrLf & "Valeur=" & valeur
	Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
	If fso.FileExists(Fichier) Then
		'pr "Fichier=" & Fichier & vbCrLf & "existe !"
		version = fso.GetFileVersion(Fichier)
		'pr "version=" & version
		If Len(version) > 0 Then
			FileVersion = version
		Else
			FileVersion = ""
		End If
	Else
		FileVersion = ""
	End If
End Function
