<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
   <!--     Ajoute les packages définis dans profiles.xml à ceux existant dans profiles.xml.tmp 
   
			## $Id$ ##
   -->
   <xsl:variable name="PROFILES" select="document('/var/se3/unattended/install/wpkg/profiles.xml')/profiles"/>

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
        <xsl:variable name="packagesDeCeProfil" select="$PROFILES/profile[@id=$profilId]/package"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            <xsl:apply-templates select="comment()|processing-instruction()" />
            <xsl:if test="$packagesDeCeProfil">
                <xsl:for-each select="$packagesDeCeProfil">
                    <xsl:copy >
                        <xsl:apply-templates select="@*" />
                    </xsl:copy>
                </xsl:for-each>
            </xsl:if>
            <xsl:apply-templates select="*" />
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
