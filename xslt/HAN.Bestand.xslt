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
                <xsl:when test="@tag='100' or @tag='700'">
                    <xsl:element name="{local-name()}">
                        <xsl:attribute name="tag">
                            <xsl:value-of select="@tag"/>
                        </xsl:attribute>
                        <xsl:call-template name="pers_entry"/> 
                    </xsl:element>                                                        
                </xsl:when>                
                <xsl:when test="@tag='541'"/>  
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
                <xsl:when test="@tag='901'">  
                    <datafield tag="700">
                        <xsl:call-template name="pers_entry_spfield"/>
                    </datafield>                    
                </xsl:when>
                <xsl:when test="@tag='902'">
                    <datafield tag="710">
                        <xsl:call-template name="corp_entry_spfield"/>
                    </datafield>                    
                </xsl:when>
                <xsl:when test="@tag='903'"/>
                <xsl:when test="@tag='906' or @tag='907'">
                    <xsl:call-template name="format"/>
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
            <xsl:when test="$field_number='950'"/>
            
            <!--Andernfalls hängen die Indikatoren von der Art des Namens ab-->
            <xsl:otherwise>
                <xsl:choose>
                    <!--Zuerst sollen die Indikatoren geschrieben werden-->
                    <xsl:when test="$field_number='950'"/>
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
                   
        <!--Dann soll das passende Template aufgerufen werden,
        um die Unterfelder zu schreiben-->
                
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
                
                <!--Wenn ein Feld 950 geschrieben wird, brauchen wir ein 
                Unterfeld E. Der erste Indikator ist 0, weil der Name
                nach dem Vornamen angesetzt wird-->
                <xsl:choose>            
                    <xsl:when test="$field_number='950'">
                        <subfield code="E">
                            <!--Wenn der Name keinen Zusatz hat und keinen Nachnamen 
                    (kein Komma), wird davon ausgegangen, dass es der
                    Vorname ist-->
                            <xsl:text>0-</xsl:text>
                        </subfield>
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
        <xsl:for-each select="marc:subfield[@code != 'a']">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>
                    <xsl:value-of select="../text()"/>
                </xsl:for-each>                        
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <!--Template, das eine Eintragung kopiert, aber $a Name + Zusatz schreibt-->
    
    <!--Der Default-Wert des Parameters 'field_number' ist auf 700
        gesetzt, um ihn vom Wert 950 zu unterscheiden. Es kann sich
        natürlich auch um ein Feld 100 handeln-->
    <xsl:template name="pers_entry_spname">
        <xsl:param name="field_number">700</xsl:param>
        <xsl:variable name="single_name" select="marc:subfield[@code='a']/text()"/>
        <xsl:variable name="add_name" select="marc:subfield[@code='c']/text()"/>            
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
    </xsl:template>
    
    
    <!--Template für die Verarbeitung von Feld 901-->
    
    <!--Enthält vorläufig redundanten Code, der in anderen pers_entry-Templates
    auch vorkommt, weil sonst die Navigation zwischen den Templates zu komplex wird-->
    
    <xsl:template name="pers_entry_spfield">
        <xsl:param name="field_number">700</xsl:param>
        <xsl:variable name="pers_name" select="marc:subfield[@code='a']/text()"/> 
        <xsl:variable name="pers_name_sur" select="marc:subfield[@code='a']/text()"/>
        <xsl:variable name="surname" select="substring-before($pers_name_sur, ',')"/>
        <xsl:variable name="forename" select="substring-after($pers_name_sur, ',')"/>
        <xsl:variable name="add_name" select="marc:subfield[@code='c']/text()"/>
        
       <!-- Wird ein Feld 700 oder 950 erstellt?
       Je nachdem wird Indikator 1 gefüllt-->
        <xsl:choose>
            <xsl:when test="$field_number='950'"/>
                <!--In diesem Fall sind beide Indikatoren leer, 
                sie wurden schon im Template 'copied_info'
                geschrieben-->                
            <xsl:otherwise>
                <!--Wenn wir kein Feld 950 schreiben, schrieben wir 
                    ein Feld 700, für welches Indikator 1  definiert wird-->
                <xsl:choose>
                    <!--Hat der Name das Muster 'Nachname, Vorname'?
                    Dann bekommt Indikator 1 den Wert 1-->            
                    <xsl:when test="contains($pers_name, ',')">                
                        <xsl:attribute name="ind1">
                            <xsl:text>1</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                    </xsl:when>
                    <!--Hat der Name das Muster 'Name + Zusatz'?
                    Dann bekommt Indikator 1 den Wert 0-->
                    <xsl:when test="marc:subfield[@code='c']">
                        <!--<xsl:variable name="single_name" select="marc:subfield[@code='a']/text()"/>-->
                        <xsl:attribute name="ind1">
                            <xsl:text>0</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
                
        <!--Nun wird die Namensansetzung in die korrekten Unterfelder geschrieben-->
        <xsl:choose>
            <!--Wenn Name, Vorname: -->
            <xsl:when test="contains($pers_name, ',')">
                <subfield code="a">
                    <xsl:value-of select="$surname"/>
                </subfield>
                <subfield code="D">
                    <xsl:value-of select="$forename"/>
                </subfield>
            </xsl:when>
            <!--Wenn Name + Zusatz:-->
            <xsl:when test="marc:subfield[@code='c']">                        
                <subfield code="a">
                    <xsl:value-of select="concat($pers_name, ' ', $add_name)"/>
                </subfield>
            </xsl:when>
        </xsl:choose>
        
        <!--Die restlichen Unterfelder sollen kopiert werden        -->
        <xsl:for-each select="marc:subfield[@code != 'a' and @code != 'c']">
            <xsl:element name="{local-name()}">
                <xsl:for-each select="@*">
                    <xsl:copy-of select="."/>
                    <xsl:value-of select="../text()"/>
                </xsl:for-each>                        
            </xsl:element>
        </xsl:for-each>
        
        <!--In jedem Fall wird das Unterfeld 4 mit dem 
        relator code erstellt-->
        <subfield code="4">
            <xsl:choose>
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
                    <xsl:text>dis</xsl:text>                        
                </xsl:when>
                <xsl:when test="@ind1='8'">
                    <xsl:text>opn</xsl:text>                        
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
                <xsl:otherwise/>
            </xsl:choose>
        </subfield>  
        
        <!--Wenn ein Feld 950 geschrieben wird, soll ein Unterfeld
        $E geschrieben werden-->
        <xsl:choose>
            <xsl:when test="$field_number='950'">
                <xsl:call-template name="copy_ind"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
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
    
    <!--Template zur Verarbeitung von Feld 902-->
    <xsl:template name="corp_entry_spfield">  
        <xsl:param name="field_number">710</xsl:param>
        <xsl:choose>
            <xsl:when test="$field_number='950'"/>
            <xsl:otherwise>
                <xsl:attribute name="ind1">           
                    <xsl:text>2</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="ind2">
                    <xsl:text> </xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>        
        <subfield code="a">
           <xsl:value-of select="marc:subfield[@code='a']/text()"/>
        </subfield>
        <subfield code="4">
           <xsl:choose>
               <xsl:when test="@ind1='1'">
                   <xsl:text>bnd</xsl:text>
               </xsl:when>
               <xsl:when test="@ind1='2'">
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
                   <xsl:text>???</xsl:text>
               </xsl:when>
               <xsl:when test="@ind1='B'">
                   <xsl:text>cli</xsl:text>
               </xsl:when>
               <xsl:when test="@ind1='P'">
                   <xsl:text>cre</xsl:text>
               </xsl:when>
           </xsl:choose> 
        </subfield> 
        
        <!--Wenn ein Feld 950 geschrieben wird, soll ein Unterfeld
        $E geschrieben werden-->
        <xsl:choose>
            <xsl:when test="$field_number='950'">
                <subfield code="E">
                    <xsl:text>2-</xsl:text>
                </subfield>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
  
    <!--Template. das Format-Feld 898 (Icon- und Facetten-Code) erstellt und aus 906 und 907 je ein Feld 908 macht-->
   <!-- Wird aufgerufen entweder durch Feld 351$c != 'Dokument=Item=Pièce' oder durch Feld 906-->
    <xsl:template name="format">
        <datafield tag="898" ind1=" " ind2=" ">
            <xsl:choose>
                <xsl:when test="@tag='906'">                    
                    <xsl:variable name="format_main" select="marc:subfield/text()"/>
                    <xsl:variable name="format_side" select="../marc:datafield[@tag='907']/marc:subfield/text()"/>
                    <xsl:choose>
                        <xsl:when test="$format_main='Briefe = Correspondance' and $format_side='CF Elektron. Daten Fernzugriff=Fichier online'">
                            <!--Stimmen die folgenden Codes?-->
                            <subfield code="a">
                                <xsl:text>BK030153</xsl:text>
                            </subfield>
                            <subfield code="b">
                                <xsl:text>BK030100</xsl:text>
                            </subfield>
                        </xsl:when>
                       <!-- Hier müssten noch für alle anderen möglichen Formate in 906 die Codes definiert werden-->
                        <xsl:otherwise/>
                    </xsl:choose>                     
                </xsl:when>
                <xsl:when test="@tag='351'">
                    <xsl:choose>
                        <xsl:when test="marc:subfield[@code='c']/text()='Bestand=Fonds'">
                            <subfield code="a">
                               <!-- "Sammlung (Brief) (online)": korrekt?-->
                                <xsl:text>CL010153</xsl:text>
                            </subfield>
                            <subfield code="b">
                                <!--"Sammlung": korrekt?-->
                                <xsl:text>CL010000 </xsl:text>
                            </subfield>
                        </xsl:when>
                        <!--Hier müssten noch alle anderen möglichen Werte von 351$c codiert werden, 
                            die Format-Icon und -Facette bestimmen-->
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
    </xsl:template>
    
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
        
        <!--An dieser Stelle soll das Template für Feld 950 aufgerufen werden, das es dann im Ausgabe-Record nach
        Feld 949 kommt-->
        <xsl:call-template name="copied_info"/>
    </xsl:template>
    
    <!-- Template für die Erstellung der Felder 950-->    
    <xsl:template name="copied_info">
        <xsl:for-each select="../marc:datafield[@tag='100'] | 
                            ../marc:datafield[@tag='700'] |
                            ../marc:datafield[@tag='490'] |
                            ../marc:datafield[@tag='773'] | 
                            ../marc:datafield[@tag='901'] |
                            ../marc:datafield[@tag='902']">
            <datafield tag="950" ind1=" " ind2=" ">                
                <xsl:choose>
                    <xsl:when test="matches(@tag, '[17]00')">
                        <xsl:call-template name="pers_entry">
                            <xsl:with-param name="field_number">950</xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>  
                    <xsl:when test="matches(@tag, '901')">                        
                        <xsl:call-template name="pers_entry_spfield">
                            <xsl:with-param name="field_number">950</xsl:with-param>
                        </xsl:call-template>                                                
                    </xsl:when>
                    <xsl:when test="matches(@tag, '902')">                        
                            <xsl:call-template name="corp_entry_spfield">
                                <xsl:with-param name="field_number">950</xsl:with-param>
                            </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        
                        <xsl:attribute name="ind1">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
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
                <xsl:choose>
                    <!--Unterfeld E wird in diesem Template nur für
                    Feld 773 und 490 erstellt. Für die Eintragungen 
                    wird Unterfeld E im jeweiligen Template erstellt-->
                    <xsl:when test="@tag='773' or @tag='490'">
                        <subfield code="E">
                            <xsl:choose>
                                <xsl:when test="@tag='773'">
                                    <xsl:value-of select="concat('-', ../marc:datafield[@tag='773']/@ind2)"/>
                                </xsl:when>
                                <xsl:when test="@tag='490'">
                                    <xsl:text>--</xsl:text>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </subfield>
                    </xsl:when>
                </xsl:choose>                
            </datafield>
        </xsl:for-each>
    </xsl:template>
   
</xsl:stylesheet>   
