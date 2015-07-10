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
    
    <!--<xsl:template match="marc:leader">
        <xsl:element name="{local-name()}">
            <xsl:value-of select="."/>
        </xsl:element>  
        <xsl:call-template name="controlfields"/>
    </xsl:template>
    
    <xsl:template name="controlfields"> 
        <xsl:for-each select="../marc:controlfield">
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
        <xsl:call-template name="datafield"/>
    </xsl:template>-->
    
    <!--Verarbeitung von Feldern, die gemappt oder gelöscht werden sollen-->
    <xsl:template match="marc:datafield">
        <!-- Zu löschende Felder -->
        <xsl:for-each select="."> 
            <xsl:choose>
                <xsl:when test="@tag='090'"/> 
                <xsl:when test="@tag='091'"/> 
                <xsl:when test="@tag='092'"/>
                <!--<xsl:when test="@tag='100'">
                    <xsl:call-template name="pers_entry"/>
                </xsl:when>
                <xsl:when test="@tag='700'">
                    <xsl:call-template name="pers_entry"/>
                </xsl:when>-->
                <xsl:when test="@tag='541'"/>  
                <xsl:when test="@tag='593'"/>  
                <xsl:when test="@tag='CAT'"/>  
                <!--<xsl:when test="@tag='852'">
                    <xsl:call-template name="HOL"/>
                </xsl:when>-->
                <!--<xsl:when test="@tag='800'">
                   <!-\- or '901' or '902' or '903'"-\->
                    <xsl:call-template name="pers_entry_spfield"/>
                </xsl:when>-->
                <!--<xsl:when test="@tag='901'">
                    <!-\- or '901' or '902' or '903'"-\->
                    <xsl:call-template name="pers_entry_spfield"/>
                </xsl:when>-->
                <!--Evtl. eigenes Template erstellen für Nonbooks?-->
                <!--<xsl:when test="@tag='906' or '907'">
                    <xsl:call-template name="format"></xsl:call-template>
                </xsl:when>-->
                <xsl:otherwise>
                    <xsl:call-template name="copy_datafields"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <!--<xsl:apply-templates select="../following-sibling::*"/>-->
       <!-- <xsl:call-template name="record"/>-->
    </xsl:template>
    
    <!--Template für das Kopieren der datafield-Elemente-->
    <xsl:template name="copy_datafields">  
        <xsl:for-each select=".">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>
                    <!--<xsl:value-of select="../node()"/>-->
                </xsl:for-each>
                <xsl:for-each select="./marc:subfield">
                    <xsl:element name="{local-name()}">
                        <xsl:for-each select="@*">
                            <xsl:copy-of select="."/>
                            <xsl:value-of select="../text()"/>
                        </xsl:for-each>                        
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>         
    </xsl:template>  
</xsl:stylesheet>
    
    <!--To Do: Behandlung von Feldern, die gemappt werden müssen -->
    <!--<xsl:template name="pers_entry">
        <!-\-Was soll grundsätzlich mit Personennamen gemacht werden? 
        Einfügen in 700 oder 100 je nach Fall soll in anderen 
        Templates geschehen-\->
        <xsl:variable name="pers_name">
            <xsl:value-of select="@code='a'"/>
        </xsl:variable>        
        <xsl:choose>
            <!-\-Hat der Name das Muster 'Nachname, Vorname'?-\->            
            <xsl:when test="fn:contains($pers_name, ',')">
                <xsl:call-template name="pers_entry_sur"/>
            </xsl:when>
            <!-\-Hat der Name das Muster 'Name + Zusatz'?-\->
            <xsl:when test="./marc:subfield[@code='c']">
                <xsl:call-template name="pers_entry_spname"/>
            </xsl:when>                       
        </xsl:choose>
    </xsl:template>-->
           
             <!-- Folgende Anweisungen können evtl. für alle Eintragungs-Templates 
            als Vorlage nützlich sein-->
            <!--<xsl:when test="@ind1='P'">
                <!-\-Inhalt des Felds 901 $a in der Variable $relname speichern-\->
                <xsl:variable name="relname" select="marc:subfield[@code='a']/text()"/>  
                <subfield code="a">         
                    <!-\-Vor dem Komma muss der Name abgeschnitten werden, der
                                Nachname wird in $a geschrieben-\->
                    <!-\-< select="($relname, ',')"/> -\->  
                    <xsl:value-of select="fn:substring-before($relname, ',')"/>
                </subfield>       
                <subfield code="D">    
                    <!-\-Was vor dem Komma kommt, wird abgeschnitten, der
                            Vorname wird in $D geschrieben-\->
                    <xsl:value-of select="fn:substring-after($relname, ',')"/>                           
                </subfield>
                <subfield code="4">
                    <!-\-Code für Aktenbildner reinschreiben-\-> 
                    <xsl:text>cre</xsl:text>
                </subfield>
            </xsl:when>-->
        
    
    <!--Template, das Eintragungen kopiert, aber $a Nachname $D Vorname macht-->
    <!--<xsl:template name="pers_entry_sur">        
        <xsl:variable name="pers_name_sur" select="marc:subfield[@code='a']/text()"/>
        <xsl:value-of select="$pers_name_sur"/>-->
        <!--Nachname in eine Variable $surname schreiben
        Vorname in eine Variable $forename schreiben
        Element (Feld 100, 700) erstellen (@tag übernehmen)
        $surname in Unterfeld a schreiben
        $forename in Unterfeld D schreiben-->
        <!--<xsl:choose>
            <xsl:when test="@tag=901">
                <xsl:call-template name="pers_entry_spfield"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>-->
    <!--</xsl:template>-->
    
    <!--Template, das eine Eintragung kopiert, aber $a Name + Zusatz schreibt-->
    <!--<xsl:template name="pers_entry_spname"></xsl:template>-->
      
<!--Template für die Verarbeitung von Feld 852-->
<!--Alternative bzw. ehemalige Signaturen evtl. in passendes Unterfeld
packen, ansonsten weglassen-->
    
        
 <!--Template für die Verarbeitung von Feld 901-->
    <!--<xsl:template name="pers_entry_spfield"></xsl:template> -->
    

