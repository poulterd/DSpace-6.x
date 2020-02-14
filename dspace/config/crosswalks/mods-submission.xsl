<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
        xmlns:mods="http://www.loc.gov/mods/v3"
        version="1.0">

        <!--
                        **************************************************
                        MODS-2-DIM  ("DSpace Intermediate Metadata" ~ Dublin Core variant)
                        For a DSpace INGEST Plug-In Crosswalk
                        Original author William Reilly wreilly@mit.edu
                        Further developed by Timo Aalto (timo.j.aalto@helsinki.fi)
                        for University of Helsinki Pure4 CRIS integration.
                        **************************************************
        -->

        <!--        See also mods.properties in same directory.
                e.g. dc.contributor = <mods:name><mods:namePart>%s</mods:namePart></mods:name> | mods:namePart/text()
        -->

        <!-- Target XML:
                http://wiki.dspace.org/DspaceIntermediateMetadata

                e.g. <dim:dim xmlns:dim="http://www.dspace.org/xmlns/dspace/dim">
                <dim:field mdschema="dc" element="title" lang="en">CSAIL Title - The Urban Question as a Scale Question</dim:field>
                <dim:field mdschema="dc" element="contributor" qualifier="author" lang="en">Brenner, Neil</dim:field>
                ...
        -->

        <!-- Dublin Core schema links:
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/qualifieddc.xsd
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/dcterms.xsd  -->

        <xsl:output indent="yes" method="xml"/>


        <xsl:template match="text()">
                <!--
                                Do nothing.

                                Override, effectively, the "Built-In" rule which will
                                process all text inside elements otherwise not matched by any xsl:template.

                                Note: With this in place, be sure to then provide templates or "value-of"
                                statements to actually _get_ the (desired) text out to the result document!
                -->
        </xsl:template>


        <!-- **** MODS  mods  [ROOT ELEMENT] ====> DC n/a **** -->
        <xsl:template match="*[local-name()='mods']">
                <!-- fwiw, these match approaches work:
                        <xsl:template match="mods:mods">...
                        <xsl:template match="*[name()='mods:mods']">...
                        <xsl:template match="*[local-name()='mods']">...
                        ...Note that only the latter will work on XML data that does _not_ have
                        namespace prefixes (e.g. <mods><titleInfo>... vs. <mods:mods><mods:titleInfo>...)
                -->
                <xsl:element name="dim:dim">

                        <xsl:comment>IMPORTANT NOTE:
                                ****************************************************************************************************
                                THIS "Dspace Intermediate Metadata" ('DIM') IS **NOT** TO BE USED FOR INTERCHANGE WITH OTHER SYSTEMS.
                                ****************************************************************************************************
                                It does NOT pretend to be a standard, interoperable representation of Dublin Core.

                                It is expressly used for transformation to and from source metadata XML vocabularies into and out of the DSpace object model.

                                See http://wiki.dspace.org/DspaceIntermediateMetadata

                                For more on Dublin Core standard schemata, see:
                                http://dublincore.org/schemas/xmls/qdc/2003/04/02/qualifieddc.xsd
                                http://dublincore.org/schemas/xmls/qdc/2003/04/02/dcterms.xsd

                        </xsl:comment>


                        <!-- WR_ NAMESPACE NOTE
                                Don't "code into" this XSLT the creation of the attribute with the name 'xmlns:dim', to hold the DSpace URI for that namespace.
                                NO: <dim:field mdschema="dc" element="title" lang="en" xmlns:dim="http://www.dspace.org/xmlns/dspace/dim">
                                Why not?
                                Because it's an error (or warning, at least), and because the XML/XSLT tools (parsers, processors) will take care of it for you. ("Ta-da!")
                                [fwiw, I tried this on 4 processors: Sablotron, libxslt, Saxon, and Xalan-J (using convenience of TestXSLT http://www.entropy.ch/software/macosx/ ).]
                                -->
                        <!-- WR_ Do Not Use (see above note)
                                        <xsl:attribute name="xmlns:dim">http://www.dspace.org/xmlns/dspace/dim</xsl:attribute>
                                -->
                        <xsl:apply-templates/>
                </xsl:element>
        </xsl:template>

        <!--NOTE: at its current form, this XSL assumes that all output has an attribute "lang=en".
        This should either be further developed to be language-sensitive or just change the lang code accordingly / tiaalto 12.5.2010-->
        <!-- **** MODS   titleInfo/title ====> DC title **** -->
        <!-- **** MODS   titleInfo/subTitle ====> DC title ______ (?) **** -->
        <xsl:template match="*[local-name()='titleInfo']">
                <xsl:choose>
                        <xsl:when test="*[local-name()='title'] and *[local-name()='subTitle']">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">title</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(*[local-name()='title'])"/> : <xsl:value-of select="normalize-space(*[local-name()='subTitle'])"/>
                                </xsl:element>
                        </xsl:when>
                        <xsl:when test="*[local-name()='title']">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">title</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(*[local-name()='title'])"/>
                                </xsl:element>
                        </xsl:when>
                </xsl:choose>
        </xsl:template>


        <!-- **** MODS   titleInfo/@type="alternative" ====> DC title.alternative **** -->
        <xsl:template match="*[local-name()='titleInfo'][@type='alternative']">
                <!-- TODO Three other attribute values:
                        http://www.loc.gov/standards/mods/mods-outline.html#titleInfo
                        -->
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">title</xsl:attribute>
                        <xsl:attribute name="qualifier">alternative</xsl:attribute>
                        <xsl:attribute name="lang">en</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


        <!-- **** MODS  name ====> DC  contributor.{role/roleTerm} **** -->
        <xsl:template match="*[local-name()='name'][@type='personal']">


                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">contributor</xsl:attribute>
                        <!-- Important assumption: That the string value used
                        in the MODS role/roleTerm is indeed a DC Qualifier.
                        e.g. contributor.illustrator
                        (Using this assumption, rather than coding in
                        a more controlled vocabulary via xsl:choose etc.)
                        -->
                        <!--
                        <xsl:if test="*[local-name()='role']/*[local-name()='roleTerm']!='Other'">
                            <xsl:attribute name="qualifier"><xsl:value-of select="*[local-name()='role']/*[local-name()='roleTerm']"/></xsl:attribute>
                        </xsl:if>
                        -->
                        <!--<xsl:if test="*[local-name()='role']/*[local-name()='roleTerm']">-->
                        <xsl:call-template name="Contributor">
                                <xsl:with-param name="contributor" select="*[local-name()='role']/*[local-name()='roleTerm']"/>
                        </xsl:call-template>
                        <!--</xsl:if>-->

                        <xsl:choose>
                                <xsl:when test="*[local-name()='namePart'][@type='given'] and *[local-name()='namePart'][@type='family']">
                                        <xsl:value-of select="*[local-name()='namePart'][@type='family']"/><xsl:text>, </xsl:text><xsl:value-of select="*[local-name()='namePart'][@type='given']"/>
                                </xsl:when>
                                <xsl:when test="*[local-name()='namePart'][@type='given']">
                                        <xsl:value-of select="*[local-name()='namePart'][@type='given']"/>
                                </xsl:when>
                                <xsl:when test="*[local-name()='namePart'][@type='family']">
                                        <xsl:value-of select="*[local-name()='namePart'][@type='family']"/>
                                </xsl:when>
                                <xsl:otherwise>
                                        No name
                                </xsl:otherwise>
                        </xsl:choose>
                </xsl:element>


                <!--if there is an affiliation for a person-->
        </xsl:template>

        <xsl:template match="*[local-name()='name'][@type='corporate']">
                <xsl:if test="*[local-name()='namePart']">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <!--         **** MODS affiliation ====> DC  creator.corporateName (UH specific, adjust accordingly) tiaalto 120210**** -->
                                <!-- xsl:attribute name="element">creator</xsl:attribute>
                                <xsl:attribute name="qualifier">corporateName</xsl:attribute-->

                                <xsl:attribute name="element">contributor</xsl:attribute>
                                <xsl:attribute name="qualifier">institution</xsl:attribute>
                                <xsl:attribute name="lang">en</xsl:attribute>
                                <xsl:text>University of Aberdeen, </xsl:text>
                                <xsl:value-of select="*[local-name()='namePart']"/>
                        </xsl:element>
                </xsl:if>

                <!--This is for capturing local authors (ie Pure persons?) into their own DIM field, for integration purposes.
                It assumes that such persons have been encoded in MODS using a authority="local" attribute in v3:name / tiaalto 12.5.2010-->

                <!--this DIM mapping is just for testing and must be changed-->
                <!-- xsl:if test="@authority='local'">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">contributor</xsl:attribute>
                                <xsl:attribute name="qualifier">other</xsl:attribute>
                        		<xsl:value-of select="*[local-name()='namePart'][@type='family']"/><xsl:text>, </xsl:text><xsl:value-of select="*[local-name()='namePart'][@type='given']"/>
                        </xsl:element>
                </xsl:if-->
        </xsl:template>

        <!-- **** MODS   originInfo/dateValid ====> DC  date.embargoedUntil (UH specific, adjust accordingly) tiaalto 120210 **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='dateValid']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">date</xsl:attribute>
                        <xsl:attribute name="qualifier">embargoedUntil</xsl:attribute>
                        <xsl:call-template name="FormatDate">
                                <xsl:with-param name="DateTime" select="."/>
                        </xsl:call-template>
                </xsl:element>
        </xsl:template>

        <!-- **** MODS   originInfo/dateIssued ====> DC  date.issued **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='dateIssued']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">date</xsl:attribute>
                        <xsl:attribute name="qualifier">issued</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>
        </xsl:template>

        <!-- **** MODS   Language/LanguageTerm ====> DC  language.iso **** -->
        <xsl:template match="*[local-name()='language']/*[local-name()='languageTerm']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">language</xsl:attribute>
                        <xsl:attribute name="qualifier">iso</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>

        </xsl:template>


        <!-- **** MODS   physicalDescription/extent ====> DC  format.extent **** -->
        <xsl:template match="*[local-name()='physicalDescription']/*[local-name()='extent']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">format</xsl:attribute>
                        <xsl:attribute name="qualifier">extent</xsl:attribute>
                        <xsl:attribute name="lang">en</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>
        </xsl:template>

        <!-- **** MODS   abstract  ====> DC  description.abstract **** -->
        <!--
            <xsl:template match="*[local-name()='abstract']">
                    <xsl:element name="dim:field">
                            <xsl:attribute name="mdschema">dc</xsl:attribute>
                            <xsl:attribute name="element">description</xsl:attribute>
                            <xsl:attribute name="qualifier">abstract</xsl:attribute>
                            <xsl:attribute name="lang">en</xsl:attribute>
                            <xsl:value-of select="normalize-space(.)"/>
                    </xsl:element>
            </xsl:template>
            -->

        <!-- **** MODS   subject/topic ====> DC  subject **** -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='topic']">
                <xsl:choose>
                        <xsl:when test="../@*[local-name()='type']='ipc'">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">subject</xsl:attribute>
                                        <xsl:attribute name="qualifier">classification</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">subject</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:template>


        <xsl:template match="*[local-name()='classification']">
                <xsl:if test="starts-with(., '/dk/atira/pure/core/keywords')">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">subject</xsl:attribute>
                                <xsl:attribute name="qualifier">lcc</xsl:attribute>
                                <xsl:attribute name="lang">en</xsl:attribute>
                                <xsl:call-template name="Tokenise" >
                                        <xsl:with-param name="src" select="."/>
                                </xsl:call-template>

                        </xsl:element>
                </xsl:if>
        </xsl:template>


        <!-- **** MODS   subject/geographic ====> DC  coverage.spatial **** -->
        <!-- (Not anticipated for CSAIL.) -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='geographic']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">coverage</xsl:attribute>
                        <xsl:attribute name="qualifier">spatial</xsl:attribute>
                        <xsl:attribute name="lang">en</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!-- **** MODS   subject/temporal ====> DC  coverage.temporal **** -->
        <!-- (Not anticipated for CSAIL.) -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='temporal']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">coverage</xsl:attribute>
                        <xsl:attribute name="qualifier">temporal</xsl:attribute>
                        <xsl:attribute name="lang">en</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


        <!-- **** MODS   relatedItem...    **** -->
        <!-- NOTE -
                HAS *TWO* INTERPRETATIONS IN DC:
                1) DC  identifier.citation
                MODS [@type='host'] {/part/text}       ====> DC  identifier.citation
                2) DC  relation.___
                MODS [@type='____'] {/titleInfo/title} ====> DC  relation.{ series | host | other...}
        -->
        <xsl:template match="*[local-name()='relatedItem']">
                <xsl:choose>
                        <!-- 1)  DC  identifier.citation  -->
                        <xsl:when test="./@type='host'  and   *[local-name()='part']/*[local-name()='text']">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">identifier</xsl:attribute>
                                        <xsl:attribute name="qualifier">citation</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(*[local-name()='part']/*[local-name()='text'])"/>
                                </xsl:element>
                                <!-- Note: CSAIL Assumption (and for now, generally):
                                        The bibliographic citation is _not_ parsed further,
                                        and one single 'text' element will contain it.
                                        e.g. <text>Journal of Physics, v. 53, no. 9, pp. 34-55, Aug. 15, 2004</text>
                                        -->
                        </xsl:when>
                        <!-- 2)  DC  relation._____  -->
                        <xsl:otherwise>
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">relation</xsl:attribute>
                                        <xsl:choose>
                                                <xsl:when test="./@type='series'">
                                                        <xsl:attribute name="qualifier">ispartofseries</xsl:attribute>
                                                </xsl:when>
                                                <xsl:when test="./@type='host'">
                                                        <xsl:attribute name="qualifier">ispartof</xsl:attribute>
                                                </xsl:when>
                                                <!-- 10 more... TODO
http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODSmapping2MB.html
                                                http://www.loc.gov/standards/mods/mods-outline.html#relatedItem
                                                        -->
                                        </xsl:choose>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(*[local-name()='titleInfo']/*[local-name()='title'])"/>
                                </xsl:element>
                        </xsl:otherwise>
                </xsl:choose>

                <xsl:if test="count(*[local-name()='identifier']) &gt; 0">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">identifier</xsl:attribute>
                                <xsl:attribute name="qualifier">
                                        <xsl:choose>
                                                <xsl:when test="*[local-name()='identifier'][@type='issn']">issn</xsl:when>
                                                <xsl:when test="*[local-name()='identifier'][@type='isbn']">isbn</xsl:when>
                                                <xsl:otherwise>other</xsl:otherwise>
                                        </xsl:choose>
                                </xsl:attribute>
                                <xsl:value-of select="normalize-space(*[local-name()='identifier'])"/>
                        </xsl:element>
                </xsl:if>
        </xsl:template>


        <!--
                <xsl:template match="mods:accessCondition">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">rights</xsl:attribute>
                                <xsl:attribute name="lang">en</xsl:attribute>
                                <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                </xsl:template>
        -->

        <!-- **** MODS   identifier/@type  ====> DC identifier.other  **** -->
        <xsl:template match="*[local-name()='identifier']"> <!-- [@type='series']"> -->
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">identifier</xsl:attribute>
                        <xsl:choose>
                                <xsl:when test="./@type='local'">
                                        <xsl:attribute name="qualifier">other</xsl:attribute>
                                </xsl:when>
                                <xsl:when test="./@type='doi'">
                                        <xsl:attribute name="qualifier">doi</xsl:attribute>
                                </xsl:when>
                                <xsl:when test="./@type='uri'">
                                        <xsl:attribute name="qualifier">uri</xsl:attribute>
                                </xsl:when>
                                <xsl:when test="./@type='isbn'">
                                        <xsl:attribute name="qualifier">isbn</xsl:attribute>
                                </xsl:when>
                                <xsl:when test="./@type='issn'">
                                        <xsl:attribute name="qualifier">issn</xsl:attribute>
                                </xsl:when>
                                <!-- 6 (?) more... TODO
                                        http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODSmapping2MB.html
                                        http://www.loc.gov/standards/mods/mods-outline.html#identifier

                                        (but see also MODS relatedItem[@type="host"]/part/text == identifier.citation)
                                -->
                        </xsl:choose>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!-- **** MODS   originInfo/publisher  ====> DC  publisher  **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='publisher']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">publisher</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!-- bg@atira.dk 17.05.10 Added handling of genre for publication type and file type, added handling of note for document version -->

        <!-- **** MODS   genre  ====> DC  type  **** -->
        <xsl:template match="*[local-name()='genre']">
                <xsl:choose>
                        <!-- 1)  DC  type  -->
                        <xsl:when test="./@type='documentType'">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <!--<xsl:attribute name="element">type</xsl:attribute>-->
                                        <xsl:attribute name="element">format</xsl:attribute>
                                        <xsl:attribute name="qualifier">type</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:when>
                        <!-- 2)  DC  type (publication type)  -->
                        <xsl:when test="./@type='publicationType'">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">type</xsl:attribute> <!-- TODO: Move to other dc field? -->
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:when>
                        <!-- 3)  DC  short description  -->
                        <xsl:when test="./@authority='dct' and ./@type='contentType'">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">description</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:when>
                </xsl:choose>
        </xsl:template>


        <!-- **** MODS   note[@type=version identification]  ====> DC  description.version  **** -->
        <!-- **** MODS   note  ====> DC  description  **** -->
        <xsl:template match="*[local-name()='note']">
                <xsl:choose>
                        <!-- Note with @type -->
                        <xsl:when test="./@type">
                                <xsl:choose>
                                        <xsl:when test="./@type='version identification'">
                                                <xsl:element name="dim:field">
                                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                                        <xsl:attribute name="element">description</xsl:attribute>
                                                        <xsl:attribute name="qualifier">version</xsl:attribute>
                                                        <xsl:attribute name="lang">en</xsl:attribute>
                                                        <!--<xsl:value-of select="normalize-space(.)"/>-->

                                                        <xsl:call-template name="FormatVersion">
                                                                <xsl:with-param name="version" select="."/>
                                                        </xsl:call-template>
                                                </xsl:element>
                                        </xsl:when>
                                        <xsl:when test="./@type='peerreview status'">
                                                <xsl:element name="dim:field">
                                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                                        <xsl:attribute name="element">description</xsl:attribute>
                                                        <xsl:attribute name="qualifier">status</xsl:attribute>
                                                        <xsl:attribute name="lang">en</xsl:attribute>
                                                        <xsl:value-of select="normalize-space(.)"/>
                                                </xsl:element>
                                        </xsl:when>
                                        <xsl:when test="./@type='rights statement'">
                                                <xsl:element name="dim:field">
                                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                                        <xsl:attribute name="element">rights</xsl:attribute>
                                                        <xsl:attribute name="lang">en</xsl:attribute>
                                                        <xsl:value-of select="normalize-space(.)"/>
                                                </xsl:element>
                                        </xsl:when>
                                </xsl:choose>

                        </xsl:when>

                        <!-- Note without @type -->
                        <xsl:otherwise>
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">description</xsl:attribute>
                                        <xsl:attribute name="lang">en</xsl:attribute>
                                        <xsl:value-of select="normalize-space(.)"/>
                                </xsl:element>
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:template>


        <!-- **** MODS   location/url  ====> DC  identifier.uri  **** -->
        <xsl:template match="*[local-name()='location']/*[local-name()='url']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">identifier</xsl:attribute>
                        <xsl:attribute name="qualifier">uri</xsl:attribute>
                        <xsl:attribute name="lang">en</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!-- bg@atira.dk 17.05.10 end -->

        <!--tiaalto 12.05.10: This template is for massaging the embargo date into a form understandable by DSpace.
        source: http://geekswithblogs.net/workdog/archive/2007/02/08/105858.aspx-->

        <xsl:template name="FormatDate">

                <xsl:param name="DateTime" />

                <!-- new date format 2006-01-14T08:55:22 -->

                <xsl:variable name="mo">

                        <xsl:value-of select="substring($DateTime,1,2)" />

                </xsl:variable>

                <xsl:variable name="day-temp">

                        <xsl:value-of select="substring-after($DateTime,'-')" />

                </xsl:variable>

                <xsl:variable name="day">

                        <xsl:value-of select="substring-before($day-temp,'-')" />

                </xsl:variable>

                <xsl:variable name="year-temp">

                        <xsl:value-of select="substring-after($day-temp,'-')" />

                </xsl:variable>

                <xsl:variable name="year">

                        <xsl:value-of select="substring($year-temp,1,4)" />

                </xsl:variable>

                <xsl:variable name="time">

                        <xsl:value-of select="substring-after($year-temp,' ')" />

                </xsl:variable>

                <xsl:variable name="hh">

                        <xsl:value-of select="substring($time,1,2)" />

                </xsl:variable>

                <xsl:variable name="mm">

                        <xsl:value-of select="substring($time,4,2)" />

                </xsl:variable>

                <xsl:variable name="ss">

                        <xsl:value-of select="substring($time,7,2)" />

                </xsl:variable>

                <xsl:value-of select="$year"/>

                <xsl:value-of select="'-'"/>





                <xsl:if test="(string-length($day) &lt; 2)">

                        <xsl:value-of select="0"/>

                </xsl:if>

                <xsl:value-of select="$day"/>

                <xsl:value-of select="'-'"/>

                <xsl:value-of select="$mo"/>


        </xsl:template>

        <xsl:template name="FormatVersion">

                <xsl:param name="version" />
                <xsl:choose>
                        <xsl:when test="$version = 'preprint'">
                                <xsl:text>Preprint</xsl:text>
                        </xsl:when>
                        <xsl:when test="$version = 'authorsversion'">
                                <xsl:text>Postprint</xsl:text>
                        </xsl:when>
                        <xsl:when test="$version = 'publishersversion'">
                                <xsl:text>Publisher PDF</xsl:text>
                        </xsl:when>
                        <xsl:when test="$version = 'other'">
                                <xsl:text>Other</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:value-of select="$version"/>
                        </xsl:otherwise>
                </xsl:choose>

        </xsl:template>

        <xsl:template name="Contributor">

                <xsl:param name="contributor" />
                <xsl:choose>
                        <xsl:when test="$contributor = 'Other'">
                                <!-- Don't add an attribute -->
                        </xsl:when>
                        <xsl:when test="$contributor = 'other'">
                                <!-- Don't add an attribute -->
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:attribute name="qualifier"><xsl:value-of select="$contributor"/></xsl:attribute>
                        </xsl:otherwise>
                </xsl:choose>

        </xsl:template>

        <!-- recursively splits string into <token> elements -->
        <xsl:template name="Tokenise">
                <xsl:param name="src"/>

                <xsl:choose>
                        <xsl:when test="contains($src,'/')">

                                <!-- recurse -->
                                <xsl:call-template name="Tokenise">
                                        <xsl:with-param name="src" select="substring-after($src,'/')"/>
                                </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>

                                <!-- last token, end recursion -->
                                <xsl:value-of select="$src"/>

                        </xsl:otherwise>
                </xsl:choose>
        </xsl:template>



</xsl:stylesheet>
