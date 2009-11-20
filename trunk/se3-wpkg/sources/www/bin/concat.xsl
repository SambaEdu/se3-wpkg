<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
   <xsl:param name="fichier">nomdefichierbidon</xsl:param>
   <xsl:variable name="wpkg" select="document('/var/www/se3/wpkg/xml/wpkg.xml')/wpkg"/>
   <!-- 
	Ajoute les donn�es de $fichier � wpkg.xml (destin� au client de gestion wpkg)
	les noeuds d�ja existants de wpkg.xml qui provenaient de $fichier sont mis � jours ou effac�s (pas dupliqu�s)
	Peut s'utiliser � partir d'un fichier wpkg.xml vide :
		<?xml version="1.0" encoding="iso-8859-1"?>
		<wpkg />
	
	F="profiles.xml";xsltproc \-\-stringparam fichier "$F" -o wpkg.xml concat.xsl "$F"
	
   -->

	<xsl:template match="/">
		<!-- ins�re le noeud racine ( /wpkg )-->
		<xsl:element name = "wpkg" >
			<!-- ins�re le noeud des hosts ( /wpkg/wpkg )-->
			<xsl:element name = "wpkg" >
				<xsl:copy-of select = "$wpkg/wpkg/host[not(@fichier=$fichier)]" />
				<xsl:apply-templates select = "wpkg/host" mode="withFichier"/>
			</xsl:element>

			<!-- ins�re le noeud des profiles ( /wpkg/profiles )-->
			<xsl:element name = "profiles" >
				<xsl:copy-of select = "$wpkg/profiles/profile[not(@fichier=$fichier)]" />
				<xsl:apply-templates select = "profiles/profile" mode="withFichier"/>
			</xsl:element>

			<!-- ins�re le noeud des packages ( /wpkg/packages )-->
			<xsl:element name = "packages" >
				<xsl:copy-of select = "$wpkg/packages/package[not(@fichier=$fichier)]" />
				<xsl:apply-templates select = "packages/package" mode="withFichier"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>
   
	<xsl:template match="/*/*" mode="withFichier">
		<!-- recopie les noeuds host, profile ou package en ajoutant le nom du fichier d'origine -->
<!-- 
		<xsl:comment>
			<xsl:text> fichier=</xsl:text><xsl:value-of select="$fichier" />
			<xsl:text>, nodeName=</xsl:text><xsl:value-of select="name()" />
			<xsl:text>, name=</xsl:text><xsl:value-of select="@name" />
			<xsl:text>, id=</xsl:text><xsl:value-of select="@id" />
		</xsl:comment>
-->
		<xsl:copy>
			<!-- M�morise le fichier source des donn�es si ce n'est pas un des 3 fichiers profiles.xml, hosts.xml, packages.xml -->
			<xsl:if test="contains($fichier, '/')">
				<xsl:attribute name="fichier" ><xsl:value-of select="$fichier" /></xsl:attribute>
			</xsl:if>
			<!-- recopie les attributs -->
			<xsl:apply-templates select = "@*"/>
			<xsl:copy-of select="*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*">
		<!-- recopie les noeuds -->
		<xsl:copy-of select="." />
	</xsl:template>

	<xsl:template match="@*">
		<!-- recopie les attributs -->
		<xsl:copy />
	</xsl:template>

</xsl:stylesheet>
