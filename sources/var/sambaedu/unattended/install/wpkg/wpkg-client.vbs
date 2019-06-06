'Option Explicit

' Client wpkg - Etablit la connexion au serveur en attendant que les services r�seau aient d�marr�s
'             - Lance l'ex�cution de wpkg-se4.js
'             - G�re les remont�es des rapports
'
'
'
' Syntaxe :  cscript wpkg-client.vbs[ /noTempo][ /cpuLoad xx]
'                  /noTempo    : pour avoir des tempo r�duites (utile pour un lancement en ligne de commande sans avoir � attendre...)
'                  /cpuLoad xx : Attend (charge cpu en %) < xx  avant de d�marrer (10% par defaut).
'                  /Tempo nn   : Attend nn sec avant de d�marrer (30 par defaut).
'                  /debug      : Affiche en temps r�el les msg lors de l'ex�cution de wpkg-se4.js.

On Error Resume Next

Const ForReading=1, ForWriting=2, ForAppending=8

' ----------------------------------------------------------------------------------
'
' Vous pouvez personnaliser ici le param�trage du client wpkg.
'
Dim LogMode        : LogMode = 2         ' Type de log. 0=Pas de log, 2=Log derni�re execution, 8=Log avec conservation de l'historique
Dim secBeforeStart : secBeforeStart = 30 ' Nombre de secondes � attendre avant d�marrer
Dim secAfterRun    : secAfterRun = 5     ' Nombre de secondes � attendre pour RemoveNetworkDrive
Dim maxCpuLoad     : maxCpuLoad = 10     ' % Charge CPU maxi autoris�e pour d�marrer
Dim ServeurWpkg    : ServeurWpkg = "se4fs"  ' Serveur utilis� par les clients wpkg
Dim testCPU		   : testCPU = false	  ' test CPU d�sactiv� par d�faut � cause des soucis de d�tection sur les nouveaux CPU : 06/2013
'  Par d�faut, le serveur se4 est utilis� pour d�ployer les applications.
'  Vous pouvez cependant pr�f�rer utiliser un autre serveur (par ex. si se4 est tr�s charg�).
'  Pour utiliser le serveur 'NomDuServeur' � la place de 'se4', il faut :
'     - cr�er un partage nomm� 'install' sur le serveur 'NomDuServeur'
'     - cr�er sur ce serveur un utilisateur 'adminse_name' ayant le mot de passe indiqu� dans http://se4/setup (adminse_passwd)
'     - permettre � adminse_name d'�crire dans \\NomDuServeur\install\wpkg\rapports
'          (un acc�s en lecture suffit pour les autres dossiers et fichiers de ce partage)
'     - d�finir ci-dessus   ServeurWpkg = "NomDuServeur"   et enregistrer ce fichier (\\se4\install\wpkg\wpkg-client.vbs) ,
'     - recopier le contenu de \\se4\install dans \\NomDuServeur\install
'
'  De plus, pour que la gestion de la configuration des applis continue � se faire par l'interface web de se4,
'    D�finir sur MonServeur un compte ADMINSE_NAME mot de passe PassWWWSE4 ayant un acces rw sur le partage \\NomDuServeur\install
'    puis sur le se4 :
'      cp -p /var/se4/unattended/install /var/se4/unattended/install.bak
'      rm -R /var/se4/unattended/install/*
'      mount -t smbfs -o username=ADMINSE_NAME,password=ADMINSE_PASSWD //NomDuServeur/install /var/se4/unattended/install
'           ou  ( USER=NomDuServeur/ADMINSE_NAME%ADMINSE_PASSWD
'                 smbmount //NomDuServeur/install /var/se4/unattended/install  )
'    Rmq. Le nom d'utilisateur ADMINSE_NAME et le mot de passe PassWWWSE4 doivent bien s�r �tre adapt� selon votre imagination...
'
'  Au prochain d�marrage des postes, le client wpkg sera mis � jour avec son nouveau param�trage.
'
'------------------------------------------------------------------------------------

Dim printOutput : printOutput = True
Dim watchDog : watchDog = 18000 ' Temps maxi en secondes pour l'ex�cution de wpkg-se4.js
Dim CodeSortie : CodeSortie = 0

Dim UNC : UNC = "\\" & ServeurWpkg & "\install" 'Chemin du partage install
Dim Z : Z="z:" 'unit� � mapper
Dim RunningStatus
Dim oNet, User, ComputerName, UserDomain
Dim oShell, WinDir, ComSpec
Dim fso, f, tf, fLog, iLog : iLog=0
Set fLog = Nothing
Dim i
Dim MAC, addmac, mac2
Dim TypeWin

Dim objArgs : Set objArgs = WScript.Arguments
Dim arg
Dim Tempo : Tempo = True
Dim debugVbs : debugVbs = False
Dim FinExec

Set oShell = WScript.CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
If fso.FileExists(oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst\wpkg-notempo.txt") Then
   Tempo = False
End If

WinDir = oShell.ExpandEnvironmentStrings("%WinDir%")
ComSpec = oShell.ExpandEnvironmentStrings("%ComSpec%")

Dim ageLastLog, ageLastTxt
dateLastLog

If Not fso.FolderExists(oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst\logs") Then
   If Not fso.FolderExists(oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst") Then
      fso.CreateFolder(oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst")
   End If
   fso.CreateFolder(oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst\logs")
End If

' Conversion OEM -> ANSI
Dim oem
InitOEM

Dim debug : debug=false ' Permet d'avoir des logs plus d�taill�s.
Dim logdebug : logdebug=false ' Pour avoir des logs en temps r�el sur le serveur.
Dim force : force=false ' Pour tester la pr�sence ou l'absence effective de chaque appli sur le poste.
Dim forceinstall : forceinstall=false ' Pour installer ou d�sinstaller les applications m�me si les tests 'check' sont v�rifi�s.
Dim nonotify : nonotify=false ' Pour ne pas avertir l'utilisateur logu� des op�rations de wpkg (si false, le service messenger doit �tre activ�).
Dim norunningstate : norunningstate=false ' Pour que wpkg n'�crive pas running : norunningstate=false ' Pour que wpkg n'�crive pas running=true dans la base de registre lorsqu'il s'ex�cute.
Dim dryrun : dryrun=false ' Pour que wpkg simule une ex�cution mais n'installe ou ne d�sinstalle rien.
Dim nowpkg : nowpkg=false ' Pour ne pas ex�cuter wpkg sur le poste.
Dim noforcedremove : noforcedremove=false ' Mettre � true pour ne pas retirer les zombies de la base de donn�e locale.

' Ajouts version 1.1.2 de wpkg.js (Olikin)
Dim noreboot : noreboot=true  ' Pour ne pas rebooter en cours de session, m�me si un programme le n�cessite.
Dim logLevel : logLevel=23 ' Masque binaire : 0  disable logging.  1  log errors only  2  log warnings  4  log information  8  log audit success  16 log audit failure 

ParseArguments

Dim Ligne1
Ligne1 = TimeStamp() & " wpkg-client.vbs : Debut"
AttendUnPeu

Dim oWMIService
If Not WaitWMIService() Then WScript.Quit 15

Dim MsgErrNoRun : MsgErrNoRun=""
Dim cProc
Dim oProc, cpuLoadOK, cpuLoad
If testCPU Then 
   if Not TestCpuLoad() Then
       MsgErrNoRun = "La charge cpu est trop �lev�e. Pas d'ex�cution de wpkg."
       nowpkg=true
       CodeSortie = 14
       ' WScript.Quit 14
   End If
End If

If Not SetComputerName() Then   ' D�fini ComputerName, User et UserDomain
   MsgErrNoRun = "Erreur lors de la d�termination de ComputerName, User et UserDomain. Pas d'execution de wpkg."
   nowpkg=true
   CodeSortie = 13
   WScript.Quit 13
End If

Z=MapZ()
If Z = "" Then WScript.Quit 12
Dim WPKGSE4JS : WPKGSE4JS= Z & "\wpkg\wpkg-se4.js"
If Not fso.FileExists(WPKGSE4JS) Then
   print "Erreur: script '" & WPKGSE4JS & "' absent !"
   WScript.Quit 13
Else
   print "Script '" & WPKGSE4JS & "' pr�sent."
End If

fso.DeleteFile oShell.ExpandEnvironmentStrings("%TEMP%\wpkgcmd*.bat"), true
fso.DeleteFile oShell.ExpandEnvironmentStrings("%TEMP%\wpkgex*.log"), true
wpkgAuBoot 'execute s'il existe %Windir%\wpkgAuBoot.bat

If Not TestRunningStatus() Then 
   print "Erreur RunningStatus."
   MsgErrNoRun = "Erreur RunningStatus."
   WScript.Quit 1
End If
'WScript.Echo "dbg: Apr�s TestRunningStatus"

Dim cmd, sStd, sStdOut, CodeRetour, oExec
Dim NoPrint : NoPrint = False

' ---------------- Ex�cution wpkg-se4.js  --------------------
dim fNameLog : fNameLog = Z & "\wpkg\rapports\" & ComputerName & ".log"
dim fLocalLog : fLocalLog = WinDir & "\wpkg.log"
dim fLocalTxt : fLocalTxt = WinDir & "\wpkg.txt"
dim fLocal : fLocal = fLocalLog ' Puis devient fLocalTxt pour sauvegarder l'etat
dim lenLog ' Taille du fichier fLocalLog d�j� lu
dim bufferLog : bufferLog = ""
dim timerLog : timerLog = Timer

InitLogFile

' Initialisation variables pour les tooltip
Dim MSGfile : MSGfile = WinDir & "\wpkg-msg.exe"
Dim MSGlog   : MSGlog = WinDir & "\wpkg-msg.txt"
Dim Dest
' sur windows 7, le dossier D�marrage de AllUsers est diff�rent.
' C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
If InStr(GetTypeWin, "winxp") > 0 Or InStr(GetTypeWin, "win2k") > 0 Then
	' on est sur windows XP ou 2000
	Dest=oShell.ExpandEnvironmentStrings("%AllUsersProfile%") & "\Menu D�marrer\Programmes\D�marrage\"
Else
	'on est sur windows 7 ou vista ou sucesseur.
	Dest=oShell.ExpandEnvironmentStrings("%AllUsersProfile%") & "\Microsoft\Windows\Start Menu\Programs\Startup\"
End If
Dim TOOLTIPfile  : TOOLTIPfile = Dest & "tooltip.exe"
Dim tooltipActifs : tooltipActifs = true
If InStr(GetTypeWin, "Server") > 0 Then
	tooltipActifs = false ' ToolTip inactifs sur les Windows Server.
	TooltipDelete() ' nettoyage des tooltips ant�rieurement d�ploy�s sur les OS serveurs
End If

If tooltipActifs Then
	TooltipInit 'initialisation de la configuration du poste, si besoin.
End If

If MiseAJourClient() Then WScript.Quit ' Teste si un nouveau client est dispo sur le serveur

If Not nowpkg Then ExecIni ' Ex�cution du vbs ini\%ComputerName%.ini  pour initialiser le param�trage

' D�commenter Si les param�tres de la ligne de commande sont prioritaires devant la conf ini
'ParseArguments

Dim NoWpkgTxt : NoWpkgTxt=oShell.ExpandEnvironmentStrings("%SystemDrive%") & "\netinst\nowpkg.txt"
If fso.FileExists(NoWpkgTxt) Then
   nowpkg = True
   dump "Le fichier '" & NoWpkgTxt & "' existe." & vbCrLf & _
      "  Pas de synchro des applis pour cette fois."  & vbCrLf & _
      "  Suppression du fichier pour qu'� la prochaine ex�cution du client la synchro ait lieu."
   fso.DeleteFile(NoWpkgTxt)
End If

' on impose /noDownload car les downloads sont geres cote serveur sur se4. Cela evite de patcher wpkg.js a chaque maj pour ce point.
' mise � jour 1.3 : on impose /applymultiple:true car, dans l'interface se4, plusieurs profiles s'appliquent � un seul poste.
dim WPKG_OPTIONS : WPKG_OPTIONS = "/synchronize /noDownload /applymultiple:true"

Dim oSysEnv

WpkgSynchronize 'Ex�cute wpkg-se4.js pour synchroniser les applications
EtatPoste  ' D�termine l'�tat des applis sur le poste et remonte l'info sur le serveur

If tooltipActifs Then
	TooltipEnd ' ajout de FIN WPKG dans le fichier MSGfile.
End If

' ---------------- D�connexion se4 --------------------
RemoveNetwork
print "Fin"

WScript.Quit CodeRetour

Function EtatPoste() 
   Dim f, tf, Retour
   fLocal = fLocalTxt
   sStd = InfoPoste()
   Set f = fso.OpenTextFile(fLocal, 2, True) 'ForWriting
   f.Write sStd
   f.Close

   cmd = "%ComSpec% /C cscript //NoLogo " & WPKGSE4JS & " /query:a"  & " >>" & fLocal & " 2>&1"
   print "Remont�e des applis install�es sur le poste ..."
   PrintOutput = False
   Retour = RunCmd(Cmd)
   PrintOutput = True
   If Retour > 0 Then print "Code de Retour=" & Retour

   Set tf = fso.GetFile(fLocal)
   If Err.Number > 0 Then 
      dump "Erreur ouverture fichier " & fLocal
      Err.Clear
   Else
      tf.Copy Z & "\wpkg\rapports\" & ComputerName & ".txt", True
      If Err.Number > 0 Then 
        dump "Erreur ouverture fichier " & Z & "\wpkg\rapports\" & ComputerName & ".txt"
        Err.Clear
      End If
   End If
   End Function
Function RemoveNetwork()
   Dim i
   i = secAfterRun
   Do While i>0
      If Tempo Then 
         Wscript.Sleep 1000
      Else
         Wscript.Sleep 100
      End If
      i = i - 1
   Loop
   Set oDrives = oNet.EnumNetworkDrives
   For i = 0 to oDrives.Count - 1 Step 2
      'print "Lecteur " & oDrives.Item(i) & " = " & oDrives.Item(i+1)
      print "RemoveNetworkDrive " & oDrives.Item(i)
      oNet.RemoveNetworkDrive oDrives.Item(i), True
      If Err.Number > 0 Then 
         print "Erreur RemoveNetworkDrive " & oDrives.Item(i) & " = " & oDrives.Item(i+1)
      End If
   Next
   ' print "RemoveNetworkDrive IPC$"
   ' oNet.RemoveNetworkDrive "\\" & ServeurWpkg & "\IPC$", True
   ' If Err.Number > 0 Then print "Erreur RemoveNetworkDrive \\" & ServeurWpkg & "\IPC$"
   End Function
Function WpkgSynchronize() 'Ex�cute wpkg-se4.js pour synchroniser les applications
   On Error Resume Next
   SetEnvironnement
   oSysEnv("WPKG_OPTIONS") = WPKG_OPTIONS

   cmd = "%ComSpec% /C cscript.exe //NoLogo //T:" & watchDog & " " & WPKGSE4JS & " " & WPKG_OPTIONS & " 1>>" & fLocal &" 2>&1"

   ' Execution de wpkg-se4.js
   If nowpkg = False Then 
      dump cmd & vbCrLf
      CodeRetour = RunCmd(Cmd)
      'If logDebug Then NoPrint=True
      'dump sStd
      'NoPrint = False
      
      If codeRetour = -10 Then 
         dump "---- " & TimeStamp() & " Erreur : Arr�t du script au bout de " & watchDog & " secondes. ----"
         If Err.Number > 0 Then Err.Clear
         oShell.RegDelete "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running"
         If Err.Number > 0 Then
            Err.Clear
         Else
            dump "La cl� HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running a �t� supprim�e."
         End If
      Else
         dump "---- " & TimeStamp() & " CodeRetour=" & CodeRetour & " ----"
      End If
   Else
      dump "noWpkg=true : Pas d'ex�cution de Wpkg."
   End If
   
   'If Not debugVbs Then print "sStd=" & vbCrLf & sStd
   'Recopie de wpkg.log local vers le serveur
   If fso.FileExists( fLocal ) Then
      fso.CopyFile fLocal, Z & "\wpkg\rapports\" & ComputerName & ".log", true
   End If
   End Function
Function SetComputerName()
   SetComputerName = True
   i = 60 ' 60sec maxi
   Set oNet = CreateObject("WScript.Network")
   User = oNet.UserName
   Do While ((Err.Number > 0) Or (User = "")) And (i>0)
      print "oNet.UserName=" & oNet.UserName
      If Tempo Then 
         Wscript.Sleep 1000
      Else
         Wscript.Sleep 10
      End If
      i = i - 1   
      Set oNet = CreateObject("WScript.Network")
      User = oNet.UserName
   Loop
   If i<=0 Then 
      SetComputerName = False
   Else
      ComputerName = LCase(oNet.ComputerName)
      UserDomain = oNet.UserDomain
      print "User=" & User & ", ComputerName=" & ComputerName &", UserDomain=" & UserDomain
   End If
   End Function
Function WaitWMIService()
   Dim i
   i = 60 ' 60sec maxi
   Set oWMIService = GetObject( "winmgmts:" )
   Do While (Err.Number > 0) And (i>0)
      print "GetObject('winmgmts:')"
      If Tempo Then 
         Wscript.Sleep 1000
      Else
         Wscript.Sleep 10
      End If
      i = i - 1
      Set oWMIService = GetObject( "winmgmts:" )
   Loop
   If i<=0 Then 
      print "Erreur : Pas de service WMI. FIN."
      
      WaitWMIService = False
   Else
      print "oWMIService : OK"
      WaitWMIService = True
   End If
   End Function
Function AttendUnPeu()
   Dim i
   If Tempo Then 
      Ligne1 = Ligne1 & " Tempo " & secBeforeStart & " sec."
      print "Debut Tempo " & secBeforeStart & " sec."
      ' Attente avant d�but
      i = secBeforeStart
      Do While (i > 0) And Tempo
         Wscript.Sleep 1000 ' secBeforeStart x 1 seconde d'attente 
         i = i - 1
      Loop
      print "Fin Tempo Start"
   End If
   End Function
Function ParseArguments()
   Dim i
   For i = 0 to objArgs.Count - 1
      arg = Ucase( objArgs(i))
      Select Case  arg
         case "/DEBUG"
            debugVbs = True
         case "/NOWPKG"
            nowpkg = True
         case "/NOTEMPO"
            Tempo = False
         case "/APPENDLOG"
            ' Pour ajouter le log au log pr�c�dent
            LogMode = 8
         case "/CPULOAD"
            i = i + 1
            If IsNumeric(objArgs(i)) Then
               maxCpuLoad = 0 + objArgs(i)
            Else
               print "Syntaxe : /cpuLoad xx  ou xx est  le %cpu maxi autoris� pour d�marrer"
            End If
         case "/TEMPO"
            i = i + 1
            If IsNumeric(objArgs(i)) Then
               secBeforeStart = 0 + objArgs(i)
            Else
               print "Syntaxe : /Tempo nn  ou nn est le nbre de sec � attendre avant de d�marrer"
            End If
      End Select
   Next
   End Function
Function TestCpuLoad
	' Calcul le taux d'occupation processeur du system consomm� par les process sur une dur�e de 5 secondes
	' toutes les 30 secondes. Si ce taux d'occupation est en dessous de la charge maximum demand�e pour lancer WPKG
	'la fonction sort de la boucle et retourne vrai. Au bout de 15 minutes de taux d'occupation sup�rieur
	'la fonction retourne faux.
	bExitFlag = False
	' R�sultat par d�faut.
	TestCpuLoad = False 
	' D�lai entre deux check pour le calcul de performance (5 secondes).
	iDelayBetweenCheck = 5000
	' D�lai entre deux tests de performance de charge (25 secondes).
	iWaitDelay = 25000
	' Nombre de tests de performance maximum a effectuer (un test = 60s).
	iRetryCount = 30
	iRetryCounter =1
	do
	    Set oPPPFirstCheck = oWMIService.Get("Win32_PerfRawData_PerfOS_Processor.Name='_Total'")
		' Taux d'occupation cpu premier check.
		pptFirstCheck = oPPPFirstCheck.PercentProcessorTime
		tssFirstCheck = oPPPFirstCheck.TimeStamp_Sys100NS
		Wscript.Sleep(iDelayBetweenCheck)
	    Set oPPPSecondCheck = oWMIService.Get("Win32_PerfRawData_PerfOS_Processor.Name='_Total'")
		' Taux d'occupation cpu second check.
		pptSecondCheck = oPPPSecondCheck.PercentProcessorTime
		tssSecondCheck = oPPPSecondCheck.TimeStamp_Sys100NS

        ' CounterType - PERF_100NSEC_TIMER_INV
		' Formula - (1- ((N2 - N1) / (D2 - D1))) x 100
		pptCPUConsumed = (1 - ((pptSecondCheck - pptFirstCheck)/(tssSecondCheck-tssFirstCheck)))*100
        Wscript.Echo "% Processor Time=" , pptCPUConsumed	
        If pptCPUConsumed > maxCpuLoad Then 
               Wscript.Echo "cpuLoad = " & pptCPUConsumed & "% > " & maxCpuLoad & "%"
			   Wscript.Echo "Nouveau test de la charge CPU dans " & ((iWaitDelay + iDelayBetweenCheck)/1000) & " secondes. Veuillez patienter."
            Else
			   TestCpuLoad = True
			   Wscript.Echo "cpuLoad : OK ( " & pptCPUConsumed & "% <= " & maxCpuLoad & "% )"
               Exit Do
            End If
		WScript.Sleep(iWaitDelay)
		iRetryCounter = IRetryCounter + 1
		If iRetryCounter > iRetryCount Then
			Wscript.Echo "Dur�e maxi d'attente �coul�e. Le PC est trop charg�."
			Exit Do
	    End if
	loop while (bExitFlag=false)	
	End Function
Function wpkgAuBoot()
   ' Execute s'il existe %WinDir%\wpkgAuBoot.bat
   Dim cmd
   wpkgAuBootBat = WinDir & "\wpkgAuBoot.bat"
   If Not WScript.Interactive Then ' Uniquement si le client a �t� lanc� avec //B  (t�che planifi�e au boot)
      If fso.FileExists( wpkgAuBootBat ) Then
         print "Ex�cution de " & WinDir & "\wpkgAuBoot.bat"
         oShell.Run wpkgAuBootBat, 0, False
      End If
   End If
   End Function
Function dateLastLog()
   If fso.FileExists(fLocalLog) Then
      Set f = fso.GetFile(fLocalLog)
      ageLastLog = ( Now - f.DateLastModified) * 24 * 60 ' Anciennet� du dernier log wpkg en mn
   Else
      ageLastLog = -1
   End If
   If fso.FileExists(fLocalTxt) Then
      Set f = fso.GetFile(fLocalTxt)
      ageLastTxt = ( Now - f.DateLastModified) * 24 * 60' Anciennet� du dernier txt wpkg en mn
   Else
      ageLastTxt = -1
   End If
   End Function
Function TestRunningStatus()
   'print "Dbg: In TestRunningStatus"
   RunningStatus = LireRegistre("HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running")
   dump "RunningStatus = " & RunningStatus & ". LastLog = " & ageLastLog & " mn. LastTxt = " & ageLastTxt & " mn."
   TestRunningStatus = True
   If RunningStatus = "true" Then
      If Not WScript.Interactive Then
         ' Ce script a �t� lanc� par la t�che planifi�e au boot
         ' Il y a un un probl�me 
         dump "Ce n'est pas normal !"
         oShell.RegDelete "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running"
         dump "La cl� HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running a �t� supprim�e."
      Else
         ' Lancement manuel de wpkg
         If ageLastLog > 60 Then ' Plus de 60mn depuis le dernier lancement
            ' Suppression de l'entr�e registre
            print "RunningStatus = " & RunningStatus & ". Wpkg est indiqu� en ex�cution depuis plus de 1h. C'est s�rement une erreur."
            oShell.RegDelete "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running"
            print "La cl� HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running a �t� supprim�e."
         Else
            If ageLastLog < 0 Then ' wpkg.log absent
               ' Suppression de l'entr�e registre
               print "RunningStatus = " & RunningStatus & ". Wpkg est indiqu� en ex�cution mais wpkg.log est absent."
               oShell.RegDelete "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running"
               print "La cl� HKEY_LOCAL_MACHINE\SOFTWARE\WPKG\running a �t� supprim�e."
            Else
               'Moins de 60mn depuis le dernier rapport
               print "RunningStatus = " & RunningStatus & ". Wpkg est d�j� indiqu� en cours d'ex�cution. FIN."
               TestRunningStatus = False
            End If
         End If
      End If
   End If
   'print "Dbg: Sortie TestRunningStatus RunningStatus="  & RunningStatus
   End Function
Function MiseAJourClient()
   Dim argCh, oExec, i
   MiseAJourClient = False
   If UpdateFile(Z & "\wpkg\wpkg-client.vbs", Windir & "\wpkg-client.vbs") = 1 Then
      dump TimeStamp() & " Mise � jour du client."
      ' Red�marrage avec le nouveau client
      argCh = ""
      For i = 0 to objArgs.Count - 1
         argCh = argCh & " " & objArgs(i)
      Next
      Set oDrives = oNet.EnumNetworkDrives
      For i = 0 to oDrives.Count - 1 Step 2
         'print "Lecteur " & oDrives.Item(i) & " = " & oDrives.Item(i+1)
         print "RemoveNetworkDrive " & oDrives.Item(i)
         oNet.RemoveNetworkDrive oDrives.Item(i), True
         If Err.Number > 0 Then 
            print "Erreur RemoveNetworkDrive " & oDrives.Item(i) & " = " & oDrives.Item(i+1)
            Err.Clear
         End If
      Next
      dump TimeStamp() & " Red�marrage avec le nouveau client."
      Set oExec = oShell.Exec("%ComSpec% /C cscript.exe //NoLogo " & WScript.ScriptFullName & argCh & " 2>&1")
      Do While oExec.Status = 0
         ' WScript.Sleep 300
         WScript.StdOut.Write oExec.StdOut.Read(1)
      Loop
      dump TimeStamp() & " Fin d'ex�cution du client d'origine. oExec.ExitCode=" & oExec.ExitCode
      WScript.Quit oExec.ExitCode
      'WScript.Run "cscript.exe //NoLogo " & WScript.ScriptFullName & argCh & " 2>&1"
      MiseAJourClient = True
   End If
   End Function
Function SetEnvironnement()
   Set oSysEnv = oShell.Environment("PROCESS")
   oSysEnv("TypeWin") = GetTypeWin()
   oSysEnv("ServeurWpkg") = ServeurWpkg
   oSysEnv("Z") = Z
   oSysEnv("WPKGROOT") = Z & "\wpkg"
   oSysEnv("SOFTWARE") = Z & "\packages"
   oSysEnv("DRIVERS")  = Z & "\drivers"
   oSysEnv("PRINTERS") = Z & "\printers"
   oSysEnv("WINLANG")  = "fra"

   If debug Then WPKG_OPTIONS = WPKG_OPTIONS & " /debug:true"
   If logdebug Then WPKG_OPTIONS = WPKG_OPTIONS & " /log_file_path:" & Z & "\wpkg\rapports /logfilePattern:" & ComputerName & ".log"
   If force Then WPKG_OPTIONS = WPKG_OPTIONS & " /force:true"
   If forceinstall Then WPKG_OPTIONS = WPKG_OPTIONS & " /forceinstall:true"
   If nonotify Then WPKG_OPTIONS = WPKG_OPTIONS & " /nonotify:true"
   If norunningstate Then WPKG_OPTIONS = WPKG_OPTIONS & " /norunningstate:true"
   If dryrun Then WPKG_OPTIONS = WPKG_OPTIONS & " /dryrun:true"
   If noforcedremove Then WPKG_OPTIONS = WPKG_OPTIONS & " /noforcedremove:true"
   'Ajout wpkg.js 1.3 (Olikin)
   If noreboot Then WPKG_OPTIONS = WPKG_OPTIONS & " /noreboot:true"
   WPKG_OPTIONS = WPKG_OPTIONS & " /logLevel:" & logLevel
   
   End Function
Function ExecIni
   ' Ex�cution du vbs ini\%ComputerName%.ini  pour initialiser le param�trage
   dim iniFile, iniData
   iniFile = Z & "\wpkg\ini\" & ComputerName & ".ini"
   If fso.FileExists( iniFile) Then
      Set f = fso.OpenTextFile(iniFile, 1)
      iniData = f.ReadAll
      f.Close
      If Len(iniData) > 0 Then
         dump "Fichier d'initialisation trouv� " & iniFile & " (" & Len(iniData) & " octets)."
         Execute iniData
		 dump "logdebug=" & logdebug
      Else
         dump "Fichier " & iniFile & " vide !"
      End If
   End If
   End Function
Function InitLogFile()
   Dim tf
   On Error Resume Next
   If LogMode > 0 Then
      Set tf = fso.OpenTextFile(fLocalLog, LogMode, true)
      If Err.Number > 0 Then 
         print "Erreur ouverture fichier " & fLocalLog
         Err.Clear
      Else
         If WScript.Interactive Then
            tf.WriteLine "-----" + TimeStamp() & " D�marrage de wpkg sur " & ComputerName & " (Mode interactif) -----"
         Else
            tf.WriteLine "-----" + TimeStamp() & " D�marrage de wpkg sur " & ComputerName & " -----"
         End If
         If MsgErrNoRun <> "" Then
            tf.WriteLine MsgErrNoRun
         End If
         tf.Close
      End If
      If logdebug Then
         Set tf = fso.OpenTextFile(fNameLog, LogMode, true)
         If Err.Number > 0 Then 
            print "Erreur ouverture fichier " & fNameLog
            Err.Clear
         Else
            tf.WriteLine "-----" + TimeStamp() & " D�marrage de wpkg sur " & ComputerName & " -----"
            If MsgErrNoRun <> "" Then
               tf.WriteLine MsgErrNoRun
            End If
            tf.Close
         End If
      End If
   End If
   If Err.Number > 0 Then Err.Clear
   End Function
Function dump(msg)
   ' Ecrit sur le terminal
   Dim tf, ErreurEnCours
   ErreurEnCours = 0
   
   If Err.Number > 0 Then 
      ErreurEnCours=Err.Number
      Err.Clear
      If Not NoPrint Then print msg
   Else
      If Not NoPrint Then print msg
   End If
   On Error Resume Next
  
   'WScript.Echo "Set tf = fso.OpenTextFile(" & fLocal & ", 8, true)"
   'Set tf = fso.OpenTextFile(fLocal, 8, true)
   'If Err.Number > 0 Then 
   '   print "Erreur d'ouverture fichier " & fLocal
   '   Err.Clear
   'Else
   '   If ErreurEnCours > 0 Then
   '      tf.Write "Erreur " & ErreurEnCours & vbCrLf
   '   End If
   '   tf.Write msg & vbCrLf
   '   tf.Close
   'End If
   End Function
Function MapZ  
   On Error Resume Next
   Dim Z0, i, oDrives
   Dim MapZok : MapZok=True
   i = 6 ' 60sec maxi (6 * 10)
   Z0=Z
   Do
      print "Map " & Z0 & " " & UNC
      oNet.MapNetworkDrive Z0, UNC
      If Err.Number > 0 Then
         MapZok = False
         print " MapNetworkDrive Err."
         If Tempo Then 
            Wscript.Sleep 1000
         Else
            Wscript.Sleep 10
         End If
         oNet.MapNetworkDrive Z0, UNC
         If Err.Number > 0 Then
            Set oDrives = oNet.EnumNetworkDrives
            For i = 0 to oDrives.Count - 1 Step 2
               print "Lecteur " & oDrives.Item(i) & " = " & oDrives.Item(i+1)
            Next
            print " MapNetworkDrive2 Err "
            'Essai avec une autre unit� apr�s 2 �checs
            If Z0="x:" Then Z0="w:"
            If Z0="y:" Then Z0="x:"
            If Z0="z:" Then Z0="y:"
         Else
            MapZok=True
            print "Map " & Z0 & " " & UNC & " : OK"
         End If
      Else
         MapZok=True
         print "Map " & Z0 & " " & UNC & " : OK"
      End If
      i = i - 1
   Loop Until MapZok Or (i<=0)
   If i<=0 Then 
      MapZ=""
   Else
      MapZ=Z0
   End If
   End Function
Function InfoPoste()
   Set MAC = CreateObject("Scripting.Dictionary") 'Contient Mac et ips associ�es
   Dim i, s, ip
   s = Now & " " & ComputerName
   getMacIp
   For Each addmac in MAC.keys
      s = s & " " & addmac & " ("
      For each ip in MAC(addmac).keys
         If MAC(addmac)(ip) = 1 Then
            If Right(s, 1) <> "(" Then s = s & " "
            s = s & ip
         End If
         If MAC(addmac)(ip) = 2 Then
            ' Masque de sous-reseau
            s = s & "/" & ip
         End If
      Next
      s = s & ")"
   Next
   InfoPoste = s & " " & GetTypeWin()
   End Function
Function RunCmd(Cmd)
   Dim nTest, T0, finOK
   T0 = Timer
   sStdOut=""
   FinExec = False
   
   If fso.FileExists(fLocal) Then
      lenLog = fso.GetFile(fLocal).size
   Else
      lenLog = 0
   End If
   Set oExec = oShell.Exec(cmd)
   nTest = 0
   finOK = False
   Do While (Timer < (T0 + watchDog)) And (Not FinExec)
      If Not ReadOutput() Then
         If nTest > 5 And oExec.Status = 1 Then
            '5 sec apr�s la fin d'ex�cution, s'il n'y a plus rien a lire, on quitte
            finOK = True
            FinExec = True
            Exit Do
         End If
         nTest = nTest + 1
         If Tempo Then 
            Wscript.Sleep 500
         End If
      Else
         nTest = 0
      End If
      Wscript.Sleep 100
   Loop
   If finOK Then
      RunCmd = oExec.ExitCode
   Else
      If Timer < (T0 + watchDog) Then
         RunCmd = -1
      Else
         ' Fin par TimeOut
         RunCmd = -10
      End If
   End If
   End Function
Function ReadOutput()
   Dim s, t, f, fichier
   ReadOutput = False
   'WScript.Echo "dbg: In ReadOutput, lenLog= " & lenLog
   If lenLog > 0 Then
      Set fichier = fso.GetFile(fLocal)
      fichier.Copy "NUL" ' flush
      s = fichier.size
      If s > lenLog Then
         'Lecture des nouveaux octets arriv�s dans le fichier pour les afficher
         Set f = fichier.OpenAsTextStream(1) ' ForReading
         f.Skip lenLog
         t = f.Read( s - lenLog)
         f.Close
         sStd = sStd & t
         If PrintOutput Then WScript.StdOut.Write t
         lenLog = s
         ReadOutput = True
      End If
   End If
   End Function
Function ReadOutputBAK()
   Dim poub, s, printNextLigne
   printNextLine = True
   ReadOutput = False
   Do Until oExec.StdOut.AtEndOfStream And (Not FinExec)
      s = oExec.StdOut.Read(1)
      If s <> vbCr Then
         sStdOut = sStdOut & s
         If oExec.StdOut.AtEndOfLine Then
            
            'If Left(sStdOut, 1) = vbLf Then sStdOut = Mid(sStdOut, 2)
            'sStdOut = oem2ansi(sStdOut)
            sStd = sStd & sStdOut
            If printOutput Then
               If (sStdOut = vbCrLf) And Not printNextLine Then 
                  printNextLine = True
               Else
                  If Left(sStdOut, 2) = vbCrLf Then sStdOut = Mid(sStdOut, 3)
                  WScript.Echo sStdOut
                  printNextLine = False
               End IF
            End If
            If  sStdOut = "L'ex�cution du script a pris fin." Then
               FinExec = True
            End If
            sStdOut = ""
         End If
      Else
         sStdOut = sStdOut & s
      End If
      ReadOutput = True
   Loop
   'WScript.Echo "Dbg: oExec.Status=" & oExec.Status & ", oExec.StdErr.AtEndOfStream=" & oExec.StdErr.AtEndOfStream
   End Function
Function UpdateFile(src, dst)
   ' Met � jour le fichier dst � partir de src et retourne 
   '  0 si dst est plus r�cent (pas de maj)
   '  1 si src a �t� copi� en dst
   ' -1 si src absent ou err copie
   On Error Resume Next
   Dim retour : retour=0
   Dim  fSrc, fDst
   Dim  doCopy : doCopy=false
   Dim dateSrc, dateDst
   
   If Not fso.FileExists(src) Then
      UpdateFile = -1
   Else 
      Set fSrc = fso.GetFile(src)
      dateSrc = fSrc.DateLastModified
      If Not fso.FileExists(dst) Then
         doCopy=true
      Else
         Set fDst = fso.GetFile( dst )
         dateDst = fDst.DateLastModified
         ' print "dateSrc=" & dateSrc & ", dateDst=" & dateDst & ", dateDst>=dateSrc = " & (dateDst >= dateSrc)
         If dateDst >= dateSrc Then
            ' Dst est � jour 
            UpdateFile = 0
         Else
            doCopy=true
         End If
      End If
      If doCopy Then
         ' copie de src dans dst
         fso.CopyFile src, dst, true ' Copie avec �ventuellemnet �crasement
         If Err.Number > 0 Then 
            UpdateFile = -1
            Err.Clear
         Else
            UpdateFile = 1
         End If
      End If
   End If
   End Function
Function InitOEM
   Dim i
   oem=array( &HC7, &HFC, &HE9, &HE2, &HE4, &HE0, &HE5, &HE7, &HEA, &HEB, &HE8, &HEF, &HEE, &HEC, &HC4, &HC5, &HC9, &HE6, &HC6, &HF4, &HF6, &HF2, &HFB, &HF9, &HFF, &HD6, &HDC, &HF8, &HA3, &HD8, &HD7, &H83, &HE1, &HED, &HF3, &HFA, &HF1, &HD1, &HAA, &HBA, &HBF, &HAE, &HAC, &HBD, &HBC, &HA1, &HAB, &HBB, &HA6, &HA6, &HA6, &HA6, &HA6, &HC1, &HC2, &HC0, &HA9, &HA6, &HA6, &H2B, &H2B, &HA2, &HA5, &H2B, &H2B, &H2D, &H2D, &H2B, &H2D, &H2B, &HE3, &HC3, &H2B, &H2B, &H2D, &H2D, &HA6, &H2D, &H2B, &HA4, &HF0, &HD0, &HCA, &HCB, &HC8, &H69, &HCD, &HCE, &HCF, &H2B, &H2B, &HA6, &H5F, &HA6, &HCC, &HAF, &HD3, &HDF, &HD4, &HD2, &HF5, &HD5, &HB5, &HFE, &HDE, &HDA, &HDB, &HD9, &HFD, &HDD, &HAF, &HB4, &HAD, &HB1, &H3D, &HBE, &HB6, &HA7, &HF7, &HB8, &HB0, &HA8, &HB7, &HB9, &HB3, &HB2, &HA6, &HA0)
   For i = 128 To 255
      oem(i - 128) = Chr(oem(i-128))
   Next
   End Function
Function oem2ansi(Texte) 'Conversion OEM -> ANSI
   dim i, s(), l, c, a
   L = Len(Texte)
   Redim s(L)
   For i = 1 To L
      c = Mid(Texte, i, 1)
      a = asc(Mid(Texte, i, 1)) - 128
      If a > 0 Then
         s(i) = oem(a)
      Else
         s(i) = c
      End If
   Next
   oem2ansi = Join(s, "")
   End Function
Function print (a)
   Dim li
   li = TimeStamp() & " " & a
   If (Err.Number > 0) Then
      li = li & vbCrLf & "  Err " & Err.Number & " " & Err.Description & " (" & Err.Source & ")" & vbCrLf
      Err.Clear
   End If
   WScript.Echo li
   End Function
Function TimeStamp() ' Retourne la date formatt�e pour le fichier de Log ou XML (format : '2006-09-25 16:58:37' )
   Dim n
   n = Now
   TimeStamp = Year(n) & "-" & Right("00"&Month(n), 2) & "-" & Right("00"&Day(n), 2) & " " & Right("00"&Hour(n), 2) & ":" & Right("00"&Minute(n), 2) & ":" & Right("00"&Second(n), 2)
   End Function
Function DumpError
   print "Err=" & Err.Number & " " & Err.description
   Err.Clear
   On Error Resume Next
   End Function
Function getMacIp()
   Dim strIPAddress, strIPSubnet
   Dim objWMI : Set objWMI = GetObject("winmgmts:")
   Dim objNetworkAdapters : Set objNetworkAdapters = objWMI.ExecQuery("select * from Win32_NetworkAdapterConfiguration where IPEnabled = 1")
   Dim addmac, ip
   Dim objAdapter
   For Each objAdapter In objNetworkAdapters
      addmac = objAdapter.MacAddress
      Set MAC(addmac) = CreateObject("Scripting.Dictionary")
      For Each strIPAddress in objAdapter.IPAddress
         MAC(addmac).Add strIPAddress, 1
      Next
      For Each strIPSubnet in objAdapter.IPSubnet
        MAC(addmac)(strIPSubnet) = 2
      Next
   Next
   If MAC.Count >=1 Then
      getMacIp = 1
   Else
      getMacIp = 0
   End If
   Set objWMI = Nothing
   Set objAdapter = Nothing
   Set objNetworkAdapters = Nothing
   End Function
Function LireRegistre(cle)
   Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
   Dim bKey
   On Error resume Next
   bKey = WshShell.RegRead(cle)
   If Err.Number <> 0 Then 
      LireRegistre = ""
      Err.Clear
   Else
      LireRegistre = bKey
   End If
   'On Error Goto 0
End Function

Function GetTypeWin()
   Dim TypeWin
   Dim ProductName, CurrentVersion, ServicePack, CurrentBuildNumber
   ProductName = LireRegistre("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName")
   CurrentVersion = LireRegistre("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentVersion")
   ServicePack = LireRegistre("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CSDVersion")
   CurrentBuildNumber = LireRegistre("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuildNumber")
   If InStr(ProductName, "Windows XP") > 0 Then
      TypeWin = "winxp"
      If InStr(ServicePack, "Pack 3") Then 
         TypeWin = TypeWin & "sp3"
      End If
      If InStr(ServicePack, "Pack 2") Then 
         TypeWin = TypeWin & "sp2"
      End If
      If InStr(ServicePack, "Pack 1") Then 
         TypeWin = TypeWin & "sp1"
      End If
	Else
		If InStr(ProductName, "Windows 2000") > 0 Then
		      TypeWin = "win2k"
		      If InStr(ServicePack, "Pack 4") Then 
		         TypeWin = TypeWin & "sp4"
		      End If
		      If InStr(ServicePack, "Pack 3") Then 
		         TypeWin = TypeWin & "sp3"
		      End If
		      If InStr(ServicePack, "Pack 2") Then 
		         TypeWin = TypeWin & "sp2"
		      End If
		      If InStr(ServicePack, "Pack 1") Then 
		         TypeWin = TypeWin & "sp1"
		      End If
		Else
			  TypeWin = ProductName
		End If
   End If
   GetTypeWin = TypeWin
End Function

Function TooltipInit()
	' Mise en place des tooltips avec les actions suivantes:
	'0. Efface le fichier de log au d�but de l'ex�cution de wpkg pour �viter que celui-ci ne soit trop important � terme.
	'1. copie du fichier wpkg-msg.exe dans %Z%\wpkg\tools\tooltip\wpkg-msg.exe vers %windir%
	'2. copie en local de %Z%\wpkg\tools\tooltip\tooltip.exe vers %allusersprofile%\Menu D�marrer\Programmes\D�marrage
	' Des tests doivent permettre une ex�cution instantan�e de cette fonction en dehors de la mise en place initiale.
	'Dim oFSO
	'Set oFSO = CreateObject("Scripting.FileSystemObject")

	If fso.FileExists(MSGlog) Then
		fso.DeleteFile MSGlog,True
	End If
	
	If Not fso.FileExists(MSGfile) Then
		' on copie le wpkg-msg.exe vers %windir%
		'MsgBox("copie de " & Z & "\wpkg\tools\tooltip\wpkg-msg.exe vers " & WinDir)
		fso.CopyFile Z & "\wpkg\tools\tooltip\wpkg-msg.exe", WinDir & "\", True
	End If
	
	If Not fso.FileExists(TOOLTIPfile) Then
		'MsgBox(TOOLTIPfile & "absent")
		fso.CopyFile Z & "\wpkg\tools\tooltip\tooltip.exe", Dest , True
	End If
End Function  

Function TooltipEnd()
	' Ajoute "FIN WPKG" au fichier de log MSGlog => met fin � l'ex�cution de tooltip.exe dans la session de l'utilisateur logu�.
	Const ForAppend = 8
	Dim f
	'Msgbox("MSGlog," & ForAppend & " , True")
	Set f = fso.OpenTextFile(MSGlog, ForAppend, True)
	f.WriteLine("FIN WPKG")
	' on fait une pause de 2 secondes pour permettre � tooltip.exe d'avoir le temps de lire "FIN WPKG", puisqu'il lit le fichier toutes les secondes.
	Wscript.Sleep 2000
	' on �crit une autre ligne � la fin de wpkg-msg.txt afin d'�viter le probl�me "un user ouvre la session avant que wpkg ne soit lanc�" qui provoquerait imm�diatement l'arr�t de tooltip.exe
	f.WriteLine("")
	f.Close
End Function 

Function TooltipDelete()
	' Suppression des tooltips : pr�vu pour nettoyer les OS Windows Server de Caen
	If fso.FileExists(MSGlog) Then
		fso.DeleteFile MSGlog, True
	End If
	If fso.FileExists(MSGfile) Then
		fso.DeleteFile MSGfile, True
	End If
	If Not fso.FileExists(TOOLTIPfile) Then
		fso.DeleteFile TOOLTIPfile, True
	End If
End Function  
