<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
	<!-- Ajoute ou retire une application d'un profile si les droits de l'utilisateur le permettent et crée profiles.xml modifié.
			S'applique à profiles.xml 
			Est appelé par associer.sh
			
		## $Id$ ##
	-->
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="operation"></xsl:param>
	<xsl:param name="idPackage"></xsl:param>
	<xsl:param name="idProfile"></xsl:param>
	<xsl:param name="login"></xsl:param>
	
	<xsl:key name="ProfileFromId" match="/profiles/profile" use="@id" />
	
	<xsl:variable name="PROFILES" select="/profiles"/>
	<xsl:variable name="DROITS" select="document('/var/se3/unattended/install/wpkg/droits.xml')/droits"/>
	<xsl:variable name="dependParcs" select="key('ProfileFromId', $idProfile)/depends/@profile-id"/>
	<xsl:variable name="OperationAllowed">
		<xsl:choose>
			<xsl:when test="$login = ''" >
				<xsl:text>0</xsl:text>
			</xsl:when>
			<xsl:when test="$DROITS/droit[(@user = $login) and ((@droit = 'admin') or (@droit = 'manage')) and ((@parc = '_TousLesPostes') or (@parc = $idProfile) or (@parc = $dependParcs))]" >
				<xsl:text>1</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>0</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:template match="*">
		<!-- recopie le noeud -->
		<xsl:copy>
			<xsl:apply-templates select="@*" />
			<xsl:apply-templates select="comment()|processing-instruction()" />
			<xsl:apply-templates select="*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="@*">
		<!-- recopie les attributs -->
		<xsl:copy />
	</xsl:template>

	<xsl:template match="comment()|processing-instruction()">
		<xsl:copy />
	</xsl:template>

	<xsl:template match="/profiles/profile">
		<!-- recupère les packages associés depuis profiles.xml -->
		<xsl:variable name="profilId" select="@id"/>
		<xsl:variable name="packagesDeCeProfil" select="$PROFILES/profile[@id = $profilId]/package"/>
		<xsl:choose>
			<xsl:when test="@id = $idProfile" >
				<xsl:copy>
					<xsl:apply-templates select="@*" />
					<xsl:apply-templates select="comment()|processing-instruction()" />
					<!-- <xsl:comment><xsl:value-of select="concat('OperationAllowed=', $OperationAllowed, ', idProfile=', $idProfile, ', idPackage=', $idPackage, ', operation=', $operation, ', login=', $login)" /></xsl:comment> -->
					<xsl:choose>
						<xsl:when test="not($OperationAllowed = '1')" >
							<xsl:comment><xsl:value-of select="concat('Erreur Associer OperationAllowed=', $OperationAllowed, ', idProfile=', $idProfile, ', idPackage=', $idPackage, ', operation=', $operation, ', login=', $login)" /></xsl:comment>
							<xsl:apply-templates select="*" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="*[not((name() = 'package') and (@package-id = $idPackage))]">
								<xsl:apply-templates select="." />
							</xsl:for-each>
							<xsl:if test="$operation = 'Associer'" >
								<xsl:element name = "package" >
									<xsl:attribute name="package-id" ><xsl:value-of select="$idPackage" /></xsl:attribute>
								</xsl:element >
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<!-- recopie le profil sans changement -->
				<xsl:copy>
					<xsl:apply-templates select="@*" />
					<xsl:apply-templates select="comment()|processing-instruction()" />
					<xsl:apply-templates select="*"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>