<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.mpi.nl/tools/elan/EAFv2.7.xsd" version="2.0" xml:lang="en">
<xsl:output method="xml" doctype-public="-//W3C//DTD HTML 5 Transitional//EN" encoding="utf-8" indent="yes"/>

<xsl:param name="author"/>
<xsl:param name="version"/>
<xsl:param name="participant"/>
<xsl:param name="source_language_code"/>
<xsl:param name="translation_language_codes"/>
<xsl:param name="bad_character_regex"/>
<xsl:param name="audio_path"/>

<xsl:param name="data_type" select="name(/*)"/>
<xsl:param name="main_tier_name" select="if ($data_type = 'TEXT') then 'S' else if ($data_type = 'WORDLIST') then 'W' else ''"/>

<xsl:template match="TEXT|WORDLIST">
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
        <xsl:call-template name="main_tier">
            <xsl:with-param name="time_slots" select="$time_slots"/>
        </xsl:call-template>
        <xsl:call-template name="main_tier_translation"/>
        <xsl:if test="$main_tier_name = 'S'">
            <xsl:call-template name="auxiliary_tier"/>
            <xsl:call-template name="auxiliary_tier_translation"/>
        </xsl:if>
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
        <xsl:call-template name="DATA_TYPE"/>
        <xsl:apply-templates select="SOUNDFILE"/>
        <xsl:apply-templates select="TITLE"/>
    </HEADER>
</xsl:template>

<xsl:template name="DATA_TYPE">
    <PROPERTY>
        <xsl:attribute name="NAME">
            <xsl:text>type</xsl:text>
        </xsl:attribute>
        <xsl:value-of select="$data_type"/>
    </PROPERTY>
</xsl:template>

<xsl:template match="SOUNDFILE">
    <MEDIA_DESCRIPTOR>
        <xsl:attribute name="MEDIA_URL">
            <xsl:value-of select="if ($audio_path != '') then $audio_path else @href"/>
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
        <xsl:for-each select="(W|S)/AUDIO">
            <time_slot><xsl:value-of select="format-number(@start*1000, '0000000000')"/></time_slot>
            <time_slot><xsl:value-of select="format-number(@end*1000, '0000000000')"/></time_slot>
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

<xsl:template name="main_tier">
    <xsl:param name="time_slots"/>
    <TIER>
        <xsl:attribute name="TIER_ID">
            <xsl:value-of select="if ($main_tier_name = 'S') then 'Phrase' else 'Word'"/>
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
        <xsl:apply-templates select="(W|S)/FORM">
            <xsl:with-param name="time_slots" select="$time_slots"/>
        </xsl:apply-templates>
    </TIER>
</xsl:template>

<xsl:template name="auxiliary_tier">
    <TIER>
        <xsl:attribute name="TIER_ID">
            <xsl:value-of select="if ($main_tier_name = 'S') then 'Word' else ''"/>
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

<xsl:template match="FORM[ancestor::*[1][@id]]">
    <xsl:param name="time_slots"/>
    <ANNOTATION>
        <ALIGNABLE_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::*[1]/@id"/>
            </xsl:attribute>
            <xsl:attribute name="TIME_SLOT_REF1">
                <xsl:variable name="time_value" select="ancestor::*[1]/AUDIO/format-number((@start*1000), '0000000000')"/>
                <xsl:value-of select="$time_slots/TIME_SLOT[@TIME_VALUE=$time_value]/@TIME_SLOT_ID"/>
            </xsl:attribute>
            <xsl:attribute name="TIME_SLOT_REF2">
                <xsl:variable name="time_value" select="ancestor::*[1]/AUDIO/format-number((@end*1000), '0000000000')"/>
                <xsl:value-of select="$time_slots/TIME_SLOT[@TIME_VALUE=$time_value]/@TIME_SLOT_ID"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="replace(replace(., $bad_character_regex, ''), ' +', ' ')"/>
            </ANNOTATION_VALUE>
        </ALIGNABLE_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template match="FORM[ancestor::*[1][not(@id)]]">
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
                <xsl:value-of select="replace(replace(., $bad_character_regex, ''), ' +', ' ')"/>
            </ANNOTATION_VALUE>
        </REF_ANNOTATION>
    </ANNOTATION>
</xsl:template>

<xsl:template name="main_tier_translation">
    <xsl:variable name="nodes" select="."/>
    <xsl:for-each select="tokenize($translation_language_codes, ', ')">
        <xsl:variable name="translation_language_code" select="."/>
        <xsl:if test="$nodes/(W|S)/TRANSL[@xml:lang=$translation_language_code]">
            <TIER>
                <xsl:attribute name="TIER_ID">
                    <xsl:text>Phrase translation </xsl:text>
                    <xsl:value-of select="$translation_language_code"/>
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
                <xsl:apply-templates select="$nodes/(W|S)/TRANSL[@xml:lang=$translation_language_code]">
                    <xsl:with-param name="translation_language_code" select="$translation_language_code"/>
                </xsl:apply-templates>
            </TIER>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template name="auxiliary_tier_translation">
    <xsl:variable name="nodes" select="."/>
    <xsl:for-each select="tokenize($translation_language_codes, ', ')">
        <xsl:variable name="translation_language_code" select="."/>
        <xsl:if test="$nodes/S/W/TRANSL[@xml:lang=$translation_language_code]">
            <TIER>
                <xsl:attribute name="TIER_ID">
                    <xsl:text>Word translation </xsl:text>
                    <xsl:value-of select="$translation_language_code"/>
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

<xsl:template match="TRANSL">
    <xsl:param name="translation_language_code"/>
    <ANNOTATION>
        <REF_ANNOTATION>
            <xsl:attribute name="ANNOTATION_ID">
                <xsl:value-of select="ancestor::*[@id][1]/@id"/>
                <xsl:value-of select="if (name(..) = 'W') then '_wt' else '_t'"/>
                <xsl:value-of select="position()"/>
                <xsl:value-of select="$translation_language_code"/>
            </xsl:attribute>
            <xsl:attribute name="ANNOTATION_REF">
                <xsl:value-of select="ancestor::*[@id][1]/@id"/>
            </xsl:attribute>
            <ANNOTATION_VALUE>
                <xsl:value-of select="replace(replace(., $bad_character_regex, ''), ' +', ' ')"/>
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
