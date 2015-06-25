<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                version="2.0"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

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
        <marc:collection >
            <!-- start processing of record nodes -->
            <xsl:apply-templates/>
        </marc:collection>
    </xsl:template>

    <!-- =======================================
         Sektion zur Erstellung der marc:record-Datenstruktur
         =======================================
    -->

    <xsl:template match="marc:record">
        <marc:record>
            <marc:controlfield tag="001">
                <xsl:value-of select="concat('HAN', marc:controlfield[@tag='001']/text())" />
            </marc:controlfield>
        </marc:record>
    </xsl:template>

</xsl:stylesheet>
