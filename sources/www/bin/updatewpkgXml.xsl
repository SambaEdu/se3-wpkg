<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
   <!--   ## $Id$ ##
        Met à jour wpkg.xml
        s'applique à profiles.xml
   -->
    <xsl:param name="user" select="''" />
    <xsl:param name="date" select="''" />
	
    <!-- xsl:variable name="PROFILES" select="document(concat('/var/se3/unattended/install/wpkg/tmp/profiles.', $user, '.xml'))/profiles"/ -->
    <xsl:variable name="PROFILES" select="/profiles"/>
    <xsl:variable name="HOSTS" select="document('/var/se3/unattended/install/wpkg/hosts.xml')/wpkg"/>
    <xsl:variable name="RAPPORTS" select="document('/var/se3/unattended/install/wpkg/rapports/rapports.xml')/rapports"/>
    <xsl:variable name="PACKAGES" select="document('/var/se3/unattended/install/wpkg/packages.xml')/packages"/>
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
        <wpkg>
        
            <xsl:comment>
				<xsl:value-of select="$date" />
                <xsl:text> Données accessibles à '</xsl:text>
                <xsl:value-of select="$user" />
                <xsl:text>' : </xsl:text>
                <xsl:for-each select="$ProfilCanRead" >
                    <xsl:value-of select="." />
                    <xsl:text> </xsl:text>
                </xsl:for-each>
            </xsl:comment>
            
            <hosts>
                <xsl:for-each select="$HOSTS/host" >
                    <xsl:sort select="@name" />
                    <xsl:variable name="CePoste" select="."/>
                    <xsl:variable name="NomPoste" select="@name"/>
                    <!-- changement de document en cours -->
                    <xsl:for-each select="$PROFILES" >
                        <xsl:choose>
                            <xsl:when test="$isAdmin or key('profile', $NomPoste)/depends[@profile-id = $ProfilCanRead]">
                                <host>
                                    <xsl:attribute name="name"><xsl:value-of select="$NomPoste" /></xsl:attribute>
                                    <xsl:for-each select="$RAPPORTS" >
                                        <xsl:apply-templates select="key('rapport', $NomPoste)" />
                                    </xsl:for-each>
                                </host>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </hosts>
			<!-- les profiles sont à nouveau dans wpkg.php -->
            <profiles>
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
            <packages>
                <!-- Recopie les noeuds package avec seulement les attributs -->
                <xsl:for-each select="$PACKAGES/package" >
                    <xsl:sort select="@id" />
                    <xsl:copy select=".">
                        <xsl:apply-templates select="@*" />
                        <xsl:apply-templates select="depends" />
                    </xsl:copy>
                </xsl:for-each>
            </packages>
        </wpkg>
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
