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
                <controlfield tag="001">
                    <xsl:value-of select="concat('HAN', marc:controlfield[@tag='001']/text())"/>
                </controlfield>
                <controlfield tag="008">
                    <xsl:value-of select="marc:controlfield[@tag='008']/text()"/>
                </controlfield>                
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
                <xsl:when test="matches(@tag, '100|700|901')">
                    <xsl:element name="{local-name()}">
                        <xsl:attribute name="tag">
                            <xsl:value-of select="@tag"/>
                        </xsl:attribute>
                        <xsl:call-template name="pers_entry"/> 
                    </xsl:element>                                                        
                </xsl:when>  
                <xsl:when test="@tag='490' or @tag='773'">
                    <xsl:element name="{local-name()}">
                        <xsl:for-each select="@*">
                            <xsl:copy-of select="."/>                    
                        </xsl:for-each>
                        <xsl:call-template name="linking_fields"/> 
                    </xsl:element>                    
                </xsl:when>
                <xsl:when test="@tag='541'"/>  
                <xsl:when test="@tag='583'"/>
                <xsl:when test="@tag='593'"/>  
                <xsl:when test="@tag='CAT'"/>  
                <xsl:when test="@tag='852'">
                    <xsl:choose>
                        <xsl:when test="@ind1='A' or @ind1='E'"/>
                        <xsl:otherwise>
                            <xsl:call-template name="HOL"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="@tag='856'">
                    <xsl:call-template name="URL"/>
                </xsl:when>                
                <xsl:when test="matches(@tag,'710|902')">
                    <datafield tag="710">
                        <xsl:choose>
                            <xsl:when test="@tag='902'">
                                <xsl:call-template name="corp_entry">
                                    <xsl:with-param name="field_number">902</xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="corp_entry"/>
                            </xsl:otherwise>
                        </xsl:choose>                        
                    </datafield>                    
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
    </xsl:template>  
    
   <!--Template für die Erstellung der Felder 
   490 und 773-->
   <xsl:template name="linking_fields">
       <xsl:param name="field_number">xxx</xsl:param>
       
       <!--Wenn ein Feld 950 geschrieben wird, soll ein
       Unterfeld E erstellt werden-->
       <xsl:choose>
           <xsl:when test="$field_number='950'">
               <subfield code="E">
                   <xsl:choose>
                       <xsl:when test="@tag='773'">
                           <xsl:value-of select="concat('-', ../marc:datafield[@tag='773']/@ind2)"/>
                       </xsl:when>
                       
                       <!--Für Feld 490 sind die beiden 
                       Indikatoren leer-->
                       <xsl:otherwise>
                           <xsl:text>--</xsl:text>
                       </xsl:otherwise>
                   </xsl:choose>
               </subfield>
           </xsl:when>
       </xsl:choose>
       
       <!--Kopieren der Unterfelder ausser $w-->
       <xsl:for-each select="marc:subfield[@code != 'w']">
           <xsl:element name="{local-name()}">
               <xsl:for-each select="@*">
                   <xsl:copy-of select="."/>
                   <xsl:value-of select="../text()"/>
               </xsl:for-each>      
           </xsl:element>
       </xsl:for-each>
       
       <!--Vor die Systemnr. in $w soll ein 'HAN'
       gehängt werden-->
       <xsl:if test="marc:subfield[@code='w']">
           <subfield code="w">
               <xsl:value-of select="concat('HAN', marc:subfield[@code='w']/text())"/>
           </subfield>
       </xsl:if>
   </xsl:template>
    
   
    <!--Template für die (Vor-)Verarbeitung von Personeneintragungen
    aus den Feldern 100, 700-->
 
    <xsl:template name="pers_entry">
        <!--Was soll grundsätzlich mit Personennamen gemacht werden? 
        Einfügen in 700 oder 100 je nach Fall soll in anderen 
        Templates geschehen-->
        
        <!--Der Default-Wert des Parameters 'field_number' ist auf 700
        gesetzt, um ihn vom Wert 950 zu unterscheiden. Es kann sich
        natürlich auch um ein Feld 100 handeln-->
        <xsl:param name="field_number">700</xsl:param>
        <xsl:variable name="pers_name" select="marc:subfield[@code='a']/text()"/>
        
        <!--Wenn ein Feld 950 geschrieben wird, sind beide Indikatoren leer,
        sie wurden schon im Template 'copied_info' geschrieben-->
        
        <xsl:choose>
            <xsl:when test="$field_number='950'">
                <!-- Für Feld 950 muss ein Unterfeld E erstellt
                 werden-->
                <subfield code="E">
                    <xsl:call-template name="copy_ind"/>
                </subfield>
            </xsl:when>
            
            <!--Andernfalls hängen die Indikatoren von der Art des Namens ab-->
            <xsl:otherwise>
                <xsl:choose>
                    <!--Zuerst sollen die Indikatoren geschrieben werden-->
                    
                    <!--Hat der Name das Muster 'Nachname, Vorname'?--> 
                    <xsl:when test="contains($pers_name, ',')"> 
                        <xsl:attribute name="ind1">
                            <xsl:text>1</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                    </xsl:when>
                    <!--Wenn der Name aus einem Vornamen plus evtl.
                    Zusatz besteht: Ind1 = 0-->
                    <xsl:otherwise>                
                        <xsl:attribute name="ind1">
                            <xsl:text>0</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
                   
        <!--Dann soll der Name je nach Typ in die
        Unterfelder geschrieben werden-->
                
        <xsl:choose>                    
            <!--Nachname, Vorname?-->
            <xsl:when test="contains($pers_name, ',')">
                <xsl:choose>
                    <xsl:when test="$field_number='950'">
                        <xsl:call-template name="pers_entry_sur">
                            <xsl:with-param name="field_number">950</xsl:with-param>
                        </xsl:call-template>    
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="pers_entry_sur"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <!--Ansetzung nach Vorname? Felder kopieren-->
            <xsl:otherwise>
                <xsl:for-each select="marc:subfield">
                    <xsl:element name="{local-name()}">
                        <xsl:for-each select="@*">
                            <xsl:copy-of select="."/>
                            <xsl:value-of select="../text()"/>
                        </xsl:for-each>      
                    </xsl:element>
                </xsl:for-each>
                
                <!--Wenn es sich um eine Relatoren-Eintragung aus 
                Feld 901 handelt, muss für Ansetzungen nach dem
                Vornamen hier ein Unterfeld 4 geschrieben werden-->
                <xsl:choose>
                    <xsl:when test="@tag='901'">
                        <xsl:call-template name="relator_code"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!--Template, das Eintragungen kopiert, aber $a Nachname $D Vorname macht-->
    
    <!--Der Default-Wert des Parameters 'field_number' ist auf 700
        gesetzt, um ihn vom Wert 950 zu unterscheiden. Es kann sich
        natürlich auch um ein Feld 100 handeln-->
    <xsl:template name="pers_entry_sur">  
        <xsl:param name="field_number">700</xsl:param>
        <xsl:variable name="pers_name_sur" select="marc:subfield[@code='a']/text()"/>
        <xsl:variable name="surname" select="substring-before($pers_name_sur, ',')"/>
        <xsl:variable name="forename" select="substring-after($pers_name_sur, ',')"/>        
        <subfield code="a">               
            <xsl:value-of select="$surname"/>
        </subfield>
        <subfield code="D">
            <xsl:value-of select="$forename"/>
        </subfield>
        
        <!--Die restlichen Unterfelder sollen kopiert werden-->
        <xsl:for-each select="marc:subfield[@code != 'a']">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>
                    <xsl:value-of select="../text()"/>
                </xsl:for-each>                        
            </xsl:element>
        </xsl:for-each>
        
        <!-- Für Relatoren aus Feld 901 muss Ansetzungen 
            nach dem Nachnamen hier ein Unterfeld 4 erstellt werden-->
        <xsl:choose>
            <xsl:when test="@tag='901'">
                <xsl:call-template name="relator_code"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    
    <!--Template für die Erstellung eines
    relator code für Felder 901 und 902-->
    
    <xsl:template name="relator_code">
        <subfield code="4">
            <xsl:choose>
                <xsl:when test="@tag='901'">
                    <xsl:choose>
                        
                        <!--Liste der relator codes
                        für Personen-->
                        <xsl:when test="@ind1='1'">
                            <xsl:text>bnd</xsl:text>
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
                            <!--Beat: 'pra'-->
                            <xsl:text>dis</xsl:text>                        
                        </xsl:when>
                        <xsl:when test="@ind1='8'">
                            <!--Beat: 'rsp'-->
                            <xsl:text>opn</xsl:text>                        
                        </xsl:when>
                        <xsl:when test="@ind1='9'">
                            <xsl:text>rcp</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='A'">
                            <xsl:text>ill</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='B'">
                            <xsl:text>pat</xsl:text>
                            <!--'Patron'-->
                        </xsl:when>
                        <xsl:when test="@ind1='P'">
                            <xsl:text>cre</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:when test="@tag='902'">
                    <xsl:choose>
                        
                        <!--Liste der relator codes 
                        für Körperschaften-->
                        <xsl:when test="@ind1='1'">
                            <xsl:text>bnd</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='2'">
                            <!--Beat: 'scr'-->
                            <xsl:text>bkd</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='3'">
                            <xsl:text>ppm</xsl:text>
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
                        <xsl:when test="@ind1='9'">
                            <xsl:text>rcp</xsl:text>
                        </xsl:when>
                        <!--Code für "Atelier" noch ermitteln, nicht in Marc-Liste vorhanden-->
                        <xsl:when test="@ind1='A'">
                            <xsl:text>ill</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='B'">
                            <xsl:text>pat</xsl:text>
                        </xsl:when>
                        <xsl:when test="@ind1='P'">
                            <xsl:text>cre</xsl:text>
                        </xsl:when>
                    </xsl:choose> 
                </xsl:when>
            </xsl:choose>
        </subfield>  
    </xsl:template>
    
    
    <!--Template für das Erstellen von Unterfeld E in Feld 950 für 
    Personeneintragungen-->
        
    <!--In Unterfeld E sollen die Indikatoren des ursprünglichen
    700er-Felds geschrieben werden-->
     <xsl:template name="copy_ind">     
        <xsl:variable name="pers_name" select="marc:subfield[@code='a']/text()"/>
        <subfield code="E">
            <xsl:choose>
                <xsl:when test="contains($pers_name, ',')">
                    <xsl:text>1-</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>0-</xsl:text>
                </xsl:otherwise>
                <!--Wenn Eintragungen für Familien in den Daten vorkommen,
                muss hier eine dritte Option definiert werden-->
            </xsl:choose>
        </subfield>
    </xsl:template>
    
    <!--Template zur Verarbeitung von Körperschaftseintragungen 
    (Feld 710 und 902)-->
    <xsl:template name="corp_entry">  
        <xsl:param name="field_number">710</xsl:param>
        <xsl:choose>
            
            <!--Bei Feld 950 wurden die Indikatoren bereits
            im Template 'copied_info' geschrieben-->
            <xsl:when test="$field_number='950'"/>
            
            <xsl:otherwise>
                <!--Bei Feld 710 werden die Indikatoren
                an dieser Stelle geschrieben-->
                <xsl:attribute name="ind1"> 
                    <!--'Name in direct order'-->
                    <xsl:text>2</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="ind2">
                    <xsl:text> </xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose> 
        
        <!--Wenn ein Feld 950 geschrieben wird, soll ein Unterfeld
        $E geschrieben werden-->
        <xsl:choose>
            <xsl:when test="$field_number='950'">
                <subfield code="E">
                    <xsl:text>2-</xsl:text>
                </subfield>
            </xsl:when>
        </xsl:choose>
        
        <!--Kopieren der Unterfelder-->
        <xsl:for-each select="marc:subfield">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>
                    <xsl:value-of select="../text()"/>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
        
        <!--Wenn ein Feld 902 verarbeitet wird
        (zu 710 oder 950), soll ein Unterfeld 
        4 mit dem relator code geschrieben werden-->
        <xsl:choose>
            <xsl:when test="@tag='902'">
                <xsl:call-template name="relator_code"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
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
            <subfield code="B">
                <xsl:text>HAN</xsl:text>
            </subfield>
        </xsl:element>
        
        <!--Hier soll das Template für die Felder 950
        aufgerufen werden-->
        <xsl:call-template name="copied_info"/>
    </xsl:template>
    
  
    <!--Template. das Format-Feld 898 (Icon- und Facetten-Code) erstellt und aus 906 und 907 je ein Feld 908 macht-->
   <!-- Wird aufgerufen entweder durch Feld 351$c != 'Dokument=Item=Pièce' oder durch Feld 906-->
    <!--<xsl:template name="format">
        <datafield tag="898" ind1=" " ind2=" ">
            <xsl:choose>
                <xsl:when test="@tag='906'">                    
                    <xsl:variable name="format_main" select="marc:subfield/text()"/>
                    <xsl:variable name="format_side" select="../marc:datafield[@tag='907']/marc:subfield/text()"/>
                    <xsl:choose>
                        <xsl:when test="$format_main='Briefe = Correspondance' and $format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                            <!-\-Stimmen die folgenden Codes?-\->
                            <subfield code="a">
                                <xsl:text>BK030153</xsl:text>
                            </subfield>
                            <subfield code="b">
                                <xsl:text>BK030100</xsl:text>
                            </subfield>
                        </xsl:when>
                       <!-\- Hier müssten noch für alle anderen möglichen Formate in 906 die Codes definiert werden-\->
                        <xsl:otherwise/>
                    </xsl:choose>                     
                </xsl:when>
                <xsl:when test="@tag='351'">
                    <xsl:choose>
                        <xsl:when test="marc:subfield[@code='c']/text()='Bestand=Fonds'">
                            <subfield code="a">
                               <!-\- "Sammlung (Brief) (online)": korrekt?-\->
                                <xsl:text>CL010153</xsl:text>
                            </subfield>
                            <subfield code="b">
                                <!-\-"Sammlung": korrekt?-\->
                                <xsl:text>CL010000 </xsl:text>
                            </subfield>
                        </xsl:when>
                        <!-\-Hier müssten noch alle anderen möglichen Werte von 351$c codiert werden, 
                            die Format-Icon und -Facette bestimmen-\->
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>  
            <xsl:choose>
                <xsl:when test="@tag='906'">
                    <xsl:call-template name="format_908"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </datafield>
    </xsl:template>-->
    
    <xsl:template name="format_908">
        <datafield tag="908" ind1=" " ind2=" ">
            <subfield code="D">
                <xsl:choose>
                    <xsl:when test="@tag='906'">
                        <xsl:text>1</xsl:text>
                    </xsl:when>
                    <xsl:when test="@tag='907'">
                        <xsl:text>2</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </subfield>
            <subfield>
                <xsl:for-each select="marc:subfield/@*">
                    <xsl:copy-of select="."/>
                    <xsl:value-of select="../text()"/>
                </xsl:for-each>
            </subfield>            
        </datafield>     
    </xsl:template>
    
    
<!--Template für die Verarbeitung von Feld 852-->
    
    <xsl:template name="HOL">
        <xsl:variable name="inst_code" select="marc:subfield[@code='b']/text()"/>
        <datafield tag="949" ind1=" " ind2=" ">
            <subfield code="B">
                <xsl:text>HAN</xsl:text>
            </subfield>
            <subfield code='0'>
                <xsl:value-of select="marc:subfield[@code='b']/text()"/>
            </subfield>
           <!-- In die Unterfelder F und b soll der Code für die jeweilige Institution 
            geschrieben werden (dopelt)-->
            <subfield code="F">
                <xsl:choose>
                    <xsl:when test="$inst_code='Basel UB'">
                        <xsl:text>A100</xsl:text>                      
                    </xsl:when>
                    <xsl:when test="$inst_code='Basel UB Wirtschaft - SWA'">
                        <xsl:text>HAN001</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Bern Gosteli Archiv'">
                        <xsl:text>HAN002</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Bern UB Medizingeschichte: Rorschach-Archiv'">
                        <xsl:text>HAN003</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Luzern ZHB'">
                        <xsl:text>HAN004</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='KB Appenzell Ausserrhoden'">
                        <xsl:text>HAN005</xsl:text>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </subfield>
            <subfield code="b">
                <xsl:choose>
                    <xsl:when test="$inst_code='Basel UB'">
                        <xsl:text>A100</xsl:text>                      
                    </xsl:when>
                    <xsl:when test="$inst_code='Basel UB Wirtschaft - SWA'">
                        <xsl:text>HAN001</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Bern Gosteli Archiv'">
                        <xsl:text>HAN002</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Bern UB Medizingeschichte: Rorschach-Archiv'">
                        <xsl:text>HAN003</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='Luzern ZHB'">
                        <xsl:text>HAN004</xsl:text>
                    </xsl:when>
                    <xsl:when test="$inst_code='KB Appenzell Ausserrhoden'">
                        <xsl:text>HAN005</xsl:text>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </subfield>
            <subfield code="E">
                <xsl:value-of select="concat('HAN', ../marc:controlfield[@tag='001']/text())"/>
            </subfield>
            <subfield code="1">
                <xsl:value-of select="marc:subfield[@code='c']/text()"/>
            </subfield>
            <subfield code="j">
                <xsl:value-of select="marc:subfield[@code='d']/text()"/>
            </subfield>
            <!--Alternativsignatur kommt in Unterfeld s für "Signatur 2"-->
            <xsl:if test="../marc:datafield[@tag='852' and @ind1='A']">
                <subfield code='s'>
                    <xsl:value-of select="../marc:datafield[@tag='852' and @ind1='A']/marc:subfield[@code='d']/text()"/>
                </subfield>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='e']">
                <subfield code="z">
                    <xsl:value-of select="marc:subfield[@code='e']/text()"/>
                </subfield>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='z']">
                <subfield code='z'>
                    <xsl:value-of select="marc:subfield[@code='z']/text()"/>
                </subfield>
            </xsl:if>
            <xsl:if test="../marc:datafield[@tag='506']">
                <subfield code='z'>
                    <xsl:value-of select="../marc:datafield[@tag='506']/marc:subfield[@code='a']/text()"/>
                </subfield>
            </xsl:if>            
        </datafield>
        
        <!--Falls kein Feld 856 vorhanden ist, soll an dieser Stelle
        das Template für die Felder 950 aufgerufen werden-->
        <xsl:choose>
            <xsl:when test="../marc:datafield[@tag='856']"/>
            <xsl:otherwise>
                <xsl:call-template name="copied_info"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template für die Erstellung der Felder 950-->    
    <xsl:template name="copied_info">
        <xsl:for-each select="../marc:datafield[@tag='100'] | 
                            ../marc:datafield[@tag='700'] |
                            ../marc:datafield[@tag='710'] |
                            ../marc:datafield[@tag='490'] |
                            ../marc:datafield[@tag='773'] | 
                            ../marc:datafield[@tag='856'] | 
                            ../marc:datafield[@tag='901'] |
                            ../marc:datafield[@tag='902']">
            
            <datafield tag="950" ind1=" " ind2=" ">    
                <!--In jedem Fall müssen in Feld 950 folgende Unterfelder geschrieben werden-->
                <subfield code="B">
                    <xsl:text>HAN</xsl:text>
                </subfield>
                <subfield code="P">
                    <xsl:choose>
                        <xsl:when test="matches(@tag, '901')">
                            <xsl:text>700</xsl:text>
                        </xsl:when>
                        <xsl:when test="@tag='902'">
                            <xsl:text>710</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@tag"/>
                        </xsl:otherwise>
                    </xsl:choose>  
                </subfield>
                    
                <!--Erstellen von Unterfeld E und der 
                    kopierten Unterfelder-->
                <xsl:choose>
                    <xsl:when test="matches(@tag, '[17]00')">
                        <xsl:call-template name="pers_entry">
                            <xsl:with-param name="field_number">950</xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>  
                    <xsl:when test="matches(@tag, '901')">                        
                        <xsl:call-template name="pers_entry">
                            <xsl:with-param name="field_number">950</xsl:with-param>
                        </xsl:call-template>                                                
                    </xsl:when>
                    <xsl:when test="matches(@tag, '710|902')">                        
                            <xsl:call-template name="corp_entry">
                                <xsl:with-param name="field_number">950</xsl:with-param>
                            </xsl:call-template>
                    </xsl:when>
                    
                    <!--Wenn das übernommene Feld keine Personen-Eintragung
                    enthält, wird das Feld 950 direkt in diesem Template 
                    geschrieben-->
                    <xsl:otherwise> 
                        <xsl:choose>
                            <!--Bei 773 und 490 muss vor die Systemnr.
                            in Unterfeld w ein 'HAN' gehängt werden-->
                            <xsl:when test="matches(@tag, '490|773')">
                                <xsl:call-template name="linking_fields">
                                    <xsl:with-param name="field_number">950</xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!--Andernfalls sollen einfach alle Unterfelder
                            kopiert werden (Feld 856); im Unterfeld E sind zwei
                            leere Indikatoren-->
                            <xsl:otherwise>
                                <subfield code="E">
                                    <xsl:text>--</xsl:text>
                                </subfield>
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
                    </xsl:otherwise>
                </xsl:choose>
            </datafield>
        </xsl:for-each>
    </xsl:template>
   
</xsl:stylesheet>   
