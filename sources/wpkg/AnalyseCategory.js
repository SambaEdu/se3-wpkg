var debug=true;

var oShell = WScript.CreateObject("WScript.Shell");
var NetinstDir = oShell.ExpandEnvironmentStrings("%SystemDrive%\\netinst");
var fso = new ActiveXObject("Scripting.FileSystemObject");

//var poste = oShell.ExpandEnvironmentStrings("%ComputerName%").toLowerCase( );
var Z = oShell.ExpandEnvironmentStrings("%Z%");

var xslPath = Z + "\\wpkg\\AnalyseCategory.xsl";
var xmlPath = Z + "\\wpkg\\packages.xml";
var xmlResultPath = NetinstDir + "\\PackagesCategory.txt";

var ansichar = Array();
var ansiStr0 = "€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ";
//var ansiStr = "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒáíóúñÑªº¿®¬½¼¡«»¦¦¦¦¦ÁÂÀ©¦¦++¢¥++--+-+ãÃ++--¦-+¤ğĞÊËÈiÍÎÏ++¦_¦Ì¯ÓßÔÒõÕµşŞÚÛÙıİ¯´­±=¾¶§÷¸°¨·¹³²¦ ";
var ansiStr = "__'Ÿ" + '"' + ".ÅÎ^%S<O_Z__''" + '"' + "" + '"' + " --~Ts>o_zYÿ­½œÏ¾İõù¸¦®ªğ©îøñıüïæôú÷û§¯¬«ó¨·µ¶Ç’€ÔÒÓŞÖ×ØÑ¥ãàâå™ëéêšíèá… ƒÆ„†‘‡Š‚ˆ‰¡Œ‹Ğ¤•¢“ä”ö›—£–ìç˜";

for (i=0; i<128; i++) {
	//if (i>0) alert((i+128) + "=" +String.fromCharCode(i)+ " : " +  ansi[i] + " = " + String.fromCharCode(ansi[i]) );
	ansichar[ansiStr0.charAt(i)] = ansiStr.charAt(i);
}
// WScript.Echo("poste=" + poste);
// WScript.Echo("xslPath=" + xslPath);
// WScript.Echo("xmlPath=" + xmlPath);

main(WScript.Arguments);

function main(argv) {
	// TODO : vérifier que le xmlPath existe.
	
	//xmlResultDoc = new ActiveXObject("Msxml2.DOMDocument"); 
	xmlDoc = new ActiveXObject("Msxml2.DOMDocument"); 
	xmlDoc.async = false; 
	xmlDoc.load(xmlPath); 
	var xslt = new ActiveXObject("Msxml2.XSLTemplate"); 
	
	var xslDoc = new ActiveXObject("Msxml2.FreeThreadedDOMDocument"); 
	var xslProc; 
	xslDoc.async = false; 
	xslDoc.load(xslPath); 
	
	xslt.stylesheet = xslDoc;
	xslProc = xslt.createProcessor(); 
	xslProc.input = xmlDoc;
	//xslProc.output = xmlResultDoc;
	
	//xslProc.addParameter("poste", poste); 
	
	xslProc.transform();
	
	SauveFichier(xmlResultPath, xslProc.output)
	//xmlResultDoc.save(xmlResultPath);
	
	//WScript.Echo(xslProc.output)
}
function SauveFichier(filespec, texte) {
	var f, s;
	f = fso.OpenTextFile(filespec, 2, true, 0); // ForWriting
	try {
		f.Write(ansi2oem(texte));
	} catch (e) {
		info("Erreur "+e+" SauveFichier filespec=" + filespec + "\ntexte=" + texte + "\n" + e.description);
		return e;
	}
	f.Close();
	return;
}
function ansi2oem(Texte) { //Conversion ANSI -> OEM
	var i, s = "", L, c;
	L = Texte.length;
	for (i=0; i<L; i++) {
		c = Texte.charCodeAt(i);
		if ( Texte.charCodeAt(i) >= 128 ) {
			s += ansichar[Texte.charAt(i)];
		} else {
			s += Texte.charAt(i);
		}
	}
	return s;
}
function dinfo(stringInfo) {
	if (debug) {
		info("Dbg: " + stringInfo)
	}
}
function info(message) {
	WScript.Echo(message);
}