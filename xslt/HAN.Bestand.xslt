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
         * und Digitalisate aus HAN
         * verarbeitet alle HANMarc-Felder
         * Version 1 (20.08.2015/awi)
         * Version 2 (21.04.2017/bmt)
         ***************************************
    -->
    
    <xsl:template match="/">
        <!-- Inhalt der Template-Regel -->
        <xsl:for-each select="marc:collection">
            <xsl:element name="{local-name()}">
                <!-- start processing of record nodes -->            
                <xsl:apply-templates select="marc:record"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <!-- =======================================
         Sektion zur Erstellung der marc:record-Datenstruktur
         =======================================
    -->
    
   <!-- Template zur Erstellung des Marc-Record 
   inkl. Leader und Kontrollfeldern-->
    <xsl:template name="record" match="marc:record">
        <xsl:for-each select=".">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="marc:leader">
                    <xsl:element name="{local-name()}">
                        <xsl:value-of select="./text()"/>
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="marc:controlfield[@tag='001']">
                    <xsl:element name="{local-name()}">
                        <xsl:attribute name="tag" select="'001'"/>
                        <xsl:value-of select="concat('HAN', ./text())"/>
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="marc:controlfield[@tag='008']">
                    <xsl:element name="{local-name()}">
                        <xsl:attribute name="tag" select="'008'"/>
                        <xsl:value-of select="./text()"/>
                    </xsl:element>
                </xsl:for-each>
                
                <!--Wenn kein Feld 024 existiert, soll an dieser
                Stelle ein Feld 035 eingefügt werden-->
                <xsl:if test="not(marc:datafield[@tag='024'])">
                    <xsl:call-template name="HAN_link">
                        <xsl:with-param name="focus" select="'record'"/>
                    </xsl:call-template>    
                </xsl:if>
                <xsl:apply-templates select="marc:datafield"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    
    <!-- =======================================
         Verarbeitung der marc:datafields
         =======================================
    -->
    
    <!--Verarbeitung von Feldern, die gemappt oder gelöscht werden sollen-->
    <xsl:template match="marc:datafield">
        <xsl:for-each select="."> 
            <xsl:choose>
                <xsl:when test="@tag='019'"/>
                <!--Nach Feld 024 soll Feld 035
                eingefügt werden-->
                <xsl:when test="@tag='024'">
                    <xsl:call-template name="copy_datafields"/>
                    <xsl:call-template name="HAN_link"/>
                </xsl:when>
                <xsl:when test="@tag='090'"/> 
                <xsl:when test="@tag='091'"/> 
                <xsl:when test="@tag='092'"/>
                <xsl:when test="matches(@tag, '[17][0135][012]')">
                    <xsl:call-template name="copy_datafields">
                        <xsl:with-param name="copy_mode" select="'heading'"/>
                    </xsl:call-template>                       
                </xsl:when>
                <xsl:when test="matches(@tag, '24[06]')">
                    <xsl:call-template name="title"/>
                </xsl:when>
                <xsl:when test="@tag='245'">
                    <xsl:call-template name="title" />
                    <xsl:call-template name="copied_info"/>
                </xsl:when>
                <xsl:when test="matches(@tag, '351')">
                    <xsl:call-template name="level" />
                </xsl:when>
                
                <!--Für Felder 490 und 773 wird in VuFind automatisch
                ein Link mit der Bezeichung 'Serie / Reihe'
                bzw. 'Verknüpfte Einträge - enthalten in:'
                erstellt. Bisher sind aber nicht alle Verzeichnungsstufen
                von HAN in swissbib, wodurch die Links ins Leere 
                führen würden bzw. die Anzeige falsch wäre (auch ohne 
                Systemnr.). Deshalb werden die Felder auf die lokal 
                definierten Felder 499 und 779 gemappt.-->
                <xsl:when test="@tag='490' or @tag='773'">
                    <xsl:element name="{local-name()}">
                        <xsl:choose>
                            <xsl:when test="@tag='490'">
                                <xsl:attribute name="tag" select="'499'"/>
                            </xsl:when>
                            <xsl:when test="@tag='773'">
                                <xsl:attribute name="tag" select="'779'"/>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:attribute name="ind1">
                            <xsl:value-of select="@ind1"/>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:value-of select="@ind2"/>
                        </xsl:attribute>
                        <xsl:call-template name="linking_fields"/> 
                    </xsl:element>                    
                </xsl:when>
                <xsl:when test="@tag='500'">
                    <xsl:call-template name="footnotes"/>
                </xsl:when>
                <xsl:when test="@tag='505'">                    
                   <xsl:call-template name="title_505"/> 
                </xsl:when>
                <xsl:when test="@tag='541'">
                    <xsl:call-template name="acquisition"/>
                </xsl:when>  
                <xsl:when test="@tag='583'"/>
                <xsl:when test="@tag='593'"/>  
                <xsl:when test="@tag='596'"/> 
                <xsl:when test="@tag='597'"/> 
                <xsl:when test="matches(@tag, '6[01359][015]')">
                    <xsl:call-template name="subject"/>
                </xsl:when>
                <xsl:when test="@tag='CAT'"/>
                <xsl:when test="@tag='830'"/>
                <xsl:when test="@tag='852'">
                    <xsl:choose>
                        <xsl:when test="@ind1='A' or @ind1='E'">
                            <xsl:call-template name="other_signature"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="HOL"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="@tag='856'">
                    <xsl:call-template name="URL"/>
                </xsl:when>                
                
                <xsl:when test="@tag='903'"/>
                <xsl:when test="@tag='906' or @tag='907'">
                    <xsl:call-template name="format_908"/>
                </xsl:when>                
                <xsl:otherwise>
                    <xsl:call-template name="copy_datafields"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    
    <!--Template zur Erstellung von Feld 035-->
    <xsl:template name="HAN_link">
        <xsl:param name="focus" select="'datafield'"/>
        <xsl:element name="datafield">
            <xsl:attribute name="tag" select="'035'"/>
            <xsl:attribute name="ind1" select="' '"/>                
            <xsl:attribute name="ind2" select="' '"/>                
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'a'"/>
                
                <!--Je nach dem, von wo das Template aufgerufen
                worden ist, muss ein anderer Pfad angegeben
                werden-->
                <xsl:choose>
                    <xsl:when test="$focus='record'">
                        <xsl:value-of select="concat('(HAN)', 
                            marc:controlfield[@tag='001']/text())"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('(HAN)', 
                            ../marc:controlfield[@tag='001']/text())"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    
    <!--Template für das Kopieren der datafield-Elemente-->
    <xsl:template name="copy_datafields">  
        <xsl:param name="copy_mode">default</xsl:param>
        <xsl:element name="{local-name()}">
            <xsl:for-each select="@*">
                <xsl:copy-of select="."/>                    
            </xsl:for-each>
            
            <xsl:for-each select="marc:subfield">
                <xsl:choose>
                    <!-- Wenn es sich um einen normierten Sucheinstieg handelt -->
                    <xsl:when test="$copy_mode='heading'">       
                        <xsl:call-template name="heading_subfields"/>                                    
                    </xsl:when>
                    
                    <!-- Wenn es kein normierter Sucheinstieg ist, alle Unterfelder
                    unverändert kopieren-->
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
            
        </xsl:element>
    </xsl:template>  
    
    
    <!-- Erstellen der Unterfelder bei normierten Sucheinstiegen -->
    <xsl:template name="heading_subfields">
        <xsl:choose>
            <xsl:when test="@code='a'">
                
                <xsl:choose>
                    <!-- Wenn es sich um einen Sucheinstieg für eine Person handelt -->
                    <xsl:when test="matches(../@tag, '[17]00')">
                        <xsl:choose>
                            
                            <!-- Wenn Ansetzung nach Nachname -->
                            <xsl:when test="..[@ind1='1']">
                                <xsl:variable name="pers_name_sur" select="./text()"/>
                                <xsl:variable name="surname" select="substring-before($pers_name_sur, ',')"/>
                                <xsl:variable name="forename" select="substring-after($pers_name_sur, ', ')"/>   
                                <!-- Nachname in $a, Vorname in $D -->
                                <xsl:element name="subfield">
                                    <xsl:attribute name="code" select="'a'"/>
                                    <xsl:value-of select="$surname"/>
                                </xsl:element>
                                <xsl:element name="subfield">
                                    <xsl:attribute name="code" select="'D'"/>
                                    <xsl:value-of select="$forename"/>
                                </xsl:element>
                            </xsl:when>
                            
                            <!-- Sonst $a unverändert kopieren -->
                            <xsl:otherwise>
                                <xsl:element name="{local-name()}">
                                    <xsl:attribute name="code" select="'a'"/>
                                    <xsl:value-of select="./text()"/>
                                </xsl:element>
                            </xsl:otherwise>                                           
                            
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- Wenn keine Person bzw. wenn Feld 600, ebenfalls $a unverändert kopieren -->
                    <xsl:otherwise>
                        <xsl:element name="{local-name()}">
                            <xsl:attribute name="code" select="'a'"/>
                            <xsl:value-of select="./text()"/>
                        </xsl:element>
                    </xsl:otherwise>   
                </xsl:choose>                                
            </xsl:when>
            
            <xsl:when test="@code='1'">
                <xsl:element name="{local-name()}">
                    <xsl:attribute name="code" select="0"/>
                    <xsl:value-of select="./text()"/>
                </xsl:element>
            </xsl:when>
            
            <!-- Alle anderen Unterfelder des Sucheinstiegs unverändert kopieren -->
            <xsl:otherwise>
                <xsl:element name="{local-name()}">
                    <xsl:for-each select="@*">
                        <xsl:copy-of select="."/>
                        <xsl:choose>
                            <!-- Bei Unterfeld $t sollen die spitzen Klammern
                                            herausgenommen werden -->
                            <xsl:when test="..[@code='t']">
                                <xsl:value-of select="replace(../text(), '&lt;|&gt;', '')"/>  
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="../text()"/>
                            </xsl:otherwise>
                        </xsl:choose>        
                    </xsl:for-each>      
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>               
    </xsl:template>
    
    
    <!--Template für die Verarbeitung von Feld 245 und 240-->
    <xsl:template name="title">
        <xsl:variable name="title" select="marc:subfield[@code='a']/text()"/>
        <xsl:element name="{local-name()}">
            <xsl:attribute name="tag" select="@tag"/>
            <xsl:attribute name="ind1">
                
                <xsl:choose>
                    <!-- Immer ind1=1 bei Feld 240 und 246 -->
                    <xsl:when test="matches(@tag, '24[06]')">
                        <xsl:value-of select="'1'"/>
                    </xsl:when>
                    
                    <!-- Bei Feld 245 -->
                    <xsl:when test="@tag='245'">
                        <!--Wenn eine Verfasser-Haupteintragung
                vorhanden ist, ist ind1 '1', sonst '0'-->
                        <xsl:choose>
                            <xsl:when test="../marc:datafield[matches(@tag,'1[10][10]')]">
                                <xsl:text>1</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>0</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            
            <!-- Indiaktor 2 -->
            <xsl:attribute name="ind2">
                <xsl:choose>
                    
                    <!-- Bei Feld 246, ind2 übernehmen -->
                    <xsl:when test="@tag='246'">
                        <xsl:value-of select="@ind2"/>
                    </xsl:when>
                    
                    <!-- Nonfiling characters bei 240, 245-->
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="starts-with($title, '&lt;')">
                                <xsl:variable name="nonfiling" 
                                    select="substring-before($title, '&gt;')"/>
                                <xsl:variable name="length" select="string-length($nonfiling)"/> 
                                <xsl:choose>
                                    <xsl:when test="contains($title, '&gt; ')">
                                        <xsl:value-of select="$length - 1"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$length - 2"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:text>0</xsl:text>
                            </xsl:otherwise>
                   
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>    
        
            <!--Unterfelder $b aneinanderfügen-->
            <xsl:variable name="titleb">
                <xsl:for-each select="marc:subfield">
                    <xsl:if test="matches(@code, 'b|i||j')">
                        <xsl:value-of select="concat(./text(), ' : ')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>

            <!--Interpunktionen hinten abschneiden-->
            <xsl:variable name="titleb_content" select="concat($titleb, '++')"/>
            <xsl:variable name="titleb_sequence" select="substring-before($titleb_content, ', ++')"/>

            <xsl:for-each select="marc:subfield">
                <xsl:choose>
                    <!--Bei folgenden Unterfeldern sollen die spitzen
                    Klammern rausgenommen werden-->
                    <xsl:when test="matches(@code, 'a|d||p')">
                        <xsl:element name="{local-name()}">
                            <xsl:for-each select="@*">
                                <xsl:copy-of select="."/>
                                <xsl:value-of select="replace(../text(), '&lt;|&gt;', '')"/>
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:when>

                    <!-- Unterfelder $i und $j sind integriert in $b und werden gelöscht-->
                    <xsl:when test="matches(@code, 'b|i|j')"/>

                    <!-- Schreibe Unterfeld $b aufgrund Variable-->
                    <xsl:when test="matches(@code, 'b')">
                        <xsl:element name="{local-name()}">
                            <xsl:attribute name="code" select="'b'"/>
                        </xsl:element>
                    </xsl:when>

                    <!-- GND-Nr. in $0 -->
                    <xsl:when test="@code='1'">
                        <xsl:element name="{local-name()}">
                            <xsl:attribute name="code" select="'0'"/>
                            <xsl:value-of select="./text()"/>
                        </xsl:element>
                    </xsl:when>
                    
                    <!--Die anderen Unterfelder sollen kopiert werden-->
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

            <!-- Unterfeld $b schreiben  -->
            <xsl:element name="marc:subfield">
                <xsl:attribute name="code" select="'b'"/>
                <xsl:value-of select="$titleb_sequence"/>
            </xsl:element>

        </xsl:element>
    </xsl:template>

    <!-- Template für die Verarbeitung der Verzeichnungsstufe (351 $c) -->
    <xsl:template name="level">
        <xsl:variable name="level" select="marc:subfield[@code='c']/text()"/>
        <xsl:element name="datafield">
            <xsl:attribute name="tag" select="'351'"/>
            <xsl:attribute name="ind1" select="' '"/>
            <xsl:attribute name="ind2" select="' '"/>
            <xsl:for-each select="marc:subfield">
                <xsl:choose>
                    <!-- entferne Text nach dem Gleichzeichen, um nur deutsche Bezeichnung zu erhalten -->
                    <xsl:when test="@code='c'">
                        <xsl:element name="{local-name()}">
                            <xsl:attribute name="code" select="'c'"/>
                            <xsl:value-of select="replace($level, '=.*$', '')" />
                        </xsl:element>
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
        </xsl:element>
    </xsl:template>

    <!--Template für die Verarbeitung von Fussnoten-->
    <xsl:template name="footnotes">
        <xsl:element name="{local-name()}">
            <xsl:attribute name="tag" select="'500'"/>
            <xsl:attribute name="ind1">
                <xsl:text> </xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ind2">
                <xsl:text> </xsl:text>
            </xsl:attribute>
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'a'"/>
                
                <!--Für die Spezialindikatoren soll ein Text
                vor den Feldinhalt gestellt werden-->
                <xsl:choose>
                    <xsl:when test="@ind1='A'">
                        <xsl:value-of select="concat('Begleitmaterial: ', marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='B'">
                        <xsl:value-of select="concat('Besitzgeschichte: ', marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='C' and @ind2='A'">
                        <xsl:value-of select="concat('Wasserzeichen: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='C' and @ind2='B'">
                        <xsl:value-of select="concat('Lagen: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='C' and @ind2='C'">
                        <xsl:value-of select="concat('Paginierung: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='D' and @ind2='A'">
                        <xsl:value-of select="concat('Überschriften: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='D' and @ind2='B'">
                        <xsl:value-of select="concat('Initialen: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='D' and @ind2='C'">
                        <xsl:value-of select="concat('Miniaturen: ', 
                            marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    
                    <!--Unterfeld b soll, wenn vorhanden, an $a angehängt werden-->
                    <xsl:when test="@ind1='L'">
                        <xsl:choose>
                            <xsl:when test="marc:subfield[@code='b']">
                                
                                <!--Wenn der Text in $a mit einem Punkt endet,
                                muss kein Komma angehängt werden-->
                                <xsl:choose>
                                    <xsl:when test="ends-with(marc:subfield[@code='a']/text(), '.')">
                                        <xsl:value-of select="concat('Einrichtung: ', marc:subfield[@code='a']/text(), 
                                            ' Schrift: ', marc:subfield[@code='b']/text())"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat('Einrichtung: ', marc:subfield[@code='a']/text(), 
                                            ', Schrift: ', marc:subfield[@code='b']/text())"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('Einrichtung: ', marc:subfield[@code='a']/text())"/>
                            </xsl:otherwise>
                        </xsl:choose>                        
                    </xsl:when>
                    
                    <xsl:when test="@ind1='M'">
                        <xsl:value-of select="concat('Musik: ', marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='O'">
                        <xsl:value-of select="concat('Entstehung: ', marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    <xsl:when test="@ind1='Z'">
                        <xsl:value-of select="concat('Zusätze zum Text: ', marc:subfield[@code='a']/text())"/>
                    </xsl:when>
                    
                    <!--Wenn es ein reguläres Feld 500 ist,
                    einfach kopieren-->
                    <xsl:otherwise>
                        <xsl:value-of select="marc:subfield[@code='a']/text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
            
            <!--Unterfeld $3, falls vorhanden, kopieren-->
            <xsl:if test="marc:subfield[@code='3']">
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'3'"/>
                    <xsl:value-of select="marc:subfield[@code='3']/text()"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    
    <!--Template für Feld 505-->
    <xsl:template name="title_505">
        
        <!--Wenn der Inhalt in $a ist, dann wird er
        in Feld 520 gepackt-->
        <xsl:choose>
            <xsl:when test="marc:subfield[@code='a']">
                <xsl:element name="datafield">
                    <xsl:attribute name="tag" select="'520'"/>
                    <xsl:attribute name="ind1" select="'8'"/>
                    <!--'No display constant generated' - korrekt?-->
                    <xsl:attribute name="ind2" select="' '"/>
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'a'"/>
                        <xsl:value-of select="marc:subfield[@code='a']/text()"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            
            <!--Andernfalls wird der Inhalt in ein Feld 
            505 geschrieben. Achtung: Indikatoren
            richtig setzen und unerlaubte Unterfelder
            mappen-->
            <xsl:otherwise>
                <xsl:element name="{local-name()}">
                    <xsl:attribute name="tag" select="@tag"/>
                    <xsl:attribute name="ind1" select="'0'"/>
                    <!--'Contents'-->
                    <xsl:attribute name="ind2" select="'0'"/>
                    <!--'Enhanced'-->
                    
                    <!--Schreiben der Unterfelder. Es sollen nur
                    $g, $t und $r übernommen werden-->                    
                    <xsl:for-each select="marc:subfield">
                        <xsl:choose>
                            <xsl:when test="matches(@code, 'g|t|r|u|6|8')">
                                <xsl:choose>
                                    <!--Bei Unterfeld t sollen die spitzen                    
                    Klammern rausgenommen werden.
                    Keine Wegsortierung von Artikeln?-->
                                    <xsl:when test="@code='t'">
					<xsl:element name="{local-name()}">
                                            <xsl:attribute name="code" select="'t'"/>
					    <xsl:value-of select="replace(./text(), '&lt;|&gt;', '')"/>
                                        </xsl:element>
                                    </xsl:when>
                                    
                                    <!--Die anderen Marc21-konformen
                                        Unterfelder sollen kopiert werden-->
                                    <xsl:otherwise>
                                        <xsl:element name="{local-name()}">
                                            <xsl:for-each select="@*">
                                                <xsl:copy-of select="."/>
                                                <xsl:value-of select="../text()"/>
                                            </xsl:for-each>      
                                        </xsl:element>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:element> 
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
   <!--Template für die Erstellung des Feld 541.
   Der Kaufpreis in $h soll nicht kopiert
   werden.-->
   <xsl:template name="acquisition">
       <xsl:element name="datafield">
           <xsl:attribute name="tag" select="'541'"/>
           <xsl:attribute name="ind1" select="' '"/>
           <xsl:attribute name="ind2" select="' '"/>
           <xsl:for-each select="marc:subfield[@code != 'h' and @code != 'b']">
               <xsl:element name="{local-name()}">
                   <xsl:for-each select="@*">
                       <xsl:copy-of select="."/>
                       <xsl:value-of select="../text()"/>
                   </xsl:for-each>      
               </xsl:element>
           </xsl:for-each>
       </xsl:element>
   </xsl:template>
    
   <!--Template für die Erstellung der Felder 
   490 und 773-->
   <xsl:template name="linking_fields">
       
       <!--Kopieren der Unterfelder ausser $w-->
       <xsl:for-each select="marc:subfield[@code != 'w' and @code != 'y']">
           <xsl:element name="{local-name()}">
               <xsl:for-each select="@*">
                   <xsl:copy-of select="."/>
                   <xsl:choose>
                       <xsl:when test="..[@code='t']">
                           <xsl:value-of select="replace(../text(), '&lt;|&gt;', '')"/>  
                       </xsl:when>
                       <xsl:otherwise>
                           <xsl:value-of select="../text()"/>
                       </xsl:otherwise>
                   </xsl:choose>  
               </xsl:for-each>      
           </xsl:element>
       </xsl:for-each>
       
       <!--Vor die Systemnr. in $w soll ein 'HAN'
       gehängt werden-->       
       
       <xsl:if test="marc:subfield[@code='w']">
           <xsl:element name="subfield">
               <xsl:attribute name="code" select="'w'"/>
               <xsl:call-template name="systemnr_link"/>
           </xsl:element>              
           
           <!--Unterfeld $9 momentan nur zu Testzwecken 
           im Skript - bitte auskommentieren-->
           <!--Zusätzlich soll die Systemnr. in $9
           geschrieben werden für die Abbildung
           der Hierarchie-->
           <xsl:element name="subfield">
               <xsl:attribute name="code" select="'9'"/>
               <xsl:call-template name="systemnr_link"/>
           </xsl:element> 
       </xsl:if>

       <xsl:if test="marc:subfield[@code='y']">
           <xsl:element name="subfield">
               <xsl:attribute name="code" select="'y'"/>
               <xsl:call-template name="systemnr_link_y"/>
           </xsl:element>
       </xsl:if>

   </xsl:template>
   
   
   <!--Template für die Erstellung des Unterfelds w und 9 in Feldern 
   490 und 773 mit führenden Nullen-->
    
   <xsl:template name="systemnr_link">
       <xsl:variable name="sysnr_length" select="string-length(marc:subfield[@code='w']/text())"/>
       
       <!--Wenn die Systemnr. unter 9 Stellen hat,
               sollen führende Nullen angehängt werden;
               es scheint keine Funktion zu geben, die 
               den String '0' mit einem Integer 
               multiplizieren kann-->
       <xsl:choose>
           <xsl:when test="$sysnr_length eq 8">
               <xsl:value-of select="concat('HAN0', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 7">
               <xsl:value-of select="concat('HAN00', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 6">
               <xsl:value-of select="concat('HAN000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 5">
               <xsl:value-of select="concat('HAN0000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 4">
               <xsl:value-of select="concat('HAN00000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 3">
               <xsl:value-of select="concat('HAN000000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 2">
               <xsl:value-of select="concat('HAN0000000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 1">
               <xsl:value-of select="concat('HAN00000000', marc:subfield[@code='w']/text())"/>
           </xsl:when>
           <xsl:otherwise>
               <xsl:value-of select="concat('HAN', marc:subfield[@code='w']/text())"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:template>

    <xsl:template name="systemnr_link_y">
       <xsl:variable name="sysnr_length" select="string-length(marc:subfield[@code='y']/text())"/>

       <!--Wenn die Systemnr. unter 9 Stellen hat,
               sollen führende Nullen angehängt werden;
               es scheint keine Funktion zu geben, die
               den String '0' mit einem Integer
               multiplizieren kann-->
       <xsl:choose>
           <xsl:when test="$sysnr_length eq 8">
               <xsl:value-of select="concat('HAN0', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 7">
               <xsl:value-of select="concat('HAN00', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 6">
               <xsl:value-of select="concat('HAN000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 5">
               <xsl:value-of select="concat('HAN0000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 4">
               <xsl:value-of select="concat('HAN00000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 3">
               <xsl:value-of select="concat('HAN000000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 2">
               <xsl:value-of select="concat('HAN0000000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:when test="$sysnr_length eq 1">
               <xsl:value-of select="concat('HAN00000000', marc:subfield[@code='y']/text())"/>
           </xsl:when>
           <xsl:otherwise>
               <xsl:value-of select="concat('HAN', marc:subfield[@code='y']/text())"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:template>
    
    <!-- Template für Feld 856 -->
    <xsl:template name="URL">
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
            <!--Zusätzliches Unterfeld B mit dem Verbundcode-->
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'B'"/>
                <xsl:text>HAN</xsl:text>
            </xsl:element>
        </xsl:element>
        
    </xsl:template>
    
    
    <!--Template für die Verarbeitung von Schlagwort-
    Feldern-->
    <xsl:template name="subject">
        <xsl:choose>
            

            <!-- Wenn es sich um 6xx-Felder mit $2resource handelt, Inhalt in 690 schreiben mit Herkunft
            und ursprünglichen Indikatoren in $2-->
            <xsl:when test="marc:subfield[@code='2']/text() = 'resource'">
                <xsl:element name="{local-name()}">
                    <xsl:attribute name="tag" select="'690'"/>
                    <xsl:attribute name="ind1" select="' '"/>
                    <xsl:attribute name="ind2" select="'7'"/>
                    <xsl:variable name="resource_com">
                        <xsl:for-each select="marc:subfield">
                            <xsl:choose>
                                <xsl:when test="@code='2'"></xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(./text(), ', ')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>

                    <!--Komma hinten abschneiden-->
                    <xsl:variable name="recource_content" select="concat($resource_com, '++')"/>
                    <xsl:variable name="recource_sequence" select="substring-before($recource_content, ', ++')"/>

                    <!--Inhalt in Unterfeld a schreiben-->
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'a'"/>
                        <xsl:value-of select="$recource_sequence"/>
                    </xsl:element>
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'2'"/>
                        <xsl:text>han</xsl:text>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <!-- Wenn es sich um 690er handelt, Inhalt in 690 schreiben mit Herkunft und ursprünglichen Indikatoren in $2-->
            <xsl:when test="@tag='690'">
                <xsl:variable name="ind1_origin" select="./@ind1"/>   
                <xsl:variable name="ind2_origin" select="./@ind2"/>   
                <xsl:element name="{local-name()}">
                    <xsl:attribute name="tag" select="'690'"/>
                    <xsl:attribute name="ind1" select="' '"/>
                    <xsl:attribute name="ind2" select="'7'"/>
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'a'"/>
                        <xsl:value-of select="marc:subfield[@code='a']/text()"/>
                    </xsl:element>
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'2'"/>
                        <xsl:value-of select="concat('han ', $ind1_origin, $ind2_origin)"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <!-- Wenn die Normdatei für die Sacherschliessung in $2 spezifiziert ist -->
            <xsl:when test="@ind2='7' and marc:subfield[@code='2']">
                <xsl:call-template name="copy_datafields">
                    <xsl:with-param name="copy_mode" select="'heading'"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Ansonsten Inhalt in Feld 653 schreiben -->
            <xsl:otherwise>
                <xsl:element name="datafield">
                    <xsl:attribute name="tag" select="'653'"/>
                    <xsl:attribute name="ind1">
                        <xsl:text> </xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="ind2">
                        
                        <!--'Type of term or name' im 
                Indikator 2-->
                        <xsl:choose>
                            <xsl:when test="@tag='600'">
                                <xsl:text>1</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='610'">
                                <xsl:text>2</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='611'">
                                <xsl:text>3</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='650'">
                                <xsl:text>0</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='651'">
                                <xsl:text>5</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='655'">
                                <xsl:text>6</xsl:text>
                            </xsl:when>
                            <xsl:when test="@tag='690'">
                                <xsl:text> </xsl:text>
                            </xsl:when>
                        </xsl:choose>
                        
                    </xsl:attribute> 
                    
                    <!--Verarbeitung der Unterfelder. Wenn es ausser            
            $a andere Unterfelder gibt, sollen sie aneinander-
            gereiht werden-->
                    <xsl:variable name="cont_com">
                        <xsl:for-each select="marc:subfield">
                            <xsl:value-of select="concat(./text(), ', ')"/>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <!--Komma hinten abschneiden-->
                    <xsl:variable name="content" select="concat($cont_com, '++')"/>
                    <xsl:variable name="sequence" select="substring-before($content, ', ++')"/>
                    
                    <!--Inhalt in Unterfeld a schreiben-->
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'a'"/>
                        <xsl:value-of select="$sequence"/>
                    </xsl:element>
                </xsl:element>
            </xsl:otherwise>            
        </xsl:choose>  
        
    </xsl:template>
   
  
    <!--Template für die Vorbereitung von Feld 898 (Formatcodierung)-->
    <xsl:template name="format">
        <xsl:variable name="LDR_06" select="substring(../marc:leader/text(), 7, 1)"/>
        <xsl:variable name="LDR_07" select="substring(../marc:leader/text(), 8,1)"/>
        <xsl:variable name="format_main" select="../marc:datafield[@tag='906']/marc:subfield/text()"/>
        <xsl:variable name="format_side" select="../marc:datafield[@tag='907']/marc:subfield/text()"/>
        <xsl:choose>
            
            <!--Für Manuskripte-->
            <xsl:when test="$LDR_06='t'">
                <xsl:variable name="spec_1" select="'BK03'"/>
                <xsl:variable name="generic" select="'XK030000'"/>
                <xsl:variable name="hierarchy_1" select="'XH00'"/>
                <!--Code für Buch-->
                <xsl:choose>
                    <xsl:when test="$format_main='Briefe = Correspondance'">
                        <xsl:variable name="spec_2" select="'01'"/>
                        <xsl:variable name="hierarchy_2" select="'0100'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                           <!-- Wenn Brief, aber nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>                   
                        </xsl:choose>      
                    </xsl:when>
                    
                    <!--Wenn Manuskript, aber kein Brief-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>
                            
                            <!--Wenn online-Dokument-->
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/> 
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>                        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <!--Für Bilder-->
            <xsl:when test="$LDR_06='k'">
                <xsl:variable name="spec_1" select="'VM02'"/>
                <xsl:variable name="hierarchy_1" select="'XM02'"/>
                <xsl:choose>
                    
                    <!--Wenn Foto-->
                    <xsl:when test="$format_main='VM Foto = Photo'">
                        <xsl:variable name="spec_2" select="'04'"/>
                        <xsl:variable name="generic" select="'XM020400'"/>
                        <xsl:variable name="hierarchy_2" select="'0400'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when> 
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    
                    <!--Für Bildmaterial, das kein Foto ist-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XM020000'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>
                            
                            <!--Online-->
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>                                
                                <!--Bildmaterial-->
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>  
                            </xsl:when>
                            
                            <!--Nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>  
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!--Für Film, Dia-->
            <xsl:when test="$LDR_06='g'">
                <xsl:choose>

                    <!--Wenn Dia-->
                    <xsl:when test="$format_main='VM Diapositiv = Diapositive'">
                        <xsl:variable name="spec_1" select="'VM02'"/>
                        <xsl:variable name="spec_2" select="'01'"/>
                        <xsl:variable name="generic" select="'XM020000'"/>
                        <xsl:variable name="hierarchy_1" select="'XM02'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Wenn Film-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_1" select="'VM01'"/>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XM010000'"/>
                        <xsl:variable name="hierarchy_1" select="'XM01'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>

                            <!--Online-->
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>

                            <!--Nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>


            <!--Für Sprachaufnahmen-->
            <xsl:when test="$LDR_06='i'">
                <xsl:choose>

                    <!--Wenn Tonband-->
                    <xsl:when test="$format_main='SR Tonband-Kompaktkassette = Cassette audio'">
                        <xsl:variable name="spec_1" select="'MU03'"/>
                        <xsl:variable name="spec_2" select="'06'"/>
                        <xsl:variable name="generic" select="'XU030000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU03'"/>
                        <xsl:variable name="hierarchy_2" select="'0600'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Wenn Schallplatte-->
                    <xsl:when test="$format_main='SR Schallplatte = Disque 78'">
                        <xsl:variable name="spec_1" select="'MU03'"/>
                        <xsl:variable name="spec_2" select="'05'"/>
                        <xsl:variable name="generic" select="'XU030000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU03'"/>
                        <xsl:variable name="hierarchy_2" select="'0500'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Nicht Tonband oder Schallplatte-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_1" select="'MU03'"/>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XU030000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU03'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>

                            <!--Online-->
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>

                            <!--Nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!--Für Musikaufnahmen-->
            <xsl:when test="$LDR_06='j'">
                <xsl:choose>

                    <!--Wenn Tonband-->
                    <xsl:when test="$format_main='SR Tonband-Kompaktkassette = Cassette audio'">
                        <xsl:variable name="spec_1" select="'MU04'"/>
                        <xsl:variable name="spec_2" select="'06'"/>
                        <xsl:variable name="generic" select="'XU040000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU04'"/>
                        <xsl:variable name="hierarchy_2" select="'0600'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Wenn Schallplatte-->
                    <xsl:when test="$format_main='SR Schallplatte = Disque 78'">
                        <xsl:variable name="spec_1" select="'MU04'"/>
                        <xsl:variable name="spec_2" select="'05'"/>
                        <xsl:variable name="generic" select="'XU030000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU04'"/>
                        <xsl:variable name="hierarchy_2" select="'0500'"/>
                        <xsl:choose>
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Nicht Tonband oder Schallplatte-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_1" select="'MU04'"/>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XU040000'"/>
                        <xsl:variable name="hierarchy_1" select="'XU04'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>
                        <xsl:choose>

                            <!--Online-->
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>

                            <!--Nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
                
            <!--Für Bestände  -->  
            <xsl:when test="$LDR_06='p'">                
                <xsl:variable name="spec_1" select="'CL01'"/>
                
                <!--Momentan ist nicht erwünscht, dass Briefsammlungen als solche codiert
                werden (genau eine HAN-Aufnahme). Sie sollen auf XL010000
                gemappt werden-->
                
                <!--<xsl:choose>
                    
                    <!-\-Wenn Briefsammlung-\->
                    <xsl:when test="$format_main='Briefe = Correspondance'">
                        <xsl:variable name="spec_2" select="'01'"/>
                        <xsl:variable name="generic" select="'XK020100'"/>                       
                        <xsl:choose>
                            
                            <!-\-Wenn online-Briefsammlung-\->
                            <xsl:when test="$format_side=
                                'CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>                                    
                                </xsl:call-template> 
                            </xsl:when>
                            
                            <!-\-Wenn Briefsammlung, aber nicht online-\->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>       
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-\-Wenn Sammlung, aber keine Briefe-\->
                    <xsl:otherwise>-->
                        <xsl:variable name="specific" select="'CL010000'"/>
                        <xsl:variable name="generic" select="'XL010000'"/>
                        <xsl:variable name="hierarchy" select="'XL010000'"/>
                        <xsl:call-template name="format_898">
                            <xsl:with-param name="specific" select="$specific"/>
                            <xsl:with-param name="generic" select="$generic"/>
                            <xsl:with-param name="hierarchy" select="$hierarchy"/>
                        </xsl:call-template>
                    <!--</xsl:otherwise>-->
                <!--</xsl:choose>   -->             
            </xsl:when>


            <!--Für Objekte  -->
            <xsl:when test="$LDR_06='r'">
                <xsl:variable name="specific" select="'CL010000'"/>
                <xsl:variable name="generic" select="'XM030000'"/>
                <xsl:variable name="hierarchy" select="'XM030200'"/>
                <xsl:call-template name="format_898">
                    <xsl:with-param name="specific" select="$specific"/>
                    <xsl:with-param name="generic" select="$generic"/>
                    <xsl:with-param name="hierarchy" select="$hierarchy"/>
                </xsl:call-template>
            </xsl:when>

            <!--Für Musikmanuskripte-->
            <xsl:when test="$LDR_06='d'">
                <xsl:variable name="spec_1" select="'MU02'"/>
                <xsl:variable name="hierarchy_1" select="'XH00'"/>
                
                <!--Wenn Partitur-->
                <xsl:choose>
                    <xsl:when test="$format_main='PM Partitur = Partition'">
                        <xsl:variable name="spec_2" select="'01'"/>
                        <xsl:variable name="generic" select="'XU010100'"/>
                        <xsl:variable name="hierarchy_2" select="'0200'"/>
                        
                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>            
                    </xsl:when>
                    
                    <!--Wenn keine Partitur-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XU010000'"/>
                        <xsl:variable name="hierarchy_2" select="'0200'"/>

                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>                    
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!--Für Musikdrucke-->
            <xsl:when test="$LDR_06='c'">
                <xsl:variable name="spec_1" select="'MU01'"/>
                <xsl:variable name="hierarchy_1" select="'XU01'"/>

                <!--Wenn Partitur-->
                <xsl:choose>
                    <xsl:when test="$format_main='PM Partitur = Partition'">
                        <xsl:variable name="spec_2" select="'01'"/>
                        <xsl:variable name="generic" select="'XU010100'"/>
                        <xsl:variable name="hierarchy_2" select="'0100'"/>

                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>

                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!--Wenn keine Partitur-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XU010000'"/>
                        <xsl:variable name="hierarchy_2" select="'0000'"/>

                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:when>

                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="concat($hierarchy_1, $hierarchy_2)"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
                
            
            <!--Für Kartenmaterial - Manuskript-->
            <xsl:when test="$LDR_06='f'">
                <xsl:variable name="spec_1" select="'MP02'"/>
                <xsl:variable name="spec_2" select="'00'"/>
                <xsl:variable name="generic" select="'XP010000'"/>
                <xsl:variable name="hierarchy" select="'XH000300'"/>
                
                <!--Wenn online-->
                <xsl:choose>
                    <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                        <xsl:variable name="spec_3" select="'53'"/>     
                        <xsl:call-template name="format_898">
                            <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                            <xsl:with-param name="generic" select="$generic"/>
                            <xsl:with-param name="hierarchy" select="$hierarchy"/>
                        </xsl:call-template>
                    </xsl:when>
                    
                    <!--Wenn nicht online-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_3" select="'00'"/>     
                        <xsl:call-template name="format_898">
                            <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                            <xsl:with-param name="generic" select="$generic"/>
                            <xsl:with-param name="hierarchy" select="$hierarchy"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:when>

            <!--Für Kartenmaterial - Druck-->
            <xsl:when test="$LDR_06='e'">
                <xsl:variable name="spec_1" select="'MP01'"/>
                <xsl:variable name="spec_2" select="'00'"/>
                <xsl:variable name="generic" select="'XP010000'"/>
                <xsl:variable name="hierarchy" select="'XP010000'"/>

                <!--Wenn online-->
                <xsl:choose>
                    <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                        <xsl:variable name="spec_3" select="'53'"/>
                        <xsl:call-template name="format_898">
                            <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                            <xsl:with-param name="generic" select="$generic"/>
                            <xsl:with-param name="hierarchy" select="$hierarchy"/>
                        </xsl:call-template>
                    </xsl:when>

                    <!--Wenn nicht online-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_3" select="'00'"/>
                        <xsl:call-template name="format_898">
                            <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                            <xsl:with-param name="generic" select="$generic"/>
                            <xsl:with-param name="hierarchy" select="$hierarchy"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!--Für gedruckte Texte-->
            <xsl:when test="$LDR_06='a'">
                <xsl:choose> 
                    
                    <!--Wenn Analyticum-->
                    <xsl:when test="$LDR_07='a'">
                        <xsl:variable name="spec_1" select="'BK01'"/>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XK010000'"/>
                        <xsl:variable name="hierarchy" select="'XK010000'"/>
                        <!--Artikel-->
                        
                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="$hierarchy"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="$hierarchy"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>           
                    </xsl:when>
                    
                    <!--Wenn selbständig (LDR_07='m')-->
                    <xsl:otherwise>
                        <xsl:variable name="spec_1" select="'BK02'"/>
                        <xsl:variable name="spec_2" select="'00'"/>
                        <xsl:variable name="generic" select="'XK020000'"/>
                        <xsl:variable name="hierarchy" select="'XK020000'"/>
                        <!--Buch-->
                        
                        <!--Wenn online-->
                        <xsl:choose>
                            <xsl:when test="$format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                                <xsl:variable name="spec_3" select="'53'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="$hierarchy"/>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Wenn nicht online-->
                            <xsl:otherwise>
                                <xsl:variable name="spec_3" select="'00'"/>     
                                <xsl:call-template name="format_898">
                                    <xsl:with-param name="specific" select="concat($spec_1, $spec_2, $spec_3)"/>
                                    <xsl:with-param name="generic" select="$generic"/>
                                    <xsl:with-param name="hierarchy" select="$hierarchy"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                     
            </xsl:when> 
            
        </xsl:choose>        
    </xsl:template>
    
    
    <!--Template für die Erstellung des Felds 898-->
    <xsl:template name="format_898">        
        <xsl:param name="specific">xxx</xsl:param>       
        <xsl:param name="generic">yyy</xsl:param>
        <xsl:param name="hierarchy">zzz</xsl:param>
        <xsl:element name="datafield">
            <xsl:attribute name="tag">
                <xsl:text>898</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ind1">
                <xsl:text> </xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ind2">
                <xsl:text> </xsl:text>
            </xsl:attribute>
            <xsl:element name="subfield">
                <xsl:attribute name="code">
                    <xsl:text>a</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$specific"/>
            </xsl:element>
            <xsl:element name="subfield">
                <xsl:attribute name="code">
                    <xsl:text>b</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$generic"/>
            </xsl:element>
            <xsl:element name="subfield">
                <xsl:attribute name="code">
                    <xsl:text>c</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$hierarchy"/>
            </xsl:element>
        </xsl:element>
        
    </xsl:template>
    
    <!--Template für die Erstellung des Felds 908
    (Inhalt aus 906 bzw. 907)-->
    <xsl:template name="format_908">
        <xsl:element name="datafield">
            <xsl:attribute name="tag" select="'908'"/>
            <xsl:attribute name="ind1" select="' '"/>
            <xsl:attribute name="ind2" select="' '"/>
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'D'"/>
                <xsl:choose>
                    <xsl:when test="@tag='906'">
                        <xsl:text>1</xsl:text>
                    </xsl:when>
                    <xsl:when test="@tag='907'">
                        <xsl:text>2</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:element>
            <xsl:for-each select="marc:subfield">
                <xsl:element name="{local-name()}">
                    <xsl:for-each select="@*">
                        <xsl:copy-of select="."/>
                        <xsl:value-of select="../text()"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>  
    </xsl:template>
    
    
<!--Template für die Erstellung von Feld 561 für alternative und ehemalige Signaturen )-->

    <xsl:template name="other_signature">
        <xsl:element name="datafield">
            <xsl:attribute name="tag" select="'561'"/>
            <xsl:attribute name="ind1" select="' '"/>
            <xsl:attribute name="ind2" select="' '"/>
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'a'"/>
                <xsl:if test="@ind1='A'">
                    <xsl:value-of select="concat('Alternative Signatur: [', marc:subfield[@code='n']/text(), ' ', marc:subfield[@code='a']/text(), ' ' , marc:subfield[@code='b']/text(), ': ', marc:subfield[@code='p']/text())"/>
                </xsl:if>
                <xsl:if test="@ind1='E'">
                    <xsl:value-of select="concat('Ehemalige Signatur: [', marc:subfield[@code='n']/text(), ' ', marc:subfield[@code='a']/text(), ' ' , marc:subfield[@code='b']/text(), ': ', marc:subfield[@code='p']/text())"/>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

<!--Template für die Erstellung von Feld 949 (Exemplare)-->

    <xsl:template name="HOL">
        <xsl:variable name="inst_code" select="marc:subfield[@code='a']/text()"/>
        <xsl:element name="datafield">
            <xsl:attribute name="tag" select="'949'"/>
            <xsl:attribute name="ind1" select="' '"/>
            <xsl:attribute name="ind2" select="' '"/>
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'B'"/>
                <xsl:text>HAN</xsl:text>
            </xsl:element>
            
            <!-- Die folgenden Unterfelder sollen nur geschrieben werden, falls
            $a (Name der Institution) vorhanden -->
            <xsl:choose>
                
                <!-- $0 mit Name der Institution -->
                <xsl:when test="marc:subfield[@code='a']">
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'0'"/>
                        <xsl:value-of select="marc:subfield[@code='a']/text()"/>
                    </xsl:element>
                    
                    <!-- In die Unterfelder F und b soll der Code für die jeweilige Institution 
            geschrieben werden (dopelt)-->
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'F'"/>
                        <xsl:choose>
                            <xsl:when test="$inst_code='Basel UB'">
                                <xsl:text>A100</xsl:text>                      
                            </xsl:when>
                            <xsl:when test="$inst_code='Basel UB Wirtschaft - SWA'">
                                <xsl:text>A125</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Bern Gosteli-Archiv'">
                                <xsl:text>B445</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Bern UB Medizingeschichte: Rorschach-Archiv'">
                                <xsl:text>HAN001</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Luzern ZHB'">
                                <xsl:text>LUZHB</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='KB Appenzell Ausserrhoden'">
                                <xsl:text>SGARK</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='St. Gallen KB Vadiana'">
                                <xsl:text>SGKBV</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='St. Gallen Stiftsbibliothek'">
                                <xsl:text>SGSTI</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Solothurn ZB'">
                                <xsl:text>ZBSO</xsl:text>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:element>
                    
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'b'"/>
                        <xsl:choose>
                            <xsl:when test="$inst_code='Basel UB'">
                                <xsl:text>A100</xsl:text>                      
                            </xsl:when>
                            <xsl:when test="$inst_code='Basel UB Wirtschaft - SWA'">
                                <xsl:text>A125</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Bern Gosteli-Archiv'">
                                <xsl:text>B445</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Bern UB Medizingeschichte: Rorschach-Archiv'">
                                <xsl:text>HAN001</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Luzern ZHB'">
                                <xsl:text>LUZHB</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='KB Appenzell Ausserrhoden'">
                                <xsl:text>SGARK</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='St. Gallen KB Vadiana'">
                                <xsl:text>SGKBV</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='St. Gallen Stiftsbibliothek'">
                                <xsl:text>SGSTI</xsl:text>
                            </xsl:when>
                            <xsl:when test="$inst_code='Solothurn ZB'">
                                <xsl:text>ZBSO</xsl:text>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:element>
                </xsl:when>
            </xsl:choose>
            
            <!-- Systemnr. -->
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'E'"/>
                <xsl:value-of select="concat('HAN', ../marc:controlfield[@tag='001']/text())"/>
            </xsl:element>
            
            <!-- Abteilung -->
            <xsl:choose>
                <xsl:when test="marc:subfield[@code='b']">
                    <xsl:element name="subfield">
                        <xsl:attribute name="code" select="'1'"/>
                        <xsl:value-of select="marc:subfield[@code='b']/text()"/>
                    </xsl:element>
                </xsl:when>
            </xsl:choose>            
            
            <!-- Signatur -->
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'j'"/>
                <xsl:value-of select="marc:subfield[@code='p']/text()"/>
            </xsl:element>
            
            <!--Alternativsignatur kommt in Unterfeld s für "Signatur 2"-->
            <xsl:if test="../marc:datafield[@tag='852' and @ind1='A']">
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'s'"/>
                    <xsl:value-of select="../marc:datafield[@tag='852' and @ind1='A']/marc:subfield[@code='p']/text()"/>
                </xsl:element>
            </xsl:if>
            
            <!--Permalink erstellen--> 
            <xsl:element name="subfield">
                <xsl:attribute name="code" select="'u'"/>
                <xsl:value-of select="concat('http://aleph.unibas.ch/F/?local_base=DSV05&amp;con_lng=GER&amp;func=find-b&amp;find_code=SYS&amp;request=', ../marc:controlfield[@tag='001']/text())"/>
            </xsl:element>
            
            <!-- Zugang -->
            <xsl:if test="marc:subfield[@code='q']">
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'z'"/>
                    <xsl:value-of select="marc:subfield[@code='q']/text()"/>
                </xsl:element>
            </xsl:if>
            
            <xsl:if test="marc:subfield[@code='z']">
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'z'"/>
                    <xsl:value-of select="marc:subfield[@code='z']/text()"/>
                </xsl:element>
            </xsl:if>
            
        </xsl:element>
    </xsl:template>
    
    <!-- Template für die Erstellung der Felder 950-->    
    <xsl:template name="copied_info">
        <xsl:for-each select="../marc:datafield[@tag='100'] | 
                            ../marc:datafield[@tag='110'] | 
                            ../marc:datafield[@tag='111'] | 
                            ../marc:datafield[@tag='700'] |
                            ../marc:datafield[@tag='710'] |
                            ../marc:datafield[@tag='490'] |
                            ../marc:datafield[@tag='773'] | 
                            ../marc:datafield[@tag='856']">
            
            <xsl:element name="datafield">
                <xsl:attribute name="tag" select="'950'"/>
                <xsl:attribute name="ind1" select="' '"/>
                <xsl:attribute name="ind2" select="' '"/>
             
                <!--In jedem Fall müssen in Feld 950 folgende Unterfelder geschrieben werden-->
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'B'"/>
                    <xsl:text>HAN</xsl:text>
                </xsl:element>
                
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'P'"/>
                    <xsl:choose>
                        <xsl:when test="@tag='490'">
                            <xsl:text>499</xsl:text>
                        </xsl:when>
                        <xsl:when test="@tag='773'">
                            <xsl:text>779</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@tag"/>
                        </xsl:otherwise>
                    </xsl:choose>  
                </xsl:element>
                    
                <!--Erstellen von Unterfeld E -->
                <xsl:element name="subfield">
                    <xsl:attribute name="code" select="'E'"/>
                    <xsl:variable name="indicators" select="concat(@ind1, @ind2)"/>
                    <xsl:variable name="ind_replaced" select="replace($indicators, ' ', '-')"/>
                    <xsl:value-of select="$ind_replaced"/>
                </xsl:element>
                                    
                <!-- Je nach Art der kopierten Felder müssen spezielle Details
                    verändert werden -->
                <xsl:choose>  
                    
                    <!--Bei 773 und 490 muss vor die Systemnr.
                    in Unterfeld w ein 'HAN' gehängt werden-->
                    <xsl:when test="matches(@tag, '490|773')">
                        <xsl:call-template name="linking_fields"/>                                   
                    </xsl:when>
                    
                    <!-- Bei normierten Sucheinstiegen müssen spezielle
                    Unterfelder geschrieben werden -->
                    <xsl:when test="matches(@tag, '[17][0135][012]')">
                        <xsl:for-each select="marc:subfield">
                            <xsl:call-template name="heading_subfields"/>
                        </xsl:for-each>                       
                    </xsl:when>
                    
                    <!--Andernfalls sollen einfach alle Unterfelder
                    kopiert werden-->
                    <xsl:otherwise>
                        
                        <xsl:for-each select="marc:subfield">
                            <xsl:element name="{local-name()}">
                                <xsl:for-each select="@*">
                                    <xsl:copy-of select="."/>
                                    <xsl:value-of select="../text()"/>
                                </xsl:for-each>      
                            </xsl:element>
                        </xsl:for-each> 
                        
                    </xsl:otherwise>                        
                         
                </xsl:choose>
            </xsl:element>
        </xsl:for-each>
        
        <!--An dieser Stelle soll das Format-Template aufgerufen werden-->
        <xsl:call-template name="format"/>
    </xsl:template>
       
</xsl:stylesheet>   
