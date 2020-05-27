<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.mpi.nl/tools/elan/EAFv2.7.xsd" version="2.0" xml:lang="en">
<xsl:output method="xml" doctype-public="-//W3C//DTD HTML 5 Transitional//EN" encoding="utf-8" indent="yes"/>

<xsl:param name="author"/>
<xsl:param name="version"/>
<xsl:param name="participant"/>
<xsl:param name="source_language_code"/>
<xsl:param name="translation_language_codes"/>

<xsl:template match="TEXT">
    <ANNOTATION_DOCUMENT>
        <xsl:attribute name="xsi:noNamespaceSchemaLocation">
            <xsl:text>http://www.mpi.nl/tools/elan/EAFv2.7.xsd</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="DATE">
            <xsl:value-of select="current-dateTime()"/>
        </xsl:attribute>
        <xsl:attribute name="AUTHOR">
            <xsl:value-of select="$author"/>
        </xsl:attribute>
        <xsl:attribute name="VERSION">
            <xsl:value-of select="$version"/>
        </xsl:attribute>
        <xsl:apply-templates select="HEADER"/>
        <xsl:apply-templates select="NOTE"/>
        <xsl:variable name="time_slots">
            <xsl:call-template name="create_time_slots"/>
        </xsl:variable>
        <xsl:call-template name="TIME_ORDER">
            <xsl:with-param name="time_slots" select="$time_slots"/>
        </xsl:call-template>
        <xsl:call-template name="S">
            <xsl:with-param name="time_slots" select="$time_slots"/>
        </xsl:call-template>
        <xsl:call-template name="S-TRANSL"/>
        <xsl:call-template name="W"/>
        <xsl:call-template name="W-TRANSL"/>
        <xsl:call-template name="LINGUISTIC_TYPE"/>
    </ANNOTATION_DOCUMENT>
</xsl:template>

<xsl:template match="HEADER">
    <HEADER>
        <xsl:attribute name="MEDIA_FILE">
            <xsl:text></xsl:text>
        </xsl:attribute>
        <xsl:attribute name="TIME_UNITS">
            <xsl:text>milliseconds</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="SOUNDFILE"/>
        <xsl:apply-templates select="TITLE"/>
    </HEADER>
</xsl:template>

<xsl:template match="SOUNDFILE">
    <MEDIA_DESCRIPTOR>
        <xsl:attribute name="MEDIA_URL">
            <xsl:value-of select="@href"/>
        </xsl:attribute>
        <xsl:attribute name="MIME_TYPE">
            <xsl:text>audio/x-wav</xsl:text>
        </xsl:attribute>
    </MEDIA_DESCRIPTOR>
</xsl:template>

<xsl:template match="TITLE">
    <PROPERTY>
        <xsl:attribute name="NAME">
            <xsl:text>title</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="LOCALE">
            <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
        <xsl:value-of select="."/>
    </PROPERTY>
</xsl:template>

<xsl:template match="NOTE">
    <PROPERTY>
        <xsl:attribute name="NAME">
            <xsl:text>note</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="LOCALE">
            <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
        <xsl:value-of select="@message"/>
    </PROPERTY>
</xsl:template>

<xsl:template name="TIME_ORDER">
    <xsl:param name="time_slots"/>
    <TIME_ORDER>
        <xsl:copy-of select="$time_slots"/>
    </TIME_ORDER>
</xsl:template>

<xsl:template name="TIME_SLOT">
    <xsl:param name="position"/>
    <TIME_SLOT>
        <xsl:attribute name="TIME_SLOT_ID">
            <xsl:text>ts</xsl:text>
            <xsl:value-of select="$position"/>
        </xsl:attribute>
        <xsl:attribute name="TIME_VALUE">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </TIME_SLOT>
</xsl:template>

<xsl:template name="create_time_slots">
    <xsl:variable name="time_slots">
        <xsl:for-each select="S/AUDIO">
            <time_slot><xsl:value-of select="round(@start * 1000)"/></time_slot>
            <time_slot><xsl:value-of select="round(@end * 1000)"/></time_slot>
        </xsl:for-each>
    </xsl:variable>
    <!-- Removal of duplicated time values for cleaner XML. -->
    <xsl:variable name="time_slots">
        <xsl:for-each-group select="$time_slots/time_slot" group-by=".">
            <xsl:call-template name="TIME_SLOT">
                <xsl:with-param name="position" select="position()"/>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:variable>
    <xsl:copy-of select="$time_slots"/>
</xsl:template>

<xsl:template name="S">
    <xsl:param name="time_slots"/>
    <TIER>
        <xsl:attribute name="TIER_ID">
            <xsl:text>Phrase</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="LINGUISTIC_TYPE_REF">
            <xsl:text>default-lt</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="PARTICIPANT">
            <xsl:value-of select="$participant"/>
        </xsl:attribute>
        <xsl:attribute name="DEFAULT_LOCALE">
            <xsl:value-of select="$source_language_code"/>
        </xsl:attribute>
        <xsl:apply-templates select="S/FORM">
            <xsl:with-param name="time_slots" select="$time_slots"/>
        </xsl:apply-templates>
    </TIER>
</xsl:template>

<xsl:template name="W">
    <TIER>
        <xsl:attribute name="TIER_ID">
            <xsl:text>Word</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="PARENT_REF">
            <xsl:text>Phrase</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="LINGUISTIC_TYPE_REF">
            <xsl:text>meta</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="PARTICIPANT">
            <xsl:value-of select="$participant"/>
        </xsl:attribute>
        <xsl:attribute name="DEFAULT_LOCALE">
            <xsl:value-of select="$source_language_code"/>
        </xsl:attribute>
        <xsl:apply-templates select="S/W/FORM"/>
    </TIER>
</xsl:template>

<xsl:template match="S/FORM">
    <xsl:param name="time_slots"/>
    <ANNOTATION>
        <ALIGNABLE_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::S/@id"/>
            </xsl:attribute>
            <xsl:attribute name="TIME_SLOT_REF1">
                <xsl:variable name="time_value" select="round(ancestor::S/AUDIO/@start*1000)"/>
                <xsl:value-of select="$time_slots/TIME_SLOT[@TIME_VALUE=$time_value]/@TIME_SLOT_ID"/>
            </xsl:attribute>
            <xsl:attribute name="TIME_SLOT_REF2">
                <xsl:variable name="time_value" select="round(ancestor::S/AUDIO/@end*1000)"/>
                <xsl:value-of select="$time_slots/TIME_SLOT[@TIME_VALUE=$time_value]/@TIME_SLOT_ID"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="replace(replace(., '[◊|]', ''), ' +', ' ')"/>
            </ANNOTATION_VALUE>
        </ALIGNABLE_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template match="W/FORM">
    <ANNOTATION>
        <REF_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::S/@id"/>
                <xsl:text>_w</xsl:text>
                <xsl:value-of select="position()"/>
            </xsl:attribute>
            <xsl:attribute name="ANNOTATION_REF">
                <xsl:value-of select="ancestor::S/@id"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="."/>
            </ANNOTATION_VALUE>
        </REF_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template name="S-TRANSL">
    <xsl:variable name="nodes" select="."/>
    <xsl:for-each select="tokenize($translation_language_codes, ', ')">
        <xsl:variable name="translation_language_code" select="."/>
        <xsl:if test="$nodes/S/TRANSL[@xml:lang=$translation_language_code]">
            <TIER>
                <xsl:attribute name="TIER_ID">
                    <xsl:text>Phrase translation</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="PARENT_REF">
                    <xsl:text>Phrase</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="LINGUISTIC_TYPE_REF">
                    <xsl:text>meta</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="DEFAULT_LOCALE">
                    <xsl:value-of select="$translation_language_code"/>
                </xsl:attribute>
                <xsl:apply-templates select="$nodes/S/TRANSL[@xml:lang=$translation_language_code]">
                    <xsl:with-param name="translation_language_code" select="$translation_language_code"/>
                </xsl:apply-templates>
            </TIER>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template name="W-TRANSL">
    <xsl:variable name="nodes" select="."/>
    <xsl:for-each select="tokenize($translation_language_codes, ', ')">
        <xsl:variable name="translation_language_code" select="."/>
        <xsl:if test="$nodes/S/W/TRANSL[@xml:lang=$translation_language_code]">
            <TIER>
                <xsl:attribute name="TIER_ID">
                    <xsl:text>Word translation</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="PARENT_REF">
                    <xsl:text>Word</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="LINGUISTIC_TYPE_REF">
                    <xsl:text>meta</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="DEFAULT_LOCALE">
                    <xsl:value-of select="$translation_language_code"/>
                </xsl:attribute>
                <xsl:apply-templates select="$nodes/S/W/TRANSL[@xml:lang=$translation_language_code]">
                    <xsl:with-param name="translation_language_code" select="$translation_language_code"/>
                </xsl:apply-templates>
            </TIER>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template match="S/TRANSL">
    <xsl:param name="translation_language_code"/>
    <ANNOTATION>
        <REF_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::S/@id"/>
                <xsl:text>_t</xsl:text>
                <xsl:value-of select="position()"/>
                <xsl:value-of select="$translation_language_code"/>
            </xsl:attribute>
            <xsl:attribute name="ANNOTATION_REF">
                <xsl:value-of select="ancestor::S/@id"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="."/>
            </ANNOTATION_VALUE>
        </REF_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template match="W/TRANSL">
    <xsl:param name="translation_language_code"/>
    <ANNOTATION>
        <REF_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::S/@id"/>
                <xsl:text>_wt</xsl:text>
                <xsl:value-of select="position()"/>
                <xsl:value-of select="$translation_language_code"/>
            </xsl:attribute>
            <xsl:attribute name="ANNOTATION_REF">
                <xsl:value-of select="ancestor::S/@id"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="."/>
            </ANNOTATION_VALUE>
        </REF_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template name="LINGUISTIC_TYPE">
    <LINGUISTIC_TYPE>
        <xsl:attribute name="LINGUISTIC_TYPE_ID">
            <xsl:text>default-lt</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="TIME_ALIGNABLE">
            <xsl:text>true</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="GRAPHIC_REFERENCES">
            <xsl:text>false</xsl:text>
        </xsl:attribute>
    </LINGUISTIC_TYPE>
    <LINGUISTIC_TYPE>
        <xsl:attribute name="LINGUISTIC_TYPE_ID">
            <xsl:text>meta</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="TIME_ALIGNABLE">
            <xsl:text>false</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="GRAPHIC_REFERENCES">
            <xsl:text>false</xsl:text>
        </xsl:attribute>
    </LINGUISTIC_TYPE>
</xsl:template>


</xsl:stylesheet>
