<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
   <!--   ## $Id$ ##
        Met à jour tmp/profiles.$login.xml
        s'applique à profiles.xml
   -->
    <xsl:param name="user" select="''" />
    <xsl:param name="date" select="''" />
	
    <xsl:variable name="PROFILES" select="document('/var/se3/unattended/install/wpkg/profiles.xml')/profiles"/>
    <xsl:variable name="DROITS" select="document('/var/se3/unattended/install/wpkg/droits.xml')/droits"/>
    <!-- Profils accessibles à cet utilisateur -->
    <xsl:variable name="isAdmin" select="$DROITS/droit[(@parc = '_TousLesPostes') and (@user=$user) and ((@droit='manage') or (@droit='admin'))]"/>
    <xsl:variable name="UserProfiles" select="$DROITS/droit[@user=$user]"/>
    <xsl:variable name="ProfilCanRead" select="$UserProfiles/@parc"/>
    <xsl:variable name="ProfilCanWrite" select="$UserProfiles[(@droit='manage') or (@droit='admin')]/@parc"/>
    
    <xsl:key name="profile" match="/profiles/profile" use="@id" />
    <xsl:key name="estPoste" match="/profiles/profile[depends/@profile-id = '_TousLesPostes']" use="@id" />
    <xsl:key name="rapport" match="/rapports/rapport" use="@id" />

    <xsl:template match="/">
		<profiles>
			<xsl:comment><xsl:value-of select="concat(' Généré le ', $date, ' pour ', $user)" /></xsl:comment>
			<xsl:for-each select="$PROFILES/profile" >
				<xsl:sort select="@id" />
				<xsl:variable name="CeProfile" select="."/>
				<xsl:choose>
					<xsl:when test="key('estPoste', @id)">
						<xsl:choose>
							<xsl:when test="$isAdmin or (key('profile', @id)/depends[@profile-id = $ProfilCanWrite])">
								<xsl:copy select=".">
									<xsl:apply-templates select="@*" />
									<xsl:attribute name="canWrite">1</xsl:attribute>
									<xsl:apply-templates select="*" />
								</xsl:copy>
							</xsl:when>
							<xsl:when test="key('profile', @id)/depends[@profile-id = $ProfilCanRead]">
								 <xsl:apply-templates select="." />
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$isAdmin or (@id = $ProfilCanWrite)">
								<xsl:copy select=".">
									<xsl:apply-templates select="@*" />
									<xsl:attribute name="canWrite">1</xsl:attribute>
									<xsl:apply-templates select="*" />
							   </xsl:copy>
							</xsl:when>
							<xsl:when test="@id = '_TousLesPostes'">
								 <xsl:apply-templates select="." />
							</xsl:when>
							<xsl:when test="@id = $ProfilCanRead">
								<xsl:comment>ProfilCanRead</xsl:comment>
								 <xsl:apply-templates select="." />
							</xsl:when>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</profiles>
    </xsl:template>

    <xsl:template match="@*">
        <!-- recopie les attributs -->
        <xsl:copy />
    </xsl:template>

    <xsl:template match="*">
        <!-- recopie le noeud -->
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            <xsl:apply-templates select="*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
