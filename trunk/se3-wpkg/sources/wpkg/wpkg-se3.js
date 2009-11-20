/*******************************************************************************
 *
 *  Version de wpkg.js modifiÈe pour SambaEdu3
 *  Supporte l'option  /logdebug pour afficher en temps rÈel les infos debug dans le fichier de log du serveur
 *  et indique les sorties de l'exÈcution des scripts d'install remove upgrade en mode /debug
 *
 *  ##  $Id$ ##
 *
 * WPKG 0.9.10 - Windows Packager
 * Copyright 2003 Jerry Haltom
 * Copyright 2005-2006 Tomasz Chmielewski <tch (at) wpkg . org>
 * Copyright 2005 Aleksander Wysocki <papopypu (at) op . pl>
 *
 * Please report your issues to the list on http://wpkg.org/
 *
 *
 * Command Line Switches
 *
 * /log:<file>
 *     Copy output of exec cmd in specified file
 *
 * /profile:<profile>
 *     Forces the name of the current profile. If not specified, the profile is
 *     looked up using hosts.xml.
 *
 * /base:<path>
 *     Sets the local or remote path to find the settings files.
 *
 * /query:<option>
 *     Displays a list of packages matching the specified criteria. Valid
 *     options are:
 *
 *     a - all packages
 *     i - packages that are currently installed on the system
 *     x - packages that are not currently installed on the system
 *     u - packages that can be upgraded
 *
 * /show:<package>
 *     Displays a summary of the specified package, including it's state.
 *
 * /install:<package>
 *     Installs the specified package on the system.
 *
 * /remove:<package>
 *     Removes the specified package from the system.
 *
 * /upgrade:<package>
 *     Upgrades the already installed package on the system.
 *
 * /synchronize
 *     Synchronizes the current program state with the suggested program state
 *     of the specified profile. This is the action that should be called at
 *     system boot time for this program to be useful.
 *
 * /quiet
 *     Uses the event log to record all error/status output. Use this when
 *     running unattended.
 *
 * /lang:<lan>
 *     Language : enu, fra (default : fra)
 *
 * /nonotify
 *     Logged on users are not notified about impending updates.
 *
 * /noreboot
 *     System does not reboot regardless of need.
 *
 * /rebootcmd:<option>
 *     Use the specified boot command, either with full path or
 *     relative to location of wpkg.js
 *     Specifying "special" as option uses tools\psshutdown.exe
 *     from www.sysinternals.com - if it exists - and a notification loop
 *
 * /force
 *     Uses force when performing actions (does not honour wpkg.xml).
 *
 * /forceinstall
 *     Forces installation over existing packages.
 *
 * /norunningstate
 *     Do not export the running state to the registry.
 *
 * /quitonerror
 *     Quits execution if installation of any package was unsuccessful
 *     (default: install next package and show the error summary).
 *
 * /debug
 * /verbose
 *     Prints some debugging info.
 *
 * /logdebug
 *     Affiche les infos debug dans le fichier wpkg\rapport\%computername%.log
 *
 * /dryrun
 *     Does not execute any action. Assumes /debug on.
 *
 * /help
 *     Shows this message.
 *
 ******************************************************************************/

/*******************************************************************************
 *
 * Global variables
 *
 ******************************************************************************/

if (true) { // variables globales
    // script wide properties
    var force = false;        // when true: doesn't consider wpkg.xml but checks existence of packages.
    var forceInstall = false; // forces instalation over existing packages

    var quitonerror = false;

    var err_summary = "";
    var debug = false;
    var dryrun = false;

    var quiet = false;
    var profile;
    var host;
    var base;

    var packages_file;
    var profiles_file;
    var settings_file;
    var hosts_file;

    var packages;
    var profiles;
    var settings;
    var hosts;

    var nonotify = false;
    var noreboot = false;
    var exportRunningState = true;    
    var rebootCmd = "standard";

    var packagesDocument;
    var profilesDocument;
    var settingsDocument;
    var hostsDocument;


    var was_notified = false;

    // environment variables to apply to all packages
    var global_env_vars;

    // names of remote configuration files
    // these must be located in the directory specified by the /base switch, or by
    // default, the current directory

    var packages_file_name = "packages.xml";
    var profiles_file_name = "profiles.xml";
    var hosts_file_name    = "hosts.xml";

    // name of the local settings file, which is located in the System32 folder of
    // the current system

    var settings_file_name = "wpkg.xml";

    var sRegPath = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall";
    // here we indicate our running state
    var sRegWPKG_Running = "HKLM\\Software\\WPKG\\running";

    //leb
    // localization of messages send to logged on user
    // Supported languages :
    // - enu : English
    // - fra : French (default).

    var lang = "fra";

    // Convertion OEM -> ANSI
    var oemchar = Array();
    var oemStr0 = "ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ";
    var oemStr  = "«¸È‚‰‡ÂÁÍÎËÔÓÏƒ≈…Ê∆ÙˆÚ˚˘ˇ÷‹¯£ÿ◊É·ÌÛ˙Ò—™∫øÆ¨Ωº°´ª¶¶¶¶¶¡¬¿©¶¶++¢•++--+-+„√++--¶-+§– À»iÕŒœ++¶_¶ÃØ”ﬂ‘“ı’µ˛ﬁ⁄€Ÿ˝›Ø¥≠±=æ∂ß˜∏∞®∑π≥≤¶†";
    for (i=0; i<128; i++) {
        oemchar[oemStr0.charAt(i)] = oemStr.charAt(i);
    }
    oemStr0 = "";
    // conversion ANSI -> OEM 
    var Oem = new Array(); initansi2oem();
    var logdebug = false, logFileName="", loglocal=false, loglocalFile="";
    var fso;
    var WshShell;
    var lStdOut = '';
    var watchdog;
    var nozombie=false; // Par dÈfaut les zombies restent inscript dans %WinDir%\system32\wpkg.xml

    /** path where log-files are stored
     * Defaults to "%TEMP%" if empty.
     */
    var log_file_path = "%TEMP%";

    /** true si une cmd est en cours d'exÈcution (utilisÈ pour Èviter les saut de ligne dans le dump) */
    var inExecCmd = false;
    var msgLog = ""; // tampon ‡ mettre dans le fichier de log
}
/*******************************************************************************
 *
 * Program execution
 *
 ******************************************************************************/

// call the main function with arguments.
try {
    main(WScript.Arguments);
} catch (e) {
    error(e.description);
    notifyUserFail();
    exit(2);
}

function main(argv) {
    /**
     * Processes command lines and decides what to do.
     */

    // get special purpose argument lists
    var argn = argv.Named;
    var argu = argv.Unnamed;

    // defines language of messages send to logged on user
    if (argn("lang") != null) {
        lang = argn("lang");
    }
    
    // process property named arguments that set values
    if (isArgSet(argv, "/debug") || isArgSet(argv, "/verbose")) {
        debug = true;
    }
    
    // process property named arguments that set values
    if (isArgSet(argv, "/dryrun")) {
        dryrun = true;
        debug = true;
    }
    
    // retrait des zombies
    if (isArgSet(argv, "/nozombie")) {
        nozombie = true;
    }

    // if the user is wanting command help, give it to him
    if (isArgSet(argv, "/help")) {
        showUsage();
        exit(0);
    }

    // process property named arguments that set values
    if (isArgSet(argv, "/quiet")) {
        quiet = true;
    }

    // if the user passes /nonotify, we don't want to notify the user
    if (isArgSet(argv, "/nonotify")) {
        nonotify = true;
    }

    // if the user passes /noreboot, we don't want to reboot
    if (isArgSet(argv, "/noreboot")) {
        noreboot = true;
    }

    // process property named arguments that set values
    if (isArgSet(argv, "/force")) {
        force = true;
    }

    // process property named arguments that set values
    if (isArgSet(argv, "/quitonerror")) {
        quitonerror = true;
    }
    
    // process property named arguments that set values
    if (isArgSet(argv, "/forceinstall")) {
        forceInstall = true;
    }
    
    if (argn("rebootcmd") != null) {
        rebootCmd=(argn("rebootcmd"));
    }
    dinfo("La commande de reboot est '" + rebootCmd +"'.");
    
    // want to export the state of WPKG to registry?
    if (isArgSet(argv, "/norunningstate")) {
        exportRunningState = false;
        //dinfo("exportRunningState = false");
    } else {
    // indicate that we are running
        setRunningState("true");
    }
    // will use the fso a bit
    fso = new ActiveXObject("Scripting.FileSystemObject");
    // set host name
    var WshNetwork = WScript.CreateObject("WScript.Network");
    host = WshNetwork.ComputerName.toLowerCase();
    WshShell = new ActiveXObject("WScript.Shell");
    
    if (argn("base") != null) {
        var base = argn("base");
        base = fso.GetAbsolutePathName(base);
    } else {
        // use the executing location of the script as the default base path
        var path = WScript.ScriptFullName;
        base = fso.GetParentFolderName(path);
    }
    
    if (isArgSet(argv, "/logdebug")) {
        debug = true;
        logdebug = true;
        logFileName = base + "\\rapports\\" + host + ".log";
    }
    loglocalFile = WshShell.ExpandEnvironmentStrings("%WinDir%") + "\\wpkg.log"
        
    dinfo("RÈpertoire de base: " + base + ".");
    // dinfo("logdebug=" + logdebug + ", logFileName=" + logFileName);

    // append the settingsfile names to the end of the base path
    packages_file = fso.BuildPath(base, packages_file_name);
    profiles_file = fso.BuildPath(base, profiles_file_name);
    hosts_file = fso.BuildPath(base, hosts_file_name);

    // our settings file is located in System32
    var SystemFolder = 1;
    var settings_folder = fso.GetSpecialFolder(SystemFolder);
    settings_file = fso.BuildPath(settings_folder, settings_file_name);


    // load packages and profiles
    hosts = loadXml( hosts_file, createXsl( base, "hosts" ) );
    profiles = loadXml( profiles_file, createXsl( base, "profiles" ) );
    packages = loadXml( packages_file, createXsl( base, "packages" ) );


    if (force  &&  isArgSet(argv, "/synchronize")) {
        dinfo("Controle des paquets installÈs sans tenir compte de l'Ètat connu du client.");

        settings = createXml("wpkg");

        fillSettingsWithInstalled(settings, packages);
        saveXml(settings, settings_file);
    } else {
        // load or create settings file
        if (!fso.fileExists(settings_file)) {
            dinfo("Le fichier local wpkg.xml n'existe pas. CrÈation d'un nouveau fichier.");

            settings = createXml("wpkg");
            saveXml(settings, settings_file);
        } else {
            settings = loadXml(settings_file);
        }
    }
/*
    if( debug ) {
        var hst = hosts.selectNodes( "host" );
        info( "Hosts file contains " + hst.length + " hosts:" );
        var dsds = 0;
        for( dsds = 0; dsds < hst.length; ++dsds ) {
            info( hst[dsds].getAttribute( "name" ) );
        }
        info( "" );
    }
    
    if (debug) {
        var packs = settings.selectNodes("package");
        info("settings file contains " + packs.length + " packages:");
        var dsds=0;
        for (dsds=0; dsds<packs.length; ++dsds) {
            if (null != packs[dsds]) {
               info(packs[dsds].getAttribute("id"));
            }
        }
        info("");
    }

    if (debug) {
        var packs = packages.selectNodes("package");
        info("packages file contains " + packs.length + " packages:");
        var dsds=0;
        for (dsds=0; dsds<packs.length; ++dsds) {
            if (null != packs[dsds]) {
               info(packs[dsds].getAttribute("id"));
            }
        }
        info("");
    }

    if( debug ) {
        var profs = profiles.selectNodes( "profile" );
        info( "profiles file contains " + profs.length + " profiles:" );
        var dsds=0;
        for (dsds=0; dsds<profs.length; ++dsds) {
            if (null != profs[dsds]) {
               info(profs[dsds].getAttribute("id"));
            }
        }
        info("");
    }
*/    

    // set the profile from either the command line or the hosts file
    if (argn("profile") != null) {
        profile = argn("profile");
    } else {
        profile = retrieveProfile(hosts, host);

        if (null == profile) {
            throw new Error("Profil absent pour le poste " + host + ".");
        }
    }

    dinfo("Using profile: " + profile);

    
    // check for existance of the current profile
    if (profiles.selectSingleNode("profile[@id='" + profile + "']") == null) {
        throw new Error("Le profil " + profile + " n'existe pas.");
    }
    
    // process command line arguments to determine course of action
    
    if (argn("query") != null) {
        var arg = argn("query").slice(0,1);
        if (arg == "a") {
            queryAllPackages();
        } else if (arg == "i") {
            queryInstalledPackages();
        } else if (arg == "x") {
            queryUninstalledPackages();
        } else if (arg == "u") {
            queryUpgradablePackages();
        }
        exit(0);
    } else if (argn("show") != null) {
        queryPackage(argn("show"));
    } else if (argn("install") != null) {
        installPackageName(argn("install"));
        exit(0);
    } else if (argn("remove") != null) {
        removePackageName(argn("remove"));
        exit(0);
    } else if (argn("upgrade") != null) {
        upgradePackageName(argn("upgrade"));
        exit(0);
    } else if (isArgSet(argv, "/synchronize")) {
        synchronizeProfile();
        exit(0);
    } else {
        throw new Error("Aucune action demandÈe.");
    }
}

function showUsage() {
    /**
     * Displays command usage.
     */
    var message = "";
    message += "WPKG 0.9.10 - Windows Packager pour SambaEdu\r\n";
    message += "Copyright 2004 Jerry Haltom\r\n";
    message += "Copyright 2005-2006 Tomasz Chmielewski <tch (at) wpkg . org>\r\n";
    message += "Copyright 2005 Aleksander Wysocki <papopypu (at) op . pl>\r\n";
    message += "Copyright 2007 Jean Le Bail <jean.lebail (at) etab . ac-caen . fr>\r\n";
    message += "\r\n";
    message += "Please report your issues to the list on http://wpkg.org/\r\n";
    message += "\r\n";
    message += "\r\n";
    message += "/profile:<profile>\r\n";
    message += "    Force le nom du profil ‡ utiliser. Si aucun profil n'est indiquÈ\r\n";
    message += "    consulte le fichier hosts.xml.\r\n";
    message += "\r\n";
    message += "/lang:<language>\r\n";
    message += "    DÈfinit la langue ‡ utiliser pour les messages envoyÈ ‡ l'utilisateur logguÈ.\r\n";
    message += "    Leur valeurs de lang acceptÈes sont:\r\n";
    message += "    eng - anglais \r\n";
    message += "    fra - franÁais (valeur par dÈfaut)\r\n";
    message += "\r\n";
    message += "/base:<path>\r\n";
    message += "    DÈfinit le rÈpertoire contenant les fichiers de configuration.\r\n";
    message += "\r\n";
    message += "/query:<option>\r\n";
    message += "    Affiche une liste de paquets vÈrifiant les critÈres choisis. Les options valides sont :\r\n";
    message += "\r\n";
    message += "    a - tous les paquets\r\n";
    message += "    i - paquets installÈs sur le poste\r\n";
    message += "    x - paquets non installÈs sur le poste\r\n";
    message += "    u - paquets pouvant Ítre mis ‡ jour\r\n";
    message += "\r\n";
    message += "/show:<package>\r\n";
    message += "    Affichie un rÈsumÈ de l'Ètat du paquet indiquÈ.\r\n";
    message += "\r\n";
    message += "/install:<package>\r\n";
    message += "    Installe le paquet indiquÈ sur le poste.\r\n";
    message += "\r\n";
    message += "/remove:<package>\r\n";
    message += "    DÈsintalle le paquet indiquÈ.\r\n";
    message += "\r\n";
    message += "/upgrade:<package>\r\n";
    message += "    Met ‡ jour le paquet dÈj‡ prÈsent sur le poste.\r\n";
    message += "\r\n";
    message += "/synchronize\r\n";
    message += "    Synchronise tous les paquets conformÈment aux demandes\r\n";
    message += "\r\n";
    message += "/quiet\r\n";
    message += "    Utilise le gestionnaire d'ÈvÈnements pour enregistrer les log.\r\n";
    message += "\r\n";    
    message += "/nonotify\r\n";
    message += "   Pas de message envoyÈ ‡ l'utilisateur logguÈ sur le poste.\r\n";
    message += "\r\n";
    message += "/noreboot\r\n";
    message += "   Pas de redÈmarrage du poste mÍme si une application le demande.\r\n";
    message += "\r\n";
    message += "/rebootcmd:<filename>\r\n";
    message += "   Utiliser la commande de redÈmarrage indiquÈe\r\n"
    message += "\r\n";
    message += "/force\r\n";
    message += "   Force les actions ‡ Ítre exÈcutÈes.\r\n";
    message += "\r\n";
    message += "/forceinstall\r\n";
    message += "   Force l'installation des paquets par dessus les installations existantes.\r\n";
    message += "\r\n";
    message += "/norunningstate\r\n";
    message += "   N'indique pas l'Ètat du client (hklm\\software\\wpkg\\running=[true|false]) dans la base de registre.\r\n";
    message += "\r\n";
    message += "/quitonerror\r\n";
    message += "   Stoppe l'exÈcution dËs que l'installation d'un paquet Èchoue\r\n";
    message += "   (par dÈfaut: installe le paquet suivant aprËs affichage de l'erreur).\r\n";
    message += "\r\n";
    message += "/debug\r\n";
    message += "/verbose\r\n";
    message += "    Affiche des infos de dÈbuggage.\r\n";
    message += "\r\n";
    message += "/logdebug\r\n";
    message += "    Copie en temps rÈel les log dans " + "%Z%\\wpkg\\rapports\\" + WScript.CreateObject("WScript.Network").ComputerName.toLowerCase() + ".log" + ".\r\n";
    message += "\r\n";
    message += "/dryrun\r\n";
    message += "    N'exÈcute aucune action. Suppose l'option /debug.\r\n";
    message += "\r\n";
    message += "/help\r\n";
    message += "    Affiche ce message d'aide.\r\n";
    alert(message);
}

function isArgSet(argv, arg) {
    /**
     * Scans an argument vector for an argument "arg". Returns true if found, else
     * false
     */
    // loop over argument vector and return true if we hit it
    for (var i = 0; i < argv.length; i++) {
        if (argv(i) == arg) {
            return true;
        }
    }
    // otherwise, return false
    return false;
}

function notifyUserStart() {
    /**
     * Sends a message to the system console notifying of impending action.
     */
    if (!was_notified) {
        var msg = "";
        if (lang == "fra" ) {
            msg += "L'utilitaire d'installation d'applications est en train ";
            msg += "de mettre ‡ jour votre ordinateur.\\n ";
            msg += "Assurez-vous que vous avez enregistrÈ tous vos documents car ";
            msg += "un redÈmarrage pourrait s'avÈrer nÈcessaire.\\n\\n";
            msg += "Merci.";
        } else {
            msg += "The automated software installation utility has or is ";
            msg += "currently applying software updates to your system. Please ";
            msg += "check the time shown at the beginning of this message to ";
            msg += "determine if it is out of date. If not, please save all your ";
            msg += "open documents, as the system might require a reboot. If so, ";
            msg += "the system will be rebooted with no warning when installation ";
            msg += "is complete. Thank you.";
        }
        was_notified = true;
        
        try {
            notify(msg);
        } catch (e) {
            throw new Error(0, "Echec lors de l'envoi du message pour indiquer que le client dÈmarre les mises ‡ jour. " + e.description);
        }
    }
}

function notifyUserStop() {
    /**
     * Sends a message to the system console notifying them that all action is
     * complete.
     */
    var msg = "";
    if (lang == "fra" ) {
        msg += "L'utilitaire d'installation d'applications a terminÈ les mises ‡ jour.\\n";
        msg += "Le redÈmarrage du poste n'a pas ÈtÈ nÈcessaire.\\n";
        msg += "Toutes les mises ‡ jour ont ÈtÈ effectuÈes.";
    } else {
        msg += "The automated software installation utility has completing ";
        msg += "installing or updating software on your system. No reboot was ";
        msg += "necessary. All updates are complete.";
    }
    
    try {
        notify(msg);
    } catch (e) {
        error("Echec lors de l'envoi du message pour indiquer la fin de l'exÈcution du client.");
    }
}


function notifyUserFail() {
    /**
     * Sends a message to the system console notifying the user that installation
     * failed.
     */
    var msg = "";
    if (lang == "fra" ) {
        msg += "L'installation de l'application a ÈchouÈ.";
    } else {
        msg += "The software installation has failed.";
    }
    try {
        notify(msg);
    } catch (e) {
        error("Echec lors de l'envoi du message : L'installation de l'application a ÈchouÈ..");
    }
}

function synchronizeProfile() {
    /**
     * Synchronizes the current package state to that of the specified profile,
     * adding, removing or upgrading packages.
     */
    // accquire packages that should be present
    var packageArray = getAvailablePackages();

    dinfo("Nombre de paquets disponibles: " + packageArray.length);

    
    // grab currently installed package nodes
    var installedPackages = settings.selectNodes("package");
    var removablesArray = new Array();
    
    // loop over each installed package and check whether it still applies
    for (var i = 0; i < installedPackages.length; i++) {
        var installedPackageNode = installedPackages(i);
        dinfo("Paquet installÈ: '" + installedPackageNode.getAttribute("id") + "'");
        
        // search for the installed package in available packages
        var found = false;
        for (j in packageArray) {
            //dinfo("testing available package: " + packageArray[j].getAttribute("id"));


            if (packageArray[j].getAttribute("id") ==
                installedPackageNode.getAttribute("id")) {
                dinfo("Le paquet: '" + installedPackageNode.getAttribute("id") + "' est disponible.");

                found = true;
                break;
            }
        }
        
        // if package is no longer present, mark for remove
        if (!found) {
            dinfo("Le paquet: '" + installedPackageNode.getAttribute("id") + "' est ajoutÈ ‡ la liste ‡ SUPPRIMER.");
            removablesArray.push(installedPackageNode);
        }
    }

    var allPackagesArray = getAllPackages();
    dinfo("Nombre de paquets ‡ supprimer: " + removablesArray.length); 
    // check for zombies, then really remove trashed packages
    for (i in removablesArray) {
        var packageName = removablesArray[i].getAttribute("id");
        var found = false;
        dinfo("ContrÙle de '" + packageName + "' pour la suppression.");
        for (j in allPackagesArray) {
            if (allPackagesArray[j].getAttribute("id") == packageName) found = true;
        }
        if (found) {
            dinfo("ContrÙle du paquet '" + packageName + "' ‡ supprimer effectuÈe.");
            notifyUserStart();
            removePackage(removablesArray[i]);
            info("==============================================================="); // saut ligne entre les paquets ‡ dÈsinstaller
        } else {
            dinfo("'" + packageName + "' est installÈ mais n'est plus dans la base de donnÈes : c'est un Zombie.");
            if (nozombie) {
                // Suppression du paquet de la base de donnÈe
                dinfo("Suppression du zombie '" + packageName + "' de la base de donnÈe.");
                settings.removeChild(settings.selectSingleNode("package[@id='" + packageName + "']"));
                saveXml(settings, settings_file);
            }
            if (quitonerror) {
                throw new Error("Erreur d'installation lors de la synchronisation du paquet '" + packageName + "'." +
                    "\r\n" + "Le paquet est installÈ mais n'est plus dans la base de donnÈes : c'est un Zombie.");
            } else {
                err_summary += "\r\nPaquet: " + packageName + "\r\n  " + "Le paquet est installÈ mais n'est plus dans la base de donnÈes : c'est un Zombie.";
            }
            
        }
    }
    
    // create a native jscript array to do the sorting on
    var sortedPackages = new Array(packageArray.length);
    for (var i = 0; i < packageArray.length; i++) {
        sortedPackages[i] = packageArray[i];
    }
    
    // classic bubble-sort algorithm on the "priority" attribute
    var len = packageArray.length;
    for (var i = 0; i < len - 1; i++) {
        for (var j = 0; j < len - 1 - i; j++) {
            var pri1;
            var pri2;
            var szpri1 = sortedPackages[j].getAttribute("priority");
            var szpri2 = sortedPackages[j + 1].getAttribute("priority");
            
            // if a priority is not set, we assume 0
            
            if (szpri1 == null) {
                pri1 = 0;
            } else {
                pri1 = parseInt(szpri1);
            }
            
            if (szpri2 == null) {
                pri2 = 0;
            } else {
                pri2 = parseInt(szpri2);
            }
            
            // if the priority of the first one in the list exceeds the second,
            // swap the packages
            if (pri1 < pri2) {
                var tmp = sortedPackages[j];
                sortedPackages[j] = sortedPackages[j + 1];
                sortedPackages[j + 1] = tmp;
            }
        }
    }
    
    // sorting complete
    packageArray = sortedPackages;
    
    // loop over each available package and determine whether to install or
    // upgrade
    for (var i = 0; i < packageArray.length; i++) {
        var packageNode = packageArray[i];
        var packageId   = packageNode.getAttribute("id");
        var packageName = packageNode.getAttribute("name");
        var packageRev  = parseInt(packageNode.getAttribute("revision"));

        var executeAttr = packageNode.getAttribute("execute");
        var notifyAttr  = packageNode.getAttribute("notify");    
    
        // search for the package in the local settings
        var installedPackage = settings.selectSingleNode("package[@id='" +
            packageId + "']");
            
        if (executeAttr == "once") {
            if ((null == installedPackage) | ((null != installedPackage) && (parseInt(installedPackage.getAttribute("revision")) < packageRev )) ) {
                try {
                    if (notifyAttr != "false") {
                        notifyUserStart();
                    }
                    executeOnce(packageNode);
                    info("==============================================================="); // saut ligne entre les paquets ‡ installer
                } catch (e) {
                    if (quitonerror) {
                        throw new Error("Erreur d'installation lors de la synchronisation du paquet " +
                            packageName + "." +
                            "\r\n" + e.description);
                    } else {
                        err_summary += "\r\nPaquet: '" + packageName + "'\r\n  " + e.description; 
                    }
                }
            }
        } else if (executeAttr == "always") {
           // do not look if package is installed
            try {
                if (notifyAttr != "false") {
                    notifyUserStart();
                }
                executeOnce(packageNode);
                info("==============================================================="); // saut ligne entre les paquets ‡ installer
            } catch (e) {
                if (quitonerror) {
                    throw new Error("Erreur d'installation lors de la synchronisation du paquet " +
                        packageName + "." +
                        "\r\n" + e.description);
                } else {
                    err_summary += "\r\nPaquet: '" + packageName + "'\r\n  " + e.description; 
                }
            }
        } else {
            // if the package is not installed, install it
            if (installedPackage == null) {
                try {
                    if (notifyAttr != "false") {
                        notifyUserStart();
                    }
                    installPackage(packageNode);
                    info("==============================================================="); // saut ligne entre les paquets ‡ installer
                } catch (e) {
                    if (quitonerror) {
                        throw new Error("Erreur d'installation lors de la synchronisation du paquet " +
                            packageName + "." +
                            "\r\n" + e.description);
                    } else {
                        err_summary += "\r\nPaquet: '" + packageName + "'\r\n  " + e.description;
                    }
                }
            } else if (parseInt(installedPackage.getAttribute("revision")) < packageRev) {
                try {
                    if (notifyAttr != "false") {
                        notifyUserStart();
                    }
                    upgradePackage(installedPackage, packageNode);
                    info("==============================================================="); // saut ligne entre les paquets ‡ installer
                } catch (e) {
                    if(quitonerror) {
                        throw new Error("Erreur de mise ‡ jour lors de la synchronisation du paquet " +
                            packageName + "." +
                            "\r\n" + e.description);
                    } else {
                        err_summary += "\r\nPaquet: '" + packageName + "'\r\n  " + e.description;
                    }
                }
            }
        }
    }
    
    // if we had previously warned the user about an impending installation, let
    // them know that all action is complete
    if (was_notified) {
        notifyUserStop();
    }
}

function queryAllPackages() {
    // retrieve packages
    var settingsNodes = settings.selectNodes("package");
    var packagesNodes = packages.selectNodes("package");
    
    // concatenate both lists
    var packageNodes = concatenateList(settingsNodes, packagesNodes);
    var packageNodes = uniqueAttributeNodes(packageNodes, "id");
    
    // create a string to append package descriptions to
    var message = new String();
    
    for (var i = 0; i < packageNodes.length; i++) {
        var packageNode     = packageNodes[i];
        var packageName     = packageNode.getAttribute("name");
        var packageId       = packageNode.getAttribute("id");
        var packageRevision = packageNode.getAttribute("revision");
        var packageReboot   = packageNode.getAttribute("reboot");
        
        if (packageReboot != "true") {
            packageReboot = "false";
        }
        
        message += packageName + "\r\n";
        message += "    ID:         " + packageId + "\r\n";
        message += "    Revision:   " + packageRevision + "\r\n";
        message += "    Reboot:     " + packageReboot + "\r\n";
        if (searchList(settingsNodes, packageNode)) {
            message += "    Status:     Installed\r\n";
        } else {
            message += "    Status:     Not Installed\r\n";
        }
        message += "\r\n";
    }
    
    info(message);
}

function queryInstalledPackages() {
    /**
     * Show the user a list of packages that are currently installed.
     */
    // retrieve currently installed nodes
    var packageNodes = settings.selectNodes("package");
    
    // create a string to append package descriptions to
    var message = new String();
    
    for (var i = 0; i < packageNodes.length; i++) {
        var packageNode     = packageNodes(i);
        var packageName     = packageNode.getAttribute("name");
        var packageId       = packageNode.getAttribute("id");
        var packageRevision = packageNode.getAttribute("revision");
        var packageReboot   = packageNode.getAttribute("reboot");
        
        if (packageReboot != "true") {
            packageReboot = "false";
        }
        
        message += packageName + "\r\n";
        message += "    ID:         " + packageId + "\r\n";
        message += "    Revision:   " + packageRevision + "\r\n";
        message += "    Reboot:     " + packageReboot + "\r\n";
        message += "    Status:     Installed\r\n";
        message += "\r\n";
    }
    
    info(message);
}

function queryUninstalledPackages() {
    /**
     * Shows the user a list of packages that are currently not installed.
     */
    // create a string to append package descriptions to
    var message = new String();
    
    // retrieve currently installed nodes
    var packageNodes = packages.selectNodes("package");
    
    // loop over each package
    for (var i = 0; i < packageNodes.length; i++) {
        var packageNode     = packageNodes(i);
        var packageId       = packageNode.getAttribute("id");
        var packageName     = packageNode.getAttribute("name");
        var packageRevision = packageNode.getAttribute("revision");
        var packageReboot   = packageNode.getAttribute("reboot");
        
        if (packageReboot != "true") {
            packageReboot = "false";
        }
        
        // search for the package in the local settings
        var installedPackage = settings.selectSingleNode("package[@id='" +
            packageId + "']");
            
        // if the package is not installed, install it
        if (installedPackage == null) {
            message += packageName + "\r\n";
            message += "    ID:         " + packageId + "\r\n";
            message += "    Revision:   " + packageRevision + "\r\n";
            message += "    Reboot:     " + packageReboot + "\r\n";
            message += "    Status:     Not Installed\r\n";
            message += "\r\n";
        }
    }
    
    info(message);
}

function installPackageName(name) {
    /**
     * Installs a package by name.
     */
    // query the package node
    var node = packages.selectSingleNode("package[@id='" + name + "']");
    
    if (node == null) {
        info("Paquet " + name + " absent!");
        return;
    }

    var executeAttr = node.getAttribute("execute");
    if (executeAttr == "once") {
        executeOnce(node);
    } else {
        installPackage(node);
    }
}

function upgradePackageName(name) {
    /**
     * Upgrades a package by name.
     */
    // query the package node
    var nodeNew = packages.selectSingleNode("package[@id='" + name + "']");
    var nodeOld = settings.selectSingleNode("package[@id='" + name + "']");
    
    if (nodeOld == null) {
        info("Paquet " + name + " non installÈ!");
        return;
    }
    
    if (nodeNew == null) {
        info("Nouveau paquet " + name + " absent!");
        return;
    }

    var executeAttr = nodeNew.getAttribute("execute");
    if (executeAttr != "once") {
        upgradePackage(nodeOld, nodeNew);
    }
}

function removePackageName(name) {
    /**
     * Removes a package by name.
     */
    // query the package node
    var node = settings.selectSingleNode("package[@id='" + name + "']");
    
    if (node == null) {
        info("Le paquet '" + name + "' n'est pas installÈ actuellement.");
        return;
    }
    
    removePackage(node);
}


function fillSettingsWithInstalled(settingsDoc, packagesDoc) {
    /**
     * Builds settings document tree containing actually installed packages.
     * Tests all packages from given doc tree for "check" conditions.
     * If given conitions are positive, package is considered as installed.
     */
    var packagesNodes = packagesDoc.selectNodes("package");

    for (var i = 0; i < packagesNodes.length; i++) {
        var packNode = packagesNodes[i];

        if (checkInstalled(packNode)) {
            var clone = packNode.cloneNode(true);

            settingsDoc.appendChild(clone);
        }
    }
}



function getRegistryValue(keyName) {
    /**
     * Returns value of given key in registry.
     */
    var val;
    try {
        val = WshShell.RegRead(keyName);
    } catch (e) {
        val = null;
    }
    return val;
}

function setRunningState(statename) {
    var WshShell = new ActiveXObject("WScript.Shell");
    var val;
    
    try {
            val = WshShell.RegWrite(sRegWPKG_Running, statename);
    } catch (e) {
            val = null;
    }
    return val;
}
            

function scanUninstallKeys(nameSearched) {
    /**
     * Scans uninstall list for given name.
     * Uninstall list is placed in registry under 
     *    HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall
     * Every subkey represents package that can be uninstalled.
     * Function checks each subkey for containing value named DisplayName.
     * If this value exists, function returns true if nameSearched matches it.
     */
    var HKLM = 0x80000002;
    var dName;
    try
    {
        oLoc = new ActiveXObject("WbemScripting.SWbemLocator");
        oSvc = oLoc.ConnectServer(null, "root\\default");
        oReg = oSvc.Get("StdRegProv");
        //-------------------------------------------------------------

        oMethod = oReg.Methods_.Item("EnumKey");
        oInParam = oMethod.InParameters.SpawnInstance_();
        oInParam.hDefKey = HKLM;
        oInParam.sSubKeyName = sRegPath;
        oOutParam = oReg.ExecMethod_(oMethod.Name, oInParam);

        aNames = oOutParam.sNames.toArray();

        for (i = 0; i < aNames.length; i++) {
            dName = getRegistryValue("HKLM\\" + sRegPath + "\\" + aNames[i] + "\\DisplayName");

            if (null != dName) {
                if (dName == nameSearched) {
                    return true;
                }
            }
        }
    }
    catch(err)
    {
        alert("Une erreur est survenue lors de la recherche dans le registre de " + nameSearched +
                        "\r\nCode: " + hex(err.number) + "; Description: " + err.description);
    }
    return false;
}


function hex(nmb) {
    //User-defined function to format error codes.
    //VBScript has a Hex() function but JScript does not.
    if (nmb > 0)
        return nmb.toString(16);
    else
        return (nmb + 0x100000000).toString(16);
}

function dinfo(stringInfo) {
    /** 
     * Presents some debug output if debugging is enabled
     */
    if (debug) {
        info(stringInfo)
    }
}

function checkCondition(checkNode) {
    /**
     * Checks for the success of a check condition for a package.
     */
    var checkType = checkNode.getAttribute("type");
    var checkCond = checkNode.getAttribute("condition");
    var checkPath = checkNode.getAttribute("path");
    var checkValue = checkNode.getAttribute("value");

    // sanity check: must have Type set here
    if (checkType == null) {
         throw new Error("Le type de test n'est pas dÈfini\r\n" +
                         "Information complÈmentaire: " +
                         "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
    } // if checkType == null

    if (checkType == "registry") {

        // sanity check: must have Cond and Path set for all registry checks
        if ((checkCond == null) || (checkPath == null)) {
            throw new Error("La condition ou le chemin pour le test du registre n'est pas dÈfini.\r\n" +
                           "Information complÈmentaire: " +
                           "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
        } // if checkCond == null || checkPath == null

        if (checkCond == "exists") {
            var val = getRegistryValue(checkPath);

            if (val != null) {
                // Some debugging information
                dinfo("Le chemin registre '"+checkPath+"' existe.");
                return true;
            } else {
                // Some debugging information
                dinfo("Le chemin registre '"+checkPath+"' n'existe pas.");
                return false;
            }
        } else if (checkCond == "equals") {
            var val = getRegistryValue(checkPath);
            if (val == checkValue) {
                // Some debugging information
                dinfo("Le chemin registre '"+checkPath+"' contient la valeur correcte: '"+ checkValue+"'.");
                return true;
            } else {
                info("Le chemin registre '"+checkPath+"' ne contient pas la valeur : '"+ checkValue+"'.");
                // change: use a return false:
                return false;
                // endChange
            }
        } else {
            throw new Error("Condition 'check': " + checkCond + " inconue pour le registre.");
        }
    } else if (checkType == "file") {
        // sanity check: must have Cond and Path set for all file checks
        if ((checkCond == null) || (checkPath == null)) {
            throw new Error("Le chemin ou la condition du test du fichier n'est pas dÈfini.\r\n" +
                            "Information complÈmentaire: " +
                            "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
        } // if checkCond == null || checkPath == null

        var shell = new ActiveXObject("WScript.Shell");
        checkPath=shell.ExpandEnvironmentStrings(checkPath);
        if (checkCond == "exists") {
            var fso = new ActiveXObject("Scripting.FileSystemObject");
            if (fso.FileExists(checkPath)) {
                // Some debugging information
                dinfo("Le chemin '"+checkPath+"' existe.");
                return true;
            } else {
                // Some debugging information
                dinfo("Le chemin '"+checkPath+"' n'existe pas.");
                return false;
            }
        } else if (checkCond == "sizeequals") {
            // sanity check: must have Value set for a size check
            if (checkValue == null) {
                throw new Error("La valeur du test 'sizeequals' n'est pas dÈfinie.\r\n" +
                                "Information complÈmentaire: " +
                                "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
            } // if checkValue == null

            filesize=GetFileSize(checkPath);
            if (filesize == checkValue) {
                dinfo("Le fichier '"+checkPath+"' a une taille de "+filesize+" octets.");
                return true;
            } else {
                dinfo("Le fichier '"+checkPath+"' a une taille de  "+filesize+" au lieu de "+ checkValue+".")
            }
        } else if (checkCond.substring(0,7) == "version") {
            // sanity check: Must have a value set for version check
            if (checkValue == null) {
                throw new Error("La valeur du test 'version' du fichier est null.\r\n" +
                                "Information complÈmentaire: " +
                                "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
            } // if checkValue == null

            CheckValFromFileSystem = GetFileVersion(checkPath);
            CheckValFromWpkg       = checkValue;
            if (CheckValFromFileSystem != "UNKNOWN") {
                var versionresult = VersionCompare(CheckValFromFileSystem, CheckValFromWpkg);
                var versionresultString = (versionresult == 0) ? "egalitÈ" : ( (versionresult == -1) ? "infÈrieur" : (versionresult == 1) ? "supÈrieur" : "inconnu" )
                dinfo ("Test de la version du fichier " + CheckValFromFileSystem + " " + checkCond + 
                       " " + CheckValFromWpkg + " - RÈsultat: "+versionresultString);
                switch (checkCond) {
                   case "versionsmallerthan":
                       retval=(versionresult == -1);
                       //dinfo("Checking version of '"+checkPath+"' : Is "+CheckValFromFileSystem + " < "+checkValue+" ? "+retval);
                       return retval;
                       break;
                   case "versionlessorequal":
                       retval=(   (versionresult == -1)
                               || (versionresult == 0) );
                       //dinfo("Checking version of '"+checkPath+"' : Is "+CheckValFromFileSystem+" <= "+checkValue+" ? "+retval);
                       return retval;
                       break;
                   case "versionequalto":
                       retval=(versionresult == 0);
                       //dinfo("Checking version of '"+checkPath+"' : Is "+CheckValFromFileSystem+" = "+checkValue+" ? "+retval);
                       return retval;
                       break;
                   case "versiongreaterorequal":
                       retval=(   (versionresult == 1)
                               || (versionresult == 0) );
                       //dinfo("Checking version of '"+checkPath+"' : Is "+CheckValFromFileSystem+" >= "+checkValue+" ? "+retval);
                       return retval;
                       break;
                   case "versiongreaterthan":
                       retval=(versionresult == 1);
                       //dinfo("Checking version of '"+checkPath+"' : Is "+CheckValFromFileSystem+" >= "+checkValue+" ? "+retval);
                       return retval;
                       break;
                   default:
                       throw new Error("Test inconnu sur les versions de fichier : " + checkCond);
                       break;
               }
           } else {
               // Didn't get a sensible version number from GetFileVersion
               dinfo("Version du fichier '" + checkPath + "' inconnue.");
               return (false);
           }

        } else {
            throw new Error("Test " + checkCond + " inconnu sur les fichiers.");
        }

    } else if (checkType == "uninstall") {
        // sanity check: must have Cond and Path set for all uninstall checks
        if ((checkCond == null) ||
            (checkPath == null)) {
             throw new Error("Le type de test est nul pour le contrÙle de dÈsinstallation.\r\n" +
                             "InformationcomplÈmentaire: " +
                             "condition='"+checkCond+"', path='"+checkPath+"', value='"+checkValue+"'");
        } // if checkCond == null || checkPath == null

        if (checkCond == "exists") {
            if (scanUninstallKeys(checkPath)) {
                dinfo("EntrÈe registre 'Uninstall' trouvÈe pour '"+checkPath+"'.");
                return true;
            } else {
                dinfo("EntrÈe registre 'Uninstall' absente pour '"+checkPath+"'.");
                return false;
            }
        } else {
            throw new Error("Condition '" + checkCond + "' inconnue pour le test de type 'Uninstall'.");
        }
    } else if (checkType == "logical") {
    
        // sanity check: must have Cond set for logical checks
        if (checkCond == null) {
            throw new Error("Il manque la condition d'un test logique." );
        } // if checkCond == null
    
        var subcheckNodes = checkNode.selectNodes("check");
   
        switch (checkCond) {
        case "not":
            if (subcheckNodes.length == 1) {
                retval=! checkCondition(subcheckNodes[0]);
                dinfo("Le rÈsultat du test logique 'NOT' est "+retval);
                return retval;
            } else {
                throw new Error("Il faut un unique noeud enfant ‡ un test logique 'not', hors il y en a " + checkNodes.length);
            }
            break;
        case "and":
            for (var i = 0; i < subcheckNodes.length; i++) {
                if (! checkCondition(subcheckNodes[i])) {
                    // lazy execution here.
                    dinfo("Le rÈsultat du test logique 'AND' est 'false'");
                    return false;
                }
            }
            dinfo("Le rÈsultat du test logique 'AND' est 'true'");
            return true;
            break;
        case "or":
            for (var i = 0; i < subcheckNodes.length; i++) {
                if (checkCondition(subcheckNodes[i])) {
                    dinfo("Le rÈsultat du test logique 'OR' est 'true'");
                    return true;
                }
            }
            dinfo("Le rÈsultat du test logique 'OR' est 'false'");
            return false;
            break;
        case "atleast":
            if (checkValue == null) {
                throw new Error("Le test sur la condition logique 'atleast' nÈcessite un attribut 'value'.");
            }
            var count=0;
            for (var i = 0; i < subcheckNodes.length; i++) {
                if (checkCondition(subcheckNodes[i])) count++;
                // lazy execution
                if (count >= checkValue) {
                    dinfo("Le rÈsultat du test logique 'AT LEAST' est 'true'");
                    return true;
                }
            } // for loop over subcheckNodes
            dinfo("Le rÈsultat du test logique 'AT LEAST' est 'false'");
            return false;
            break;
        case "atmost":
            var count=0;
            for (var i = 0; i < subcheckNodes.length; i++) {
                if (checkCondition(subcheckNodes[i])) count++;
                // lazy execution
                if (count > checkValue) {
                    dinfo("Le rÈsultat du test logique 'AT MOST' est 'false'");
                    return false;
                }
            }
            // result will be true now
            dinfo("Le rÈsultat du test logique 'AT MOST' est 'true'");
            return true;
            break;
        default:
            throw new Error("Condition " + checkCond + " inconnue pour le test logique.");
            break;
        }
    } else {
        throw new Error("Type de condition '" + checkType + "' inconnue.");
    }
    
    return false;
}

function VersionCompare(a,b) {
    /**
     *   VersionCompare - compare two executable versions
     */
    // Return 0 if equal
    // Return -1 if a < b
    // Return +1 if a > b
    var as = a.split(".");
    var bs = b.split(".");
    var length=as.length;
    var ret=0;
    for (var i = 0; i < length; i++) {
        var av = as[i]*1;
        var bv = bs[i]*1;
        if (av<bv) {
            ret=-1;
            i=length; // Hack to exit loop
        } else if (av>bv) {
            ret=1;
            i=length;
        }
    }
    return ret;
}

function GetFileVersion (file) {
    /**
     *  Gets the version of a file
     */
    var version="UNKNOWN";
    try {
        dinfo ("Recherche de la version de '"+file+"'\r\n");
        var FSO = new ActiveXObject("Scripting.FileSystemObject");
        version = FSO.GetFileVersion(file);
        //leb:
        if ( version == "" ) version = "UNKNOWN";
        dinfo ("Version='"+version+"'.");
    } catch (e) {
        version="UNKNOWN";
        dinfo ("Erreur lors de la dÈtermination de la version du fichier '"+file+"' : "+e.description);
    }
    dinfo ("GetFileVersion retourne la valeur de version: "+version);
    return version;
}

function GetFileSize (file) {
    /**
     *  Gets the size of a file
     */
    var size="UNKNOWN";
    try {
        dinfo ("DÈtermination de la taille du fichier '"+file+"'.");
        var FSO = new ActiveXObject("Scripting.FileSystemObject");
        var fsof = FSO.GetFile(file);
        size = fsof.Size;
    } catch (e) {
        size="UNKNOWN";
        dinfo("Impossible de dÈterminer la taille du fichier "+file+" : "+
               e.description);
    }
    dinfo ("GetFileSize Taille = "+size);
    return size;
}

function checkInstalled(packageNode) {
    /**
    *  Check if package is installed.
    */
    var retour=true;
    var packageName = packageNode.getAttribute("name");
    
    // get a list of checks to perform before installation.
    var checkNodes = packageNode.selectNodes("check");
    
    // when there are no check conditions, say "not installed"
    if (checkNodes.length == 0) {
        retour = false;
    } else {
        // loop over every condition check
        // if all are successful, we consider package as installed
        for (var i = 0; i < checkNodes.length; i++) {
            if (! checkCondition(checkNodes[i])) {
                retour = false;
            } 
        }
    }
    dinfo ("PrÈsence du paquet '" + packageName + "' sur le poste: " + (retour?"Vrai":"Faux") +".");
    return retour;
}

function executeOnce(packageNode) {
    /**
     * Executes command of the package and registers this fact.
     */
    var packageName = packageNode.getAttribute("name");
    var packageId = packageNode.getAttribute("id");
    
    info("ExÈcution des commandes pour '" + packageName + "' ...");
        
    // select command lines to install
    var cmds = packageNode.selectNodes("install");
        
    // execute each command line
    for (var i = 0; i < cmds.length; i++) {
        var cmdNode = cmds(i);
        var cmd = cmdNode.getAttribute("cmd");
        var workdir = cmdNode.getAttribute("workdir");
        var timeout = cmdNode.getAttribute("timeout");
            
        if (timeout == null) {
            timeout = 0;
        } else {
            timeout = parseInt(timeout);
        }
            
        try {

            dinfo("commande : " + cmd);
            var result = 0;
            result = exec(cmd, timeout, workdir);
            //dinfo("code de retour: " + result);

            // if exit code is 0, return successfully
            if (result == 0) {
                continue;
            }

            // search for exit code
            var exitNode = cmdNode.selectSingleNode("exit[@code='" +
                result + "']");

            // check for special exit codes
            if (exitNode != null) {
                if (exitNode.getAttribute("reboot") == "true") {
                    // this exit code forces a reboot
                    info("La commande de '" + packageName + "' a retournÈ la valeur " +
                        "[" + result + "]. Un redÈmarrage immÈdiat est nÈcessaire.");
                    reboot();
                } else {
                    // this exit code is successful
                    info("La commande de mise ‡ jour de '" + packageName + "' a retournÈ la valeur " +
                        "[" + result + "]. Cette valeur n'est pas une erreur.");
                    continue;
                }
            }

            // command did not succeed, throw error
            throw new Error(0, "Code d'erreur: " + result + ". '" + cmd + "'");
        } catch (e) {
            throw new Error("Erreur d'exÈcution de '" + packageName + "'. " +
                e.description);       
        }
    }
    
    // check for old node and remove it if there, to avoid duplicate settings
    // file entries when execution=always
    var nodeOld = settings.selectSingleNode("package[@id='" + packageId + "']");
    if (nodeOld != null) {
       info("Remplacement des entrÈes de wpkg.xml pour '" + packageName + "'.");
       settings.removeChild(nodeOld);
    }
    
    // append new node to local xml
    settings.appendChild(packageNode);
    saveXml(settings, settings_file);
    
    // reboot the system if this package is suppose to
    if (packageNode.getAttribute("reboot") == "true") {
        info("ExÈcution des commandes de '" + packageName + "' rÈussies, le poste redÈmarre.");
        reboot();
    } else {
        info("Execution de '" + packageName + "' rÈussie.");
    }
}


function trim(string) {
    /**
     * Removes leading / trailing spaces
     */
    return(string.replace(new RegExp("(^\\s+)|(\\s+$)"),""));
}

function installPackage(packageNode) {
    /**
     * Installs the specified package node to the system.
     */
    var packageName = packageNode.getAttribute("name");
    
    // get a list of checks to perform before installation.
    var checkNodes = packageNode.selectNodes("check");
    var bypass = false;


    // when "/forceinstall" say "not installed"
    if (!forceInstall) {
        bypass = checkInstalled(packageNode);
        if (bypass) {
                info("Ignore la demande d'installation du paquet " + packageName);

                // yes the packages is installed, but is it in wpkg.xml?
                var packageID = packageNode.getAttribute("id");
                var nodeInst = settings.selectSingleNode("package[@id='" + packageID + "']");

                if (nodeInst == null) {
                  
                  dinfo("Ajout du paquet '" + packageName + "' dans wpkg.xml.");
                  
                  settings.appendChild(packageNode);
                  saveXml(settings, settings_file);
                }
        }
    }

    if (!bypass) {
        info("Installation de '" + packageName + "' ...");
/***        
        var cmdconditions = packageNode.selectNodes("if");
        for (var i = 0; i < cmdconditions.length; i++) {
            var cmdIf = cmdconditions(i);
            var champ = cmdIf.getAttribute("datebefore");
            dinfo("cmdIf.getAttribute('datebefore')=" + champ);
        }
***/
        // select command lines to install
        var cmds = packageNode.selectNodes("install");
        //dinfo("cmds.length=" + cmds.length);
        
        // execute each command line
        for (var i = 0; i < cmds.length; i++) {
            var cmdNode = cmds(i);
            var cmd = cmdNode.getAttribute("cmd");
            //dinfo("cmds[" + i + "]=" + cmd);
            var workdir = cmdNode.getAttribute("workdir");
            var timeout = cmdNode.getAttribute("timeout");
            
            if (timeout == null) {
                timeout = 0;
            } else {
                timeout = parseInt(timeout);
            }
            
            try {

                //dinfo("ExÈcution de la commande : " + cmd);

                var result = 0;
                //dinfo("exec(" + cmd + ", " + timeout + ", " + workdir + ")");
                result = exec(cmd, timeout, workdir);
                //dinfo("Code de retour: " + result);

                // if exit code is 0, return successfully
                if (result == 0) {
                    continue;
                }

                // search for exit code
                var exitNode = cmdNode.selectSingleNode("exit[@code='" + result + "']");

                // check for special exit codes
                if (exitNode != null) {
                    if (exitNode.getAttribute("reboot") == "true") {
                        // this exit code forces a reboot
                        info("La commande d'installation de '" + packageName + "' a retournÈ la valeur " +
                            "[" + result + "]. Cette valeur nÈcessite un redÈmarrage immÈdiat du poste.");
                        reboot();
                    } else {
                        // this exit code is successful
                        info("La commande d'installation de '" + packageName + "' a retournÈ la valeur " +
                            "[" + result + "]. Cette valeur n'est pas une erreur.");
                        continue;
                    }
                }
                // command did not succeed, throw error
                throw new Error(0, "Code d'erreur: " + result + ". '" + cmd + "'");
            } catch (e) {
                throw new Error("'" + packageName + "' n'a pas pu Ítre installÈ.\r\n" + e.description);
            }
        }

        if (!checkInstalled(packageNode)) {
            throw new Error("'" + packageName + "' n'est pas installÈ, d'aprËs le test (check)\r\n");
        }

    
        // append new node to local xml
        settings.appendChild(packageNode);
        saveXml(settings, settings_file);
    
        // reboot the system if this package is suppose to
        if (packageNode.getAttribute("reboot") == "true") {
            info("Installation de '" + packageName + "' rÈussie, le poste redÈmarre.");
            reboot();
        } else {
            info("Installation de '" + packageName + "' rÈussie.");
        }
    }
}

function upgradePackage(oldPackageNode, newPackageNode) {
    /**
     * Upgrades the old package node to the new package node.
     */
    info("Mise ‡ jour (upgrade) de " + newPackageNode.getAttribute("name") + "...");
    var packageName = newPackageNode.getAttribute("name");
    
    // select command lines to install
    var cmds = newPackageNode.selectNodes("upgrade");
    
    // execute each command line
    for (var i = 0; i < cmds.length; i++) {
        var cmdNode = cmds(i);
        var cmd = cmdNode.getAttribute("cmd");
        var workdir = cmdNode.getAttribute("workdir");
        var timeout = cmdNode.getAttribute("timeout");
        
        if (timeout == null) {
            timeout = 0;
        } else {
            timeout = parseInt(timeout);
        }
        
        try {
            //dinfo("ExÈcution de la commande : " + cmd);
            var result = 0;
            result = exec(cmd, timeout, workdir);
            dinfo("La commande a retournÈ la valeur: " + result);


            // if exit code is 0, return successfully
            if (result == 0) {
                continue;
            }
            
            // search for exit code
            var exitNode = cmdNode.selectSingleNode("exit[@code='" + result + "']");
            
            // if found, command was successful
//leb            if (exitNode != null) {
//                info("Command in upgrade of '" + packageName + "' returned " +
//                    "non-zero exit code [" + result + "]. This exit code " +
//                    "is not an error.");
//                continue;
//            }

            // check for special exit codes
            if (exitNode != null) {
                if (exitNode.getAttribute("reboot") == "true") {
                    // this exit code forces a reboot
                    info("La commande de mise ‡ jour de '" + packageName + "' a retournÈ la valeur " +
                        "[" + result + "]. Cette valeur nÈcessite un redÈmarrage immÈdiat du poste.");
                    reboot();
                } else {
                    // this exit code is successful
                    info("La commande de mise ‡ jour de '" + packageName + "' a retournÈ la valeur " +
                        "[" + result + "]. Cette valeur n'est pas une erreur.");
                    continue;
                }
            }
            
            // command did not succeed, throw error
            throw new Error(0, "La commande de mise ‡ jour de '" + packageName + "' a retournÈ le code d'erreur " + result + ".\r\n" + cmd);
        } catch (e) {
            throw new Error(packageName + " n'a pas pu Ítre mis ‡ jour.\r\n" +
                e.description);
        }
    }


    if (!checkInstalled(newPackageNode)) {

        if (!checkInstalled(oldPackageNode)) {
            //remove old node
            settings.removeChild(oldPackageNode);
            saveXml(settings, settings_file);
        }
        throw new Error(packageName + " n'a pas ÈtÈ mis ‡ jour d'aprËs le test d'installation (check) .");
    } else {
        // replace local node with new node
        settings.removeChild(oldPackageNode);
        settings.appendChild(newPackageNode);
        saveXml(settings, settings_file);
    }


    info("Mise ‡ jour de " + newPackageNode.getAttribute("name") + " version "+ newPackageNode.getAttribute("revision") + " rÈussie.");
    
    // reboot the system if this package is suppose to
    if (newPackageNode.getAttribute("reboot") == "true") {
        reboot();
    }
}

function removePackage(packageNode) {
    /**
     * Removes the specified package node from the system.
     */
    var  failure = false;

    var packageName = packageNode.getAttribute("name");
    info("DÈsinstallation de '" + packageName + "' ...");
    
    // select command lines to remove
    var cmds = packageNode.selectNodes("remove");
    
    // execute each command line
    for (i = 0; i < cmds.length; i++) {
        var cmdNode = cmds(i);
        var cmd = cmdNode.getAttribute("cmd");
        var workdir = cmdNode.getAttribute("workdir");
        var timeout = cmdNode.getAttribute("timeout");
        
        if (timeout == null) {
            timeout = 0;
        } else {
            timeout = parseInt(timeout);
        }
        
        try {
            //dinfo("ExÈcution de la commande : " + cmd);

            var result = exec(cmd, timeout, workdir);
            //dinfo("Code de retour: " + result);
            
            // if exit code is 0, return successfully
            if (result == 0) {
                continue;
            }
            
            // search for exit code
            var exitNode = cmdNode.selectSingleNode("exit[@code='" + result +
                "']");
                
            // if found, command was successful
            if (exitNode != null) {
                info("La commande de dÈsinstallation (remove) de '" + packageName + "' a retournÈ le code " +
                    "[" + result + "]. Ce code de retour n'est pas une erreur.");
                continue;
            }

            // check for special exit codes
            if (exitNode != null) {
                if (exitNode.getAttribute("reboot") == "true") {
                    // this exit code forces a reboot
                    info("La commande de dÈsinstallation (remove) de '" + packageName + "' a retournÈ le code " +
                        "[" + result + "]. Ce code de retour nÈcessite un redÈmarrage immÈdiat du poste.");
                    reboot();
                } else {
                    // this exit code is successful
                    info("La commande de dÈsinstallation (remove) de '" + packageName + "' a retournÈ le code " +
                        "[" + result + "]. Ce code de retour n'est pas une erreur.");
                    continue;
                }
            }
            
            // command did not succeed, throw error
            throw new Error(0, "La commande de dÈsinstallation (remove) a retournÈ le code d'erreur " +
                result + ".\r\n" + cmd);
        } catch (e) {
            failure = true;
            break;

//            throw new Error("Could not remove '" + packageName + "'. " +
//                e.description);
        }
    }
    

    if (!checkInstalled(packageNode)) {
        // remove package node from local xml
        settings.removeChild(packageNode);
        saveXml(settings, settings_file);
    } else {
        failure = true;

//        throw new Error("Could not remove '" + packageName + "'. " +
//                        "Check after removing failed.");
    }
        
    
    // log a nice informational message
    if (!failure) {
        info("DÈsinstallation de " + packageNode.getAttribute("name") + " rÈussie.");
    } else {
        info("Une erreur est survenue lors de la dÈsinstallation de '" + packageName + "'. ");
        return;
    }
    
    // reboot the system if this package is suppose to
    if (packageNode.getAttribute("reboot") == "true") {
        reboot();
    }
}

function getAllPackages() {
    /**
     * Returns an array of all package nodes that can be installed
     */
    // retrieve packages
    var settingsNodes = settings.selectNodes("package");
    var packagesNodes = packages.selectNodes("package");
    
    // concatenate both lists
    var packageNodes = uniqueAttributeNodes(packagesNodes, "id");
    
    var packageArray = new Array();

    for (var i = 0; i < packageNodes.length; i++) {
        var packageNode     = packageNodes[i];
            if (packageNode != null) {
                if (!searchArray(packageArray, packageNode)) {
                   // add the new node to the array 
                   packageArray.push(packageNode);
                }
            }
    }
    return packageArray;
}

function getAvailablePackages() {
    /**
     * Returns an array of package nodes that should be applied to the current
     * profile.
     */
    // get array of all profiles that apply to the base profile
    var profileArray = getAvailableProfiles();


    // create new empty package array
    var packageArray = new Array();
    
    // add each profile's packages to the array
    for (var i in profileArray) {
        profileNode = profileArray[i];

        // search for package tags in each profile
        var packageNodes = profileNode.selectNodes("package");

        // append all the resulting profiles identified by profile-id
        for (var j = 0; j < packageNodes.length; j++) {
            var packageId = packageNodes(j).getAttribute("package-id");

            // grab the package node
            var packageNode = packages.selectSingleNode("package[@id='" +
                packageId + "']");

            // search array for pre-existing package, we don't want duplicates
            if (searchArray(packageArray, packageNode)) {
                continue;
            }

            // sometimes nodes can be null
            if (packageNode != null) {
                // add package-id dependencies 
                appendPackageDependencies(packageArray, packageNode);
                if (!searchArray(packageArray, packageNode)) {
                    // add the new node to the array _after_ adding dependencies
                    packageArray.push(packageNode);
                }
            }
        }
    }
    return packageArray;
}

function appendPackageDependencies(packageArray, packageNode) {
    /* nearly the same as appendProfileDependencies() but more relaxed on unknown
     * or invalid dependencies */
    appendDependencies(packageArray, packageNode, packages, "package");
}

function appendDependencies(appendArray, appendNode, sourceArray, sourceName) {
    // search for package tags in each profile
    var dependsNodes = appendNode.selectNodes("depends");
    if (dependsNodes != null) {
        for (var i = 0; i < dependsNodes.length; i++) {
            var dependsId = dependsNodes(i).getAttribute(sourceName + "-id");
            // skip unknown entries 
            if (dependsId == null) continue;

            dinfo("DÈpendances " + sourceName + " : " + dependsId);
            var dependsNode = sourceArray.selectSingleNode(sourceName + "[@id='" +
                dependsId + "']");

            if (dependsNode == null) {
                throw new Error(0, "DÈpendance invalide  \"" + dependsId +
                        "\" de " + sourceName +  " \"" + appendNode.getAttribute("id") 
                        + "\".");
            }
            // duplicate check 
            if (searchArray(appendArray, dependsNode)) {
                        continue;
                    } else {
                dinfo("Ajout de dÈpendance, " + sourceName + " : '" + dependsId + "'");
                appendArray.push(dependsNode);
                appendDependencies(appendArray, dependsNode, sourceArray, sourceName);
                }
        }
    }
}

function getAvailableProfiles() {
    /**
     * Returns an array of profile nodes that should be applied to the current
     * profile.
     */
    // create array to hold available package nodes
    var profileArray = new Array();
    
    // acquire the node of the current profile
    var profileNode = profiles.selectSingleNode("profile[@id='" + profile + "']");

    dinfo("profil: '" + profile + "'");
        
    // add the current profile's node as the first element in the array
    profileArray.push(profileNode);
    
    // append dependencies of the current profile to the list (recursive)
    appendProfileDependencies(profileArray, profileNode);
    
    return profileArray;
}

function appendProfileDependencies(profileArray, profileNode) {
    /**
     * Appends dependent profile nodes of the specified profile to the specifed
     * array. Recurses into self to get an entire dependency tree.
     */
    appendDependencies(profileArray, profileNode, profiles, "profile");
}

function searchArray(array, element) {
    /**
     * Scans the specified array for the specified element and returns true if
     * found.
     */
    for (var i in array) {
        var e = array[i];
        if (element == e) {
            return true;
        }
    }
    
    return false;
}

function searchList(list, element) {
    /**
     * Scans the specified list for the specified element and returns true if
     * found.
     */
    for (var i = 0; i < list.length; i++) {
        var e = list(i);
        if (element == e) {
            return true;
        }
    }
    
    return false;
}

function uniqueAttributeNodes(nodes, attribute) {
    /**
     * Returns a new array of nodes unique by the specified attribute.
     */
    // hold unique nodes in a new array
    var newNodes = new Array();
    
    // loop over nodes
    for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        var val = node.getAttribute(attribute);
        
        // determine if node with attribute already exists
        var found = false;
        for (var j = 0; j < newNodes.length; j++) {
            var newVal = newNodes[j].getAttribute(attribute);
            if (val == newVal) {
                found = true;
                break;
            }
        }
        
        // if it doesn't exist, add it
        if (!found) {
            newNodes.push(node);
        }
    }
    
    return newNodes;
}

function concatenateList(list1, list2) {
    /**
     * Combines one list and another list into a single array.
     */
    // create a new array the size of the sum of both original lists
    var list = new Array();
    
    for (var i = 0; i < list1.length; i++) {
        list.push(list1(i));
    }
    
    for (var i = 0; i < list2.length; i++) {
        list.push(list2(i));
    }
    
    return list;
}

function uniqueArray(array) {
    /**
     * Remove duplicate items from an array.
     */
    // hold unique elements in a new array
    var newArray = new Array();
    
    // loop over elements
    for (var i = 0; i < array.length; i++) {
        var found = false;
        for (var j = 0; j < newArray.length; j++) {
            if (array[i] == newArray[j]) {
                found = true;
                break;
            }
        }
        
        if (!found) {
            newArray.push(array[i]);
        }
    }
    
    return newArray;
}



function retrieveProfile(hosts, hostName) {
    /**
     * Retrieves profile from given "hosts" XML document.
     * Searches for node having attribute "name" matching
     * given hostName. Returns it's attribute "profile-id".
     *
     * Check is performed using regular expression object:
     * "name" attribute value as the pattern and 
     * hostName as matched string.
     * First matching profile is returned.
     */
    if (null == hostName) {
        //error! lack of attribute "profile-id"
        throw new Error("Erreur! poste: '" + hostName + "' absent du fichier hosts.xml.");
    }

    var hostNodes = hosts.selectNodes("host");
    var i;
    var node;

    var attrName;
    var attrProfile;

    for (i=0; i<hostNodes.length; ++i) {
        node = hostNodes[i];
        if (null != node) {
            attrName = node.getAttribute("name");
            if (null != attrName) {
                if (hostName.toUpperCase() == attrName.toUpperCase()) {
                    attrProfile = node.getAttribute("profile-id");
                    if (null == attrProfile) {
                        //error! lack of attribute "profile-id"
                        throw new Error("Erreur! Pas d'attribut \"profile-id\" pour le poste (host) " + 
                            attrName + ".");
                    }

                    return attrProfile;
                }
            } else {
                //error! lack of attribute "name"
            }
        }
    }



    for (i=0; i<hostNodes.length; ++i) {
        node = hostNodes[i];

        if (null != node) {
            attrName = node.getAttribute("name");

            if (null != attrName) {
                var reg = new RegExp("^" + attrName + "$", "i");

                if (reg.test(hostName)) {
                    attrProfile = node.getAttribute("profile-id");

                    if (null == attrProfile) {
                        //error! lack of attribute "profile-id"
                        throw new Error("Erreur! Pas d'attribut \"profile-id\" pour le poste (host) " + 
                            attrName + ".");
                    }

                    return attrProfile;
                }
            } else {
                //error! lack of attribute "name"
            }
        }
    }

    throw new Error("Profile du poste (host) " + hostName + " absent.");
}
function loadXml( xmlPath, xslPath ) {
    /**
     * Loads an XML file and returns the root element.
     */
    var source = new ActiveXObject("Msxml2.DOMDocument.3.0");
    source.async = false;
    source.validateOnParse = false;
    source.load( xmlPath );
    
    if (source.parseError.errorCode != 0) {
        var myErr = source.parseError;
        info("Erreur en parcourant le xml: " + myErr.reason );
        info("Fichier   " + xmlPath);
        info("Ligne     " + myErr.line);
        info("CaractËre " + myErr.linepos);
        info("Position  " + myErr.filepos);
        info("srcText   " + myErr.srcText);

        exit(2);
    }
    else {
        if( xslPath != null ) {
            try {
                var xmlDoc = new ActiveXObject("Msxml2.DOMDocument.3.0")
                xmlDoc.async="false"
                xmlDoc.validateOnParse = false;
                xmlDoc.loadXML( source.transformNode( xslPath ) );
                return xmlDoc.documentElement;
            } catch (e) {
                    if (quitonerror) {
                    throw new Error("Erreur de lecture du fichier: " + xmlPath + "\r\n" + e.description);
                } else {
                    err_summary += "\r\nErreur de lecture du fichier: " + xmlPath + "\r\n  " + e.description;
                    return source.documentElement;
                }
            }
        } else {
            return source.documentElement;
        }
    }
}

function createXsl( base, folder ) {
    /**
     * Creates xsl document object and returns it.
     */
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var file;
    if( !fso.folderExists( base + "\\" + folder ) ) {
        return null;
    }
    var e = new Enumerator(fso.GetFolder( base + "\\" + folder ).files);
    var str = "";
    var root = "";
    if( folder == "hosts" ) {
        root = "wpkg";
    }
    else {
        root = folder;
    }

    str = "<?xml version=\"1.0\"?>\r\n";
    str += "<xsl:stylesheet xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" version=\"1.0\">\r\n";
    str += "        <xsl:output encoding=\"ISO-8859-1\" indent=\"yes\" method=\"xml\" version=\"1.0\"/>\r\n";
    str += "        <xsl:template match=\"/\">\r\n";
    str += "                <" + root + ">\r\n";
    str += "                        <xsl:copy-of select=\""+ root + "/child::*\"/>\r\n";
    for( e.moveFirst(); ! e.atEnd(); e.moveNext() ) {
        file = e.item();
        var DotSpot = file.name.toString().lastIndexOf('.');
        var extension = file.name.toString().substr(DotSpot + 1,file.name.toString().length);

        if(extension == "xml") {
            str = str + "                        <xsl:copy-of select=\"document('" + 
                    base.replace( /\\/g, "/" ) + "/" + folder + "/" + file.name + 
                    "')/" + root + "/child::*\"/>\r\n";
        }
    }
    str += "                </" + root + ">\r\n";
    str += "        </xsl:template>\r\n";
    str += "</xsl:stylesheet>\r\n";
    var xsl = new ActiveXObject( "Msxml2.DOMDocument.3.0" );
    xsl.async = false;
    xsl.loadXML( str );
    return xsl.documentElement;
}

function saveXml(root, path) {
    /**
     * Saves the root element to the specified XML file.
     */
    if (dryrun) {
        path += ".dryrun";
    }
    dinfo("Sauvegarde de " + path);
    var xmlDoc = new ActiveXObject("Msxml2.DOMDocument.3.0");
    xmlDoc.appendChild(root);
    if (xmlDoc.save(path)) {
        throw new Error(0, "Erreur de sauvegarde de " + path);
    }
}

function createXml(root) {
    /**
     * Creates a new root element of the specified name.
     */
    var xmlDoc = new ActiveXObject("Msxml2.DOMDocument.3.0");

//    xmlDoc.createNode(1, root, "");
//    return xmlDoc;

    return xmlDoc.createNode(1, root, "");
}

/*******************************************************************************
 *
 * Miscellaneous functions
 *
 ******************************************************************************/
function alert(msg) {
    /**
     * Echos text to the command line or a prompt depending on how the program is run.
     */
    var ssmsg;
    if (msg != "") {
        if ( inExecCmd ) {
        } else {
            //WScript.Echo(msg);
            msg += "\r\n";
        }
        WScript.StdOut.Write(msg);
        dumpLog(msg);
    }
}

function log(type, description) {
    /**
     * Logs the specified event type and description in the Windows event log.
     */
    WshShell = WScript.CreateObject("WScript.Shell");
    WshShell.logEvent(type, description);
}

function error(message) {
    /**
     * Logs or presents an error message depending on interactivity.
     */
    if (quiet) {
        log(1, message);
    } else {
        alert(message);
    }
}

function info(message) {
    /**
     * Logs or presents an info message depending on interactivity.
     */
    if (quiet) {
        log(4, message);
    } else {
        alert(message);
    }
}

function exec(cmd, timeout, workdir) {
    /**
     * Executes a shell command and blocks until it is completed, returns the
     * program's exit code. Command times out and is terminated after the
     * specified number of seconds.
     *
     * @param cmd the command line to be executed
     * @param timeout timeout value in seconds
     * @param workdir working directory (optional). If set to null uses the current
     *                working directory of the script.
     * @return command exit code (or -1 in case of timeout)
     */
    // leb
    //WScript.Echo("dbg: In exec(" + cmd + ", " + timeout + ", " + workdir + ")");
    var oldWorkdir, retour=0;
    var i;

    if (dryrun) {
        return 0;
    }
    try {
        var shell = new ActiveXObject("WScript.Shell");

        // Timeout after an hour by default.
        if (timeout == 0) {
            timeout = 3600;
        }
        oldWorkdir = shell.CurrentDirectory;
        //dinfo("oldWorkdir=" + oldWorkdir);
        // set working directory (if supplied)
        if ( (workdir != null) && (workdir != "") ) {
            workdir = shell.ExpandEnvironmentStrings(workdir);
            dinfo("RÈpertoire de travail: " + workdir + " (" + oldWorkdir + ")");
            shell.CurrentDirectory = workdir;
        }
        var newtext="";
        var nC=0, nT=0;
        var fso = new ActiveXObject("Scripting.FileSystemObject");
        
        // Creation du fichier bat a exÈcuter
        i = 1;
        var wpkgcmd;
        var log_file_exec;
        i = 0;
        do {
            i++;
            wpkgcmd = shell.ExpandEnvironmentStrings("%TEMP%\\wpkgcmd" + i + ".bat");
            log_file_exec = shell.ExpandEnvironmentStrings("%TEMP%\\wpkgex" + i + ".log");
        } while (fso.FileExists(wpkgcmd) || fso.FileExists(log_file_exec))
        //dinfo("wpkgcmd=" + wpkgcmd + ", log_file_exec=" + log_file_exec);
        var f = fso.OpenTextFile(wpkgcmd, 2, true); //ForWriting
        f.Write(ansi2oem(cmd) + "\r\n");
        f.Close();
        alert(TimeStamp() + " --- DÈbut exÈcution ------");
        inExecCmd = true;
        try {
            // var shellExec = shell.exec("%ComSpec% /E:ON /V:ON /C (" + cmd + ") 1>" + log_file_exec + " 2>&1" );
            var shellExec = shell.exec("%ComSpec% /E:ON /V:ON /C " + wpkgcmd + " 1>" + log_file_exec + " 2>&1" );
        } catch (e) {
            throw new Error(0, "Commande \"" + cmd + "\" : ECHEC.\r\n" + e.description);
        }

        count = 0;
        var msg="";
        while (shellExec.status == 0) {
            count++;
            nT = readexeclog(log_file_exec, nT, ((count % 10) == 5 ));
// leb
//WScript.Echo("dbg: count=" + count + ", nT=" + nT + ", log_file_exec=" + log_file_exec + ", shellExec.status= " +shellExec.status);
            WScript.sleep(1000);

            if (count >= timeout) {
                inExecCmd = false;
                // Tue le process
                shellExec.Terminate();
            }
            //WScript.sleep(333);
        }
        WScript.sleep(1000);
        nT = readexeclog(log_file_exec, nT, true);
        
        inExecCmd = false;
        if (count >= timeout) {
            alert(TimeStamp() + " --- Fin exÈcution. TimeOut " + timeout + " ------");
            retour = -2;
        } else {
            retour = shellExec.ExitCode;
            alert(TimeStamp() + " --- Fin exÈcution - Code de retour= " + retour + " -----");
        }
        if ( oldWorkdir != shell.CurrentDirectory ) {
            dinfo("Restauration du rÈpertoire de travail: " + oldWorkdir);
            shell.CurrentDirectory = oldWorkdir;
        }
        return retour;
    } catch (e) {
        throw new Error(0, "Commande \"" + cmd + "\" : ECHEC.\r\n" + e.description);
    }
}
function readexeclog(filename, nCarLus, doDumpLog) {
    var flogFile;
    var msg="", msgLength;
    var f, s;
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    if (fso.FileExists(filename)) {
        fso.CopyFile (filename, "NUL");  // flush filename
        f = fso.GetFile(filename);
        s = f.size;
// leb
//WScript.StdOut.WriteBlankLines(0);
//WScript.StdOut.Write(String.fromCharCode(10, 8) + "#in dumpLog#");
//WScript.Echo("dbg: f.size=" + s + ", filename=" + filename + ", nCarLus=" +nCarLus + ", doDumpLog=" + doDumpLog);
        if ( s > nCarLus ) {
            try {
                flogFile = fso.OpenTextFile(filename, 1, true); // ForReading
                msg = flogFile.Skip(nCarLus);
                msg = oem2ansi(flogFile.Read( s - nCarLus));
                //msg = flogFile.Read( s - nCarLus);
                flogFile.Close();
                msgLength = msg.length;
//WScript.Echo("dbg: msgLength=" + msgLength + ", doDumpLog=" + doDumpLog);
                if (msgLength > 0) {
                    alert(msg);
                    msgLog += msg;
                    nCarLus += msgLength;
                }
            } catch(e) {
                info("Erreur de lecture de '" + filename + "'\r\n" + e.number + " " + e.description);
            }
        }
        if (doDumpLog) {
            if (msgLog.length > 0) {
                if ( inExecCmd ) {
                    dumpLog(msgLog);
                } else {
//WScript.Echo("dbg:readexeclog inExecCmd=" + inExecCmd +" xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  +\\r\n");
                    dumpLog(msgLog + '\r\n');
                }
                msgLog = "";
            }
            
        }
    } else {
// leb
//info("ERREUR   NOT FileExists(" + filename + ")");

    }
    return(nCarLus);
}
function dumpLog(msg) {
    // copie les infos de debuggage dans le fichier logFileName
    var flogFile;
    if (msg != "") {
        if (logdebug) {
            if (logFileName != "") {
                try {
                    flogFile = fso.OpenTextFile(logFileName, 8, true); // Append
                    flogFile.Write(msg);
                    flogFile.Close();
                } catch(e) {
                    info("dumpLog: Erreur d'Ècriture dans '" + logFileName + "'\r\n" + e.number + " " + e.description);
                }
            }
        }
    }
}
function initansi2oem() {
    var codesCar = "";
    for (i=0; i<32; i++) { 
        codesCar += String.fromCharCode(i);
    }
    var oemStr =  codesCar + " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¶«¸È‚‰‡ÂÁÍÎËÔÓÏƒ≈…Ê∆ÙˆÚ˚˘ˇ÷‹¯£ÿ◊É·ÌÛ˙Ò—™∫øÆ¨Ωº°´ª¶¶¶¶¶¡¬¿©¶¶++¢•++--+-+„√++--¶-+§– À»iÕŒœ++¶_¶ÃØ”ﬂ‘“ı’µ˛ﬁ⁄€Ÿ˝›Ø¥≠±=æ∂ß˜∏∞®∑π≥≤¶†";
    var charTab= (codesCar + " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ").split("");

    for (i=(oemStr.length-1); i>=0; i--) { 
        Oem[oemStr.charCodeAt(i)] = charTab[i];
    }
    for (i=0; i<256; i++) { 
        if (Oem[i] == null) Oem[i] = String.fromCharCode(i);
    }
}
function ansi2oem(Texte) { //Conversion ANSI -> OEM
    var i, c, r=new Array();
    var L = Texte.length;
    if ( L > 0 ) {
        for ( i=0; i<L; i++) {
            r[i] = Oem[Texte.charCodeAt(i)];
        }
        return r.join("");
    } else {
        return "";
    }
}
function oem2ansi(T) { //Conversion OEM -> ANSI
    var i, s = "", L, c;
    L = T.length;
    for (i=0; i<L; i++) {
        c = T.charCodeAt(i);
        if ( T.charCodeAt(i) >= 128 ) {
            s += oemchar[T.charAt(i)];
        } else {
            s += T.charAt(i);
        }
    }
    return s;
}
function carOem2ansi(ch) { //Conversion OEM -> ANSI d'un car
    var i, s = "";
    c = ch.charCodeAt(0);
    if ( c >= 128 ) {
        s += oemchar[ch];
    } else {
        s += ch;
    }
    return s;
}
function notifySEND(message) {
    /**   OBSOLETE
     * Notifies the user/computer with a pop up message.
     */
    if (!nonotify) {
        var cmd = "";
        cmd += "%SystemRoot%\\System32\\NET.EXE SEND ";
        cmd += host;
        cmd += " \"" + message + "\"";
        try {
            exec(cmd, 0);
        } catch (e) {
            throw new Error(0, "L'envoi du message a ÈchouÈ. " + e.description);
        }
    } else {
        //info("User notification suppressed.");
        info("______________");
    }
}
function notify(message) {
    /**
     * Notifies the user/computer with a pop up message.
     */
    if (!nonotify) {
        //DisplayMsg(message, timedisplay, titre);
        DisplayMsg(message);
    } else {
        //info("User notification suppressed.");
        info("______________");
    }
}

function reboot() {
    if (!noreboot ) {
        switch (rebootCmd) {
        case "standard": 
            var wmi = GetObject("winmgmts:{(Shutdown)}//./root/cimv2");
            var win = wmi.ExecQuery("select * from Win32_OperatingSystem where Primary=true");
            var e = new Enumerator(win);

            info("RedÈmarrage en cours!");

            for (; !e.atEnd(); e.moveNext()) {
                var x = e.item();
                x.win32Shutdown(6);
            }
            break;
        case "special":
            psreboot();
            break;
        default:
            var fso = new ActiveXObject("Scripting.FileSystemObject");
            if (!fso.fileExists(rebootCmd)) {
                var path = WScript.ScriptFullName;
                base = fso.GetParentFolderName(path);
                rebootCmd = fso.BuildPath(base, rebootCmd);
                if (!fso.fileExists(rebootCmd)) {
                    throw new Error("La fichier de commande rebootCmd " + rebootCmd + " est absent.");
                }
            } 
            info("ExÈcution de la commande de redÈmarrage: "+rebootCmd);
            exec(rebootCmd,0); 
            break;
        }
/**    } else if (pretend) {
        info("REBOOT");
*/
    } else {
        info("Le redÈmarrage du poste a ÈtÈ annulÈ.");
    }
    exit(0);
}

function psreboot() {
    /**
     * Reboots the system.
     */
    if (!noreboot ) {

        // RFL prefers shutdown tool to this method: allows user to cancel
        // if required, but we loop for ever until they give in!
        var i;
        var cmd;
        var msg="Un redÈmarrage est nÈcessaire pour achever l'installation de l'application. Elle risque de ne pas fonctionner "+
                "tant que le poste n'aura pas redÈmarrÈ."
        // overwrites global variable rebootcmd !   
        var rebootCmd="tools\\psshutdown.exe"
        var fso = new ActiveXObject("Scripting.FileSystemObject");
        if (!fso.fileExists(rebootCmd)) {
            var path = WScript.ScriptFullName;
            base = fso.GetParentFolderName(path);
            rebootCmd = fso.BuildPath(base, rebootCmd);
            if (!fso.fileExists(rebootCmd)) {
                throw new Error("Le fichier de commande rebootCmd " + rebootCmd + " est absent.");
            } 
        } 
        var shutdown=rebootCmd + " -r ";

        for (i=60; i!=0; i=i-1) {
            // This could be cancelled
            cmd=shutdown+" -c -m \"" +msg+ "\" -t "+i;
            info("ExÈcution de la commande de redÈmarrage: "+cmd);
            exec(cmd,0);
            WScript.Sleep(i*1000);
        }
        // Hmm. We're still alive. Let's get more annoying.
        for (i=60; i!=0; i=i-3) {
            cmd=shutdown+" -m \"" + msg + "\" -t "+i;
            info("ExÈcution de la commande de redÈmarrage: "+cmd);
            exec(cmd,0);
            WScript.Sleep(i*1000);
        }
        // And if we're here, there's problem.
        notify("Ce poste doit Ítre redÈmarrÈ.");
    } else {
        info("Le redÈmarrage du poste a ÈtÈ annulÈ.");
    }
    exit(0);
}
function exit(exitCode) {
    /**
     * Ends program execution with the specified exit code.
     */
    if (exportRunningState) {
        // reset running state 
        setRunningState("false");
    }
if (err_summary != "") {
    info( "\r\n\r\nRÈsumÈ des erreurs:" + err_summary );
    exitCode = 1;
}
    WScript.Quit(exitCode);
}
function queryUpgradablePackages() {
    /**
     * Show the user a list of packages that can be updated.
     */
    // retrieve currently installed and installable nodes
    var installedNodes = settings.selectNodes("package");
    var availableNodes = packages.selectNodes("package");

    // create a string to append package descriptions to
    var message = new String();

    for (var i = 0; i < installedNodes.length; i++) {
        var installedNode       = installedNodes(i);
        var instPackageId       = installedNode.getAttribute("id");
        var instPackageRevision = installedNode.getAttribute("revision");
        var instPackageExecAttr = installedNode.getAttribute("execute");
        if (instPackageExecAttr == "") {
            instPackageExecAttr = "none";
        }
        for (var j = 0; j < availableNodes.length; j++) {
            var availableNode        = availableNodes(j);
            var availPackageId       = availableNode.getAttribute("id");
            var availPackageRevision = availableNode.getAttribute("revision");
            if (instPackageId == availPackageId) {
                message += availableNode.getAttribute("name") + "\r\n";
                message += "    ID:           " + instPackageId + "\r\n";
                message += "    Old Revision: " + instPackageRevision + "\r\n";
                message += "    New Revision: " + availableNode.getAttribute("revision") + "\r\n";
                message += "    ExecAttribs:  " + instPackageExecAttr + "\r\n";
                message += "    Status:       updatable\r\n";
                message += "\r\n";
            }
        }
    }
    info(message);
}

function queryPackage(pack) {
    /**
     * Show the user information about a specific package.
     */
    // retrieve packages
    var settingsNodes = settings.selectNodes("package");
    var packagesNodes = packages.selectNodes("package");

    // concatenate both lists
    var packageNodes = concatenateList(settingsNodes, packagesNodes);
    var packageNodes = uniqueAttributeNodes(packageNodes, "id");

    // create a string to append package descriptions to
    var message = new String();

    for (var i = 0; i < packageNodes.length; i++) {
        var packageNode     = packageNodes[i];
        var packageReboot   = packageNode.getAttribute("reboot");
        var packageName     = packageNode.getAttribute("name");
        var packageId       = packageNode.getAttribute("id");
        var packageExecAttr = packageNode.getAttribute("execute");
        if (packageReboot != "true") {
            packageReboot = "false";
        }
        if (packageExecAttr == "") {
            packageExecAttr = "none";
        }
        if (packageName == pack || packageId == pack) {
            message += packageName + "\r\n";
            message += "    ID:         " + packageId + "\r\n";
            message += "    Revision:   " + packageNode.getAttribute("revision") + "\r\n";
            message += "    Reboot:     " + packageReboot + "\r\n";
            message += "    ExecAttribs:" + packageExecAttr + "\r\n";
            if (searchList(settingsNodes, packageNode)) {
                message += "    Status:     Installed\r\n";
            } else {
                message += "    Status:     Not Installed\r\n";
            }
            message += "\r\n";
        }
    }
    info(message);
}

function TimeStamp(d) {
    if ( d == undefined ) {
        d = new Date();
    } else {
        d = new Date(d);
    }
    var s;
    s = d.getFullYear();
    s += "/" + ((d.getMonth()<9)?"0":"") + (d.getMonth() + 1);
    s += "/" + ((d.getDate()<10)?"0":"") + d.getDate();
    s += " " + ((d.getHours()<10)?"0":"") + d.getHours();
    s += ":" + ((d.getMinutes()<10)?"0":"") + d.getMinutes();
    s += ":" + ((d.getSeconds()<10)?"0":"") + d.getSeconds() ;
    return s;
}
function DisplayMsg(msg, timedisplay, titre) {
    if (typeof timedisplay == "undefined") {
        // DurÈe d'affichage de la boite
        timedisplay=30;
    }
    if (typeof titre == "undefined") {
        // Titre de la boite
        titre="Applications WPKG";
    }
    var bouton=0;
    //0 bouton OK. 
    //1 boutons OK et Annuler. 
    //2 boutons Terminer, RÈessayer et Ignorer. 
    //3 boutons Oui, Non et Annuler. 
    //4 boutons Oui et Non. 
    //5 boutons RÈessayer et Annuler. 
    var icone=128 + 16; // Icone invisible + silentieux
    //16 icÙne Stop. 
    //32 icÙne Point d'interrogation. 
    //48 icÙne Point d'exclamation. 
    //64 icÙne Informations. 
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    
    var fichierTmp = WshShell.ExpandEnvironmentStrings("%WinDir%\\Temp\\msg.js");
    //var SysRunExe = WshShell.ExpandEnvironmentStrings("%Z%\\wpkg\\tools\\SysRun.exe");
    var SysRunExe = WshShell.ExpandEnvironmentStrings("%Z%\\wpkg\\tools\\SysRun.exe");
    if (fso.fileExists(SysRunExe)) {
        // Creation du script ‡ executer
        // WScript.CreateObject("WScript.Shell").Popup "Texte a afficher", waitSecondes, "Titre boite", TypeBouton + TypeIcone
        var f = fso.OpenTextFile(fichierTmp, 2, true); //ForWriting
        f.Write( 'var fso = new ActiveXObject("Scripting.FileSystemObject");\r\n');
        f.Write( 'fso.DeleteFile(WScript.ScriptFullName);\r\n');
        f.Write( '\r\n');
        f.Write( 'var msg="' + msg + '"' + ';\r\n');
        f.Write( 'var titre="' + titre + '"' + ';\r\n');
        f.Write( 'var timedisplay=' + timedisplay + ';\r\n');
        f.Write( 'var bouton=' + bouton + ';\r\n');
        f.Write( 'var icone=' + icone + ';\r\n');
        f.Write( '\r\n');
        f.Write( 'var shell = new ActiveXObject("WScript.Shell");\r\n');
        f.Write( '\r\n');
        f.Write( 'shell.Popup(msg, timedisplay, titre, (bouton + icone));\r\n');
        f.Close();
        WshShell.Run(SysRunExe + ' ' + WScript.Path + '\\WScript.exe ' + fichierTmp);
    }
}