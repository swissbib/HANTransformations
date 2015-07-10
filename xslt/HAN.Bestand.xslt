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
    
   <!-- Template zur Erstellung des Marc-Record -->
    <xsl:template name="record" match="marc:record">
        <xsl:for-each select=".">
            <record>
                <leader>
                    <xsl:value-of select="marc:leader/text()"/>
                </leader>
                <xsl:for-each select="marc:controlfield">
                    <xsl:choose>
                        <xsl:when test="@tag='001'">
                            <controlfield tag="001">
                                <xsl:value-of select="concat('HAN', .)" />
                            </controlfield>                    
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:element name="{local-name()}">
                                <xsl:for-each select="@*">
                                    <xsl:copy-of select="."/>
                                    <xsl:value-of select="../text()"/>
                                </xsl:for-each>                        
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>            
                </xsl:for-each>
                <xsl:apply-templates select="marc:datafield"/>
            </record>
        </xsl:for-each>
    </xsl:template>
    
    
    <!--Verarbeitung von Feldern, die gemappt oder gelöscht werden sollen-->
    <xsl:template match="marc:datafield">
        <!-- Zu löschende Felder -->
        <xsl:for-each select="."> 
            <xsl:choose>
                <xsl:when test="@tag='090'"/> 
                <xsl:when test="@tag='091'"/> 
                <xsl:when test="@tag='092'"/>
                <xsl:when test="@tag='100' or @tag='700'">
                    <xsl:call-template name="pers_entry"/>
                </xsl:when>               
                <xsl:when test="@tag='541'"/>  
                <xsl:when test="@tag='593'"/>  
                <xsl:when test="@tag='CAT'"/>  
                <xsl:when test="@tag='852'">
                    <xsl:call-template name="HOL"/>
                </xsl:when>
                <xsl:when test="@tag='901'">                    
                    <xsl:call-template name="pers_entry_spfield"/>
                </xsl:when>
                <!--Evtl. eigenes Template erstellen für Nonbooks?-->
                <!--<xsl:when test="@tag='906' or '907'">
                    <xsl:call-template name="format"></xsl:call-template>
                </xsl:when>-->
                <xsl:otherwise>
                    <xsl:call-template name="copy_datafields"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>        
    </xsl:template>
    
    <!--Template für das Kopieren der datafield-Elemente-->
    <xsl:template name="copy_datafields">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>                    
                </xsl:for-each>
                <xsl:for-each select="marc:subfield">
                    <xsl:element name="{local-name()}">
                        <xsl:for-each select="@*">
                            <xsl:copy-of select="."/>
                            <xsl:value-of select="../text()"/>
                        </xsl:for-each>                        
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        <!--</xsl:for-each>-->         
    </xsl:template>  
 
   
    <xsl:template name="pers_entry">
        <!--Was soll grundsätzlich mit Personennamen gemacht werden? 
        Einfügen in 700 oder 100 je nach Fall soll in anderen 
        Templates geschehen-->
        <xsl:variable name="pers_name" select="marc:subfield[@code='a']/text()"/>                
        <xsl:choose>
            <!--Hat der Name das Muster 'Nachname, Vorname'?-->            
            <xsl:when test="contains($pers_name, ',')">
                <xsl:call-template name="pers_entry_sur"/>
            </xsl:when>
            <!--Hat der Name das Muster 'Name + Zusatz'?-->
            <xsl:when test="marc:subfield[@code='c']">
                <xsl:call-template name="pers_entry_spname"/>
            </xsl:when> 
            <xsl:otherwise>
                <!--Wenn ein Name nur aus einem Wort ohne Zusatz besteht, 
                soll das Feld einfach kopiert werden, d.h. der Name
                steht dann in $a-->
                <xsl:call-template name="copy_datafields"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--Template, das Eintragungen kopiert, aber $a Nachname $D Vorname macht-->
    <xsl:template name="pers_entry_sur">        
        <xsl:variable name="pers_name_sur" select="marc:subfield[@code='a']/text()"/>
        <xsl:variable name="surname" select="substring-before($pers_name_sur, ',')"/>
        <xsl:variable name="forename" select="substring-after($pers_name_sur, ',')"/>
        <xsl:element name="{local-name()}">
            <xsl:for-each select="@*">
                <xsl:copy-of select="."/>                
            </xsl:for-each>
            <subfield code="a">               
                <xsl:value-of select="$surname"/>
            </subfield>
            <subfield code="D">
                <xsl:value-of select="$forename"/>
            </subfield>
            <xsl:for-each select="marc:subfield[@code != 'a']">
                <xsl:element name="{local-name()}">
                    <xsl:for-each select="@*">
                        <xsl:copy-of select="."/>
                        <xsl:value-of select="../text()"/>
                    </xsl:for-each>                        
                </xsl:element>
            </xsl:for-each>
        </xsl:element> 
    </xsl:template>
    
    <!--Template, das eine Eintragung kopiert, aber $a Name + Zusatz schreibt-->
    <xsl:template name="pers_entry_spname">
        <xsl:variable name="single_name" select="marc:subfield[@code='a']/text()"/>
        <xsl:variable name="add_name" select="marc:subfield[@code='c']/text()"/>
        <xsl:element name="{local-name()}">
            <xsl:for-each select="@*">
                <xsl:copy-of select="."/>                    
            </xsl:for-each>
            <subfield code="a">
                <xsl:value-of select="concat($single_name, ' ', $add_name)"/>
            </subfield>
            <xsl:for-each select="marc:subfield[@code != 'a' and @code != 'c']">
                <xsl:element name="{local-name()}">
                    <xsl:for-each select="@*">
                        <xsl:copy-of select="."/>
                        <xsl:value-of select="../text()"/>
                    </xsl:for-each>                        
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    
    <!--Template für die Verarbeitung von Feld 901-->
    <!--Enthält vorläufig redundanten Code, der in anderen pers_entry-Templates
    auch vorkommt, weil sonst die Navigation zwischen den Templates zu komplex wird-->
    <xsl:template name="pers_entry_spfield">
        <datafield tag="700" ind1=" " ind2=" ">
            <xsl:variable name="pers_name" select="marc:subfield[@code='a']/text()"/>                
            <xsl:choose>
                <!--Hat der Name das Muster 'Nachname, Vorname'?-->            
                <xsl:when test="contains($pers_name, ',')">
                    <xsl:variable name="pers_name_sur" select="marc:subfield[@code='a']/text()"/>
                    <xsl:variable name="surname" select="substring-before($pers_name_sur, ',')"/>
                    <xsl:variable name="forename" select="substring-after($pers_name_sur, ',')"/>
                    <subfield code="a">
                        <xsl:value-of select="$surname"/>
                    </subfield>
                    <subfield code="D">
                        <xsl:value-of select="$forename"/>
                    </subfield>
                    <xsl:for-each select="marc:subfield[@code != 'a']">
                        <xsl:element name="{local-name()}">
                            <xsl:for-each select="@*">
                                <xsl:copy-of select="."/>
                                <xsl:value-of select="../text()"/>
                            </xsl:for-each>                        
                        </xsl:element>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="marc:subfield[@code='c']">
                    <xsl:variable name="single_name" select="marc:subfield[@code='a']/text()"/>
                    <xsl:variable name="add_name" select="marc:subfield[@code='c']/text()"/>
                    <subfield code="a">
                        <xsl:value-of select="concat($single_name, ' ', $add_name)"/>
                    </subfield>
                    <xsl:for-each select="marc:subfield[(@code != 'a') or (@code != 'c')]">
                        <xsl:element name="{local-name()}">
                            <xsl:for-each select="@*">
                                <xsl:copy-of select="."/>
                                <xsl:value-of select="../text()"/>
                            </xsl:for-each>                        
                        </xsl:element>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
            <subfield code="4">
                <xsl:choose>
                    <xsl:when test="@ind1='1'">
                        <xsl:text>bnd</xsl:text>
                        <!--Laut CBS-Transformationsskript kommt bnd
                        nur bei Körperschaften vor-->
                    </xsl:when>
                    <xsl:when test="@ind1='2'">
                        <xsl:text>scr</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='3'">
                        <xsl:text>ann</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='4'">
                        <xsl:text>dte</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='5'">
                        <xsl:text>dto</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='6'">
                        <xsl:text>fmo</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='7'">
                        <xsl:text>pra</xsl:text>
                        <!--Laut CBS-Skript 'dis'-->
                    </xsl:when>
                    <xsl:when test="@ind1='8'">
                        <xsl:text>opn</xsl:text>
                        <!--In Marc-Relatoren-Liste steht 
                        für 'respondent' 'rsp'-->
                    </xsl:when>
                    <xsl:when test="@ind1='9'">
                        <xsl:text>rcp</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='A'">
                        <xsl:text>ill</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1='B'">
                        <xsl:text>cli</xsl:text>
                        <!--Auf Marc-Liste gibt es keinen 'Orderer'.
                        'cli' steht für 'client'. Korrekt?-->
                    </xsl:when>
                    <xsl:when test="@ind1='P'">
                        <xsl:text>cre</xsl:text>
                    </xsl:when>
                    <xsl:when test="@ind1=' '"/>
                </xsl:choose>
            </subfield>
        </datafield>
    </xsl:template>
    
<!--Template für die Verarbeitung von Feld 852-->
<!--Auszugebende Felder noch sortieren
Mapping noch überprüfen-->
    
    <xsl:template name="HOL">
        <datafield tag="852" ind1=" " ind2=" ">
            <xsl:choose>
                <xsl:when test="@ind1='A'">
                    <subfield code="z">
                        <xsl:text>Alternative Signatur</xsl:text>
                    </subfield>
                </xsl:when>
                <xsl:when test="@ind1='E'">
                    <subfield code="z">
                        <xsl:text>Ehemalige Signatur</xsl:text>
                    </subfield>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>            
            <xsl:for-each select="marc:subfield">
                <xsl:choose>
                    <xsl:when test="@code='a'">
                        <subfield code="n">
                            <!--Stimmt $n für Ländercode?-->
                            <xsl:value-of select=".[@code='a']/text()"/>
                        </subfield>
                    </xsl:when>
                    <xsl:when test="@code='d'">
                        <subfield code="j">
                            <xsl:value-of select=".[@code='d']/text()"/>
                        </subfield>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="{local-name()}">
                            <xsl:for-each select="@*">
                                <xsl:copy-of select="."/>
                                <xsl:value-of select="../text()"/>
                            </xsl:for-each>                        
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </datafield>
    </xsl:template>
   
</xsl:stylesheet>   
