<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                version="2.0"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">
    
    <xsl:output
            indent="yes"
            method="xml"
            />

    <!-- ***************************************
         * Template für Bestandsaufnahmen
         * nicht für Digitalisate verwenden
         * very basic, erster Entwurf (25.06.2015/osc)
         ***************************************
    -->
    
    <xsl:template match="/">
        <!-- Inhalt der Template-Regel -->
        <collection>
            <!-- start processing of record nodes -->
            <xsl:apply-templates/>
        </collection>
    </xsl:template>

    <!-- =======================================
         Sektion zur Erstellung der marc:record-Datenstruktur
         =======================================
    -->
    
   <!-- In diesem Template wird das Marc-Record erstellt inkl. Leader und Controlfield -->
    
    <xsl:template match="marc:record">
        <record>
            <leader>
                <xsl:value-of select="marc:leader/text()"/>
            </leader>
            <controlfield tag="001">                
                <xsl:value-of select="concat('HAN', marc:controlfield[@tag='001']/text())" />
            </controlfield>  
            <controlfield tag="008">                
                <xsl:value-of select="marc:controlfield[@tag='008']/text()" />
            </controlfield>  
            <xsl:apply-templates/>
        </record>  
    </xsl:template>

    <xsl:template match="marc:datafield">
        <!--Ist die auskommentierte for-each Schleife hier nötig?
            <xsl:for-each select="marc:datafield">-->
        <xsl:choose>
            <xsl:when test="@tag='090'"/> 
            <xsl:when test="@tag='091'"/> 
            <xsl:when test="@tag='092'"/> 
            <xsl:when test="@tag='593'"/>                    
            <!--Kann die Sortierform des Entstehungszeitraums in swissbib 
                aus Feld 008 statt aus 593 geholt werden? -->     
            <!--<xsl:when test="@tag='596'>Bezug eines Briefes zu Werken der Bernoulli: wohin?</xsl:when>
            Kommt aber im Bestand-Testset nicht vor-->
            <!--<xsl:when test="@tag='579'">Rekatalogiserungsgrad: wohin? In Exemplardaten?</xsl:when>-->
            <xsl:when test="@tag='852'">            
                <subfield code="b">
                    <xsl:value-of select="marc:subfield[@code='b']/text()"/>
                </subfield>
                <subfield code="c">
                    <xsl:value-of select="marc:subfield[@code='c']/text()"/>
                </subfield>
                <xsl:choose>
                    <xsl:when test="@ind1='A'">                
                        <subfield code="d">
                            <xsl:value-of select="concat('Alternative Signatur: ', marc:subfield[@code='d']/text())" />
                        </subfield>   
                    </xsl:when>
                    <xsl:when test="@ind1='E'">                
                        <subfield code="d">
                            <xsl:value-of select="concat('Ehemalige Signatur: ', marc:subfield[@code='d']/text())" />
                        </subfield>   
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="marc:subfield[@code='d']/text()"/>
                    </xsl:otherwise>
                </xsl:choose>  
                <subfield code="e">
                    <xsl:value-of select="marc:subfield[@code='e']/text()"/>
                </subfield>
                <subfield code="n">
                    <xsl:value-of select="marc:subfield[@code='a']/text()"/>
                </subfield>
                <subfield code="x">
                    <xsl:value-of select="marc:subfield[@code='x']/text()"/>
                </subfield>
                <subfield code="z">
                    <xsl:value-of select="marc:subfield[@code='z']/text()"/>
                </subfield>
            </xsl:when>   
            <xsl:when test="@tag='901'">
                <datafield tag="700" ind1=" " ind2=" ">
                    <xsl:choose>
                        <xsl:when test="@ind1='P'">
                            <!--Inhalt des Felds 901 $a in der Variable $relname speichern-->
                            <xsl:variable name="relname" select="marc:subfield[@code='a']/text()"/>  
                            <subfield code="a">         
                                <!--Vor dem Komma muss der Name abgeschnitten werden, der
                                    Nachname wird in $a geschrieben-->
                                <!--< select="($relname, ',')"/> -->  
                                <xsl:value-of select="fn:substring-before($relname, ',')"/>
                            </subfield>       
                            <subfield code="D">    
                                <!--Was vor dem Komma kommt, wird abgeschnitten, der
                                Vorname wird in $D geschrieben-->
                                <xsl:value-of select="fn:substring-after($relname, ',')"/>                           
                            </subfield>
                            <subfield code="4">
                                <!--Code für Aktenbildner reinschreiben--> 
                                <xsl:text>cre</xsl:text>
                            </subfield>
                        </xsl:when>
                    </xsl:choose>   
                </datafield>                                 
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>          
    </xsl:template>
</xsl:stylesheet>
