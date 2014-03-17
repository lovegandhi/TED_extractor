<?xml version="1.0" encoding="UTF-8"?>
<!-- 
####################################################################################
#  Author:  Tomas Posepny
#  Compatible TED XSD release:  R2.0.8.S02.E01
#  Compatible XSDs: F02_CONTRACT
####################################################################################
 -->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:gr="http://purl.org/goodrelations/v1#" 
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:pc="http://purl.org/procurement/public-contracts#" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" 
    xmlns:s="http://schema.org/"
    xmlns:vcard="http://www.w3.org/2006/vcard/ns#" 
    xmlns:pceu="http://purl.org/procurement/public-contracts-eu#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:adms="http://www.w3.org/ns/adms#"
    xmlns:f="http://opendata.cz/xslt/functions#" 
    exclude-result-prefixes="f"
    xpath-default-namespace="http://publications.europa.eu/TED_schema/Export" 
    version="2.0">

    <xsl:import href="functions.xsl"/>
    <xsl:output encoding="UTF-8" indent="yes" method="xml" normalization-form="NFC"/>

    <!--
    *********************************************************
    *** GLOBAL VARIABLES
    *********************************************************
    -->
    
    <!-- NAMESPACES -->
    <xsl:variable name="pc_nm" select="'http://purl.org/procurement/public-contracts#'"/>
    <xsl:variable name="lod_nm" select="'http://linked.opendata.cz/resource/'"/>
    <xsl:variable name="ted_nm" select="concat($lod_nm, 'ted.europa.eu/')"/>
    <xsl:variable name="ted_business_entity_nm" select="concat($ted_nm, 'business-entity/')"/>
    <xsl:variable name="ted_pc_nm" select="concat($ted_nm, 'public-contract/')"/>
    <xsl:variable name="pc_lot_nm" select="concat($pc_uri, '/lot/')"/>
    <xsl:variable name="pc_estimated_price_nm" select="concat($pc_uri, '/estimated-price/')"/>
    <xsl:variable name="pc_weighted_criterion_nm" select="concat($pc_award_criteria_combination_uri_1, '/weighted_criterion/')"/>
    <xsl:variable name="pc_criteria_nm" select="'http://purl.org/procurement/public-contracts-criteria#'"/>
    
    <!-- URIS -->
    <xsl:variable name="pc_uri" select="concat($ted_pc_nm, $doc_id)"/>
    <xsl:variable name="pc_award_criteria_combination_uri_1" select="concat($pc_uri, '/combination-of-contract-award-criteria/1')"/>
    <xsl:variable name="pc_criterion_lowest_price_uri" select="concat($pc_criteria_nm,'LowestPrice')"/>
    <xsl:variable name="pc_identifier_uri_1" select="concat($pc_uri, '/identifier/1')"/>
    <xsl:variable name="pc_documentation_price_uri_1" select="concat($pc_uri, '/documentation-price/1')"/>
    <xsl:variable name="tenders_opening_place_uri_1" select="concat($pc_uri,'/tenders-opening-place/1')" />

    <!-- OTHER VARIABLES -->
    <xsl:variable name="doc_id" select="/TED_EXPORT/@DOC_ID"/>
    <xsl:variable name="lang" select="/TED_EXPORT/CODED_DATA_SECTION/NOTICE_DATA/LG_ORIG/text()"/>
     
    
    <!--
    *********************************************************
    *** TEMPLATES
    *********************************************************
    -->
    
    <!-- ROOT -->
    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates select="TED_EXPORT/FORM_SECTION/CONTRACT[@CATEGORY='ORIGINAL']"/>
        </rdf:RDF>
    </xsl:template>

    <!-- F02 CONTRACT -->
    <xsl:template match="CONTRACT[@CATEGORY='ORIGINAL']">
        <pc:Contract rdf:about="{$pc_uri}">
            <xsl:apply-templates select="FD_CONTRACT"/>
        </pc:Contract>
        
        <!-- tenders opening -->
        <xsl:apply-templates select="FD_CONTRACT/PROCEDURE_DEFINITION_CONTRACT_NOTICE/ADMINISTRATIVE_INFORMATION_CONTRACT_NOTICE/CONDITIONS_FOR_OPENING_TENDERS"/>
      
    </xsl:template>

    <xsl:template match="FD_CONTRACT">
        <!-- contract kind -->
        <pc:kind rdf:resource="{f:getContractKind(@CTYPE)}"/>

        <xsl:apply-templates select="CONTRACTING_AUTHORITY_INFORMATION"/>
        <xsl:apply-templates select="OBJECT_CONTRACT_INFORMATION"/>
        <xsl:apply-templates select="PROCEDURE_DEFINITION_CONTRACT_NOTICE"/>
    </xsl:template>


    <!--
    *********************************************************
    *** SECTION I: CONTRACTING AUTHORITY
    *********************************************************
    -->
    <xsl:template match="CONTRACTING_AUTHORITY_INFORMATION">
        <xsl:apply-templates select="NAME_ADDRESSES_CONTACT_CONTRACT" mode="contractingAuthority"/>
        <xsl:apply-templates select="NAME_ADDRESSES_CONTACT_CONTRACT" mode="contact"/>
        <xsl:apply-templates select="TYPE_AND_ACTIVITIES_AND_PURCHASING_ON_BEHALF/PURCHASING_ON_BEHALF/PURCHASING_ON_BEHALF_YES/CONTACT_DATA_OTHER_BEHALF_CONTRACTING_AUTORITHY"/>
    </xsl:template>

    <!-- contracting authority -->
    <xsl:template match="NAME_ADDRESSES_CONTACT_CONTRACT" mode="contractingAuthority">
        <xsl:variable name="countryCode" select="CA_CE_CONCESSIONAIRE_PROFILE/COUNTRY/@VALUE"/>
        <xsl:variable name="organisationId" select="CA_CE_CONCESSIONAIRE_PROFILE/ORGANISATION/NATIONALID"/>
        <xsl:variable name="contractingAuthorityUri">
            <xsl:value-of select="f:getBusinessEntityId($countryCode, $organisationId)"/>
        </xsl:variable>
        <pc:contractingAuthority>
            <gr:BusinessEntity rdf:about="{concat($ted_business_entity_nm, $contractingAuthorityUri)}">
                <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE" mode="legalNameAndAddress"/>
                <xsl:apply-templates select="INTERNET_ADDRESSES_CONTRACT/URL_BUYER"/>
                <xsl:apply-templates select="../TYPE_AND_ACTIVITIES_AND_PURCHASING_ON_BEHALF/TYPE_AND_ACTIVITIES"/>
            </gr:BusinessEntity>
        </pc:contractingAuthority>
    </xsl:template>

    <!-- contract contact -->
    <xsl:template match="NAME_ADDRESSES_CONTACT_CONTRACT" mode="contact">
        <xsl:if test="CA_CE_CONCESSIONAIRE_PROFILE/(CONTACT_POINT|ATTENTION|(E_MAILS/E_MAIL)|PHONE|FAX)/text()">
            <pc:contact>
                <vcard:VCard>
                    <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE/CONTACT_POINT"/>
                    <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE/ATTENTION"/>
                    <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE/PHONE"/>
                    <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE/E_MAILS/E_MAIL"/>
                    <xsl:apply-templates select="CA_CE_CONCESSIONAIRE_PROFILE/FAX"/>
                </vcard:VCard>
            </pc:contact>
        </xsl:if>
    </xsl:template>

    <xsl:template match="CA_CE_CONCESSIONAIRE_PROFILE" mode="legalNameAndAddress">
        <xsl:call-template name="legalName"/>
        <xsl:call-template name="postalAddress"/>
    </xsl:template>

    <!-- contracting authority buyer profile url -->
    <xsl:template match="URL_BUYER">
        <xsl:if test="text()">
            <pc:buyerProfile rdf:resource="{text()}"/>
        </xsl:if>
    </xsl:template>

    <!-- contracting authority kind and main activity  -->
    <xsl:template match="TYPE_AND_ACTIVITIES">
        <xsl:if test="TYPE_OF_CONTRACTING_AUTHORITY">
            <pc:authorityKind rdf:resource="{f:getAuthorityKind(TYPE_OF_CONTRACTING_AUTHORITY/@VALUE)}"/>
        </xsl:if>
        <xsl:if test="TYPE_OF_ACTIVITY">
            <pc:mainActivity rdf:resource="{f:getAuthorityActivity(TYPE_OF_ACTIVITY[1]/@VALUE)}"/>
        </xsl:if>
    </xsl:template>

    <!-- on behalf of -->
    <xsl:template match="CONTACT_DATA_OTHER_BEHALF_CONTRACTING_AUTORITHY">
        <pc:onBehalfOf>
            <gr:BusinessEntity>
                <xsl:call-template name="legalName"/>
                <xsl:call-template name="postalAddress"/>
            </gr:BusinessEntity>
        </pc:onBehalfOf>
    </xsl:template>


    <!--
    *********************************************************
    *** SECTION II: OBJECT OF THE CONTRACT + B_ANNEX
    *********************************************************
    -->
    <xsl:template match="OBJECT_CONTRACT_INFORMATION">
        <xsl:apply-templates select="DESCRIPTION_CONTRACT_INFORMATION"/>
        <xsl:apply-templates select="QUANTITY_SCOPE/NATURE_QUANTITY_SCOPE"/>
        <xsl:apply-templates select="PERIOD_WORK_DATE_STARTING"/>
    </xsl:template>
   
    <xsl:template match="DESCRIPTION_CONTRACT_INFORMATION">
        <xsl:apply-templates select="TITLE_CONTRACT"/>
        <xsl:apply-templates select="LOCATION_NUTS"/>
        <xsl:apply-templates select="F02_FRAMEWORK"/>
        <xsl:apply-templates select="SHORT_CONTRACT_DESCRIPTION"/>
        <xsl:apply-templates select="CPV"/> 
        <xsl:apply-templates select="F02_DIVISION_INTO_LOTS/F02_DIV_INTO_LOT_YES/F02_ANNEX_B"/> 
    </xsl:template>

    <!-- contract title -->
    <xsl:template match="TITLE_CONTRACT|LOT_TITLE">
        <dcterms:title xml:lang="{$lang}">
            <xsl:value-of select="normalize-space(.)"/>
        </dcterms:title>
        <rdfs:label xml:lang="{$lang}">
            <xsl:value-of select="normalize-space(.)"/>
        </rdfs:label>
    </xsl:template>

    <!-- contract location -->
    <xsl:template match="LOCATION_NUTS">
        <xsl:if test="LOCATION">    
            <pc:location>
                <s:Place>
                        <s:description>
                            <xsl:value-of select="normalize-space(LOCATION)"/>
                        </s:description>
                    <xsl:if test="NUTS">
                        <pceu:hasParentRegion rdf:resource="{f:getNutsUri(NUTS/@CODE)}"/>
                    </xsl:if>
                </s:Place>
            </pc:location>
        </xsl:if>
    </xsl:template>
    
    <!-- framework agreement -->
    <xsl:template match="F02_FRAMEWORK">
        <pc:frameworkAgreement>
            <pc:FrameworkAgreement>
                <pc:expectedNumberOfOperators>
                    <xsl:choose>
                        <xsl:when test="SINGLE_OPERATOR">
                            <!-- TODO: -->
                        </xsl:when>
                        <xsl:when test="SEVERAL_OPERATORS">
                            <!-- TODO: -->
                        </xsl:when>
                    </xsl:choose>
                </pc:expectedNumberOfOperators>
            </pc:FrameworkAgreement>
        </pc:frameworkAgreement>
    </xsl:template>
    
    <!-- contract description -->
    <xsl:template match="SHORT_CONTRACT_DESCRIPTION|LOT_DESCRIPTION">
            <xsl:call-template name="description"/>
    </xsl:template>
    
    <!-- contract part (lot) -->
    <xsl:template match="F02_ANNEX_B">
            <xsl:variable name="lotNumber">
                <xsl:choose>
                    <xsl:when test="LOT_NUMBER">
                        <xsl:value-of select="LOT_NUMBER"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="position()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <pc:lot>
                <pc:Contract rdf:about="{concat($pc_lot_nm, $lotNumber)}">
                    <xsl:apply-templates select="LOT_TITLE"/>
                    <xsl:apply-templates select="LOT_DESCRIPTION"/>
                    <xsl:apply-templates select="CPV"/>
                    <xsl:apply-templates select="NATURE_QUANTITY_SCOPE"/>
                    <xsl:apply-templates select="PERIOD_WORK_DATE_STARTING"/>
                </pc:Contract>
            </pc:lot>    
    </xsl:template>
    
    <!-- cpv codes -->
    <xsl:template match="CPV">
        <xsl:apply-templates select="CPV_MAIN"/>
        <xsl:apply-templates select="CPV_ADDITIONAL"/>
    </xsl:template>
    
    <!-- main cpv -->
    <xsl:template match="CPV_MAIN">
        <pc:mainObject rdf:resource="{f:getCpvUri(CPV_CODE/@CODE)}"/>
    </xsl:template>
    
    <!-- additional cpv -->
    <xsl:template match="CPV_ADDITIONAL">
        <pc:additionalObject rdf:resource="{f:getCpvUri(CPV_CODE/@CODE)}"/>
    </xsl:template>
       
    <!-- estimated price -->
    <xsl:template match="NATURE_QUANTITY_SCOPE">
        <xsl:apply-templates select="COSTS_RANGE_AND_CURRENCY"/>
    </xsl:template>
    
    <xsl:template match="COSTS_RANGE_AND_CURRENCY">
        <pc:estimatedPrice>
            <gr:PriceSpecification rdf:about="{concat($pc_estimated_price_nm, position())}">
                <xsl:apply-templates select="VALUE_COST"/>
                <xsl:apply-templates select="RANGE_VALUE_COST"/>
                <xsl:call-template name="currency">
                    <xsl:with-param name="currencyCode" select="@CURRENCY"/>
                </xsl:call-template>
                <gr:valueAddedTaxIncluded rdf:datatype="xsd:boolean">false</gr:valueAddedTaxIncluded>
            </gr:PriceSpecification>
        </pc:estimatedPrice>
    </xsl:template>

    <!-- price value -->
    <xsl:template match="VALUE_COST">
        <xsl:call-template name="priceValue">
            <xsl:with-param name="value" select="@FMTVAL"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- price range min and max values -->
    <xsl:template match="RANGE_VALUE_COST">
        <gr:hasMinCurrencyValue rdf:datatype="xsd:decimal">
            <xsl:value-of select="LOW_VALUE/@FMTVAL"/>
        </gr:hasMinCurrencyValue>
        <gr:hasMaxCurrencyValue rdf:datatype="xsd:decimal">
            <xsl:value-of select="HIGH_VALUE/@FMTVAL"/>
        </gr:hasMaxCurrencyValue>
    </xsl:template>
    
    <!-- contract expected duration --> 
    <xsl:template match="PERIOD_WORK_DATE_STARTING">
        <xsl:apply-templates select="DAYS"/>
        <xsl:apply-templates select="MONTHS"/>
        <xsl:apply-templates select="INTERVAL_DATE"/>
    </xsl:template>
    
    <!-- duration in days -->
    <xsl:template match="DAYS">
        <pc:duration rdf:datatype="xsd:duration">
            <xsl:value-of select="f:getDuration(text(), 'D')"/>
        </pc:duration>
    </xsl:template>
    
    <!-- duration in months -->
    <xsl:template match="MONTHS">
        <pc:duration rdf:datatype="xsd:duration">
            <xsl:value-of select="f:getDuration(text(), 'M')"/>
        </pc:duration>
    </xsl:template>
    
    <!-- duration as start date and estimated end date -->
    <xsl:template match="INTERVAL_DATE">
        <xsl:apply-templates select="START_DATE"/>
        <xsl:apply-templates select="END_DATE"/>
    </xsl:template>
    
    <!-- interval start date -->
    <xsl:template match="START_DATE">
        <pc:startDate rdf:datatype="xsd:date">
            <xsl:value-of select="f:getDate(YEAR, MONTH, DAY)"/>        
        </pc:startDate>
    </xsl:template>
    
    <!-- interval estimated end date -->
    <xsl:template match="END_DATE">
        <pc:estimatedEndDate rdf:datatype="xsd:date">
            <xsl:value-of select="f:getDate(YEAR, MONTH, DAY)"/>        
        </pc:estimatedEndDate>
    </xsl:template>
    
    <!--
    *********************************************************
    *** SECTION IV: PROCEDURE
    *********************************************************
    -->
    <xsl:template match="PROCEDURE_DEFINITION_CONTRACT_NOTICE">
        <xsl:apply-templates select="TYPE_OF_PROCEDURE/TYPE_OF_PROCEDURE_DETAIL_FOR_CONTRACT_NOTICE"/>
        <xsl:apply-templates select="AWARD_CRITERIA_CONTRACT_NOTICE_INFORMATION/AWARD_CRITERIA_DETAIL"/>
        <xsl:apply-templates select="ADMINISTRATIVE_INFORMATION_CONTRACT_NOTICE"/>
    </xsl:template>
    
    <xsl:template match="ADMINISTRATIVE_INFORMATION_CONTRACT_NOTICE">
        <xsl:apply-templates select="FILE_REFERENCE_NUMBER"/>
        <xsl:apply-templates select="CONDITIONS_OBTAINING_SPECIFICATIONS"/>
        <xsl:apply-templates select="RECEIPT_LIMIT_DATE"/>
        <xsl:apply-templates select="MINIMUM_TIME_MAINTAINING_TENDER"/>
    </xsl:template>
    
    <xsl:template match="CONDITIONS_OBTAINING_SPECIFICATIONS">
        <xsl:apply-templates select="TIME_LIMIT"/>
        <xsl:apply-templates select="PAYABLE_DOCUMENTS/DOCUMENT_COST"/>
    </xsl:template>
    
    <!-- contract procedure type -->
    <xsl:template match="TYPE_OF_PROCEDURE_DETAIL_FOR_CONTRACT_NOTICE">
        <xsl:call-template name="procedureType">
            <xsl:with-param name="ptElementName" select="local-name(*)"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- contract criteria -->
    <xsl:template match="AWARD_CRITERIA_DETAIL[LOWEST_PRICE or MOST_ECONOMICALLY_ADVANTAGEOUS_TENDER/CRITERIA_STATED_BELOW]">
        <pc:awardCriteriaCombination> 
            <pc:AwardCriteriaCombination rdf:about="{$pc_award_criteria_combination_uri_1}">
                <xsl:apply-templates select="LOWEST_PRICE|MOST_ECONOMICALLY_ADVANTAGEOUS_TENDER/CRITERIA_STATED_BELOW/CRITERIA_DEFINITION"/>
            </pc:AwardCriteriaCombination>
        </pc:awardCriteriaCombination>
    </xsl:template>
    
    <!-- criterion lowest price -->
    <xsl:template match="LOWEST_PRICE">
        <xsl:call-template name="awardCriterion">
            <xsl:with-param name="isLowestPrice" select="true()"/>
            <xsl:with-param name="id" select="1"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- criterion most economically advantageous tender -->
    <xsl:template match="CRITERIA_DEFINITION">
        <xsl:variable name="id">
                <xsl:choose>
                    <xsl:when test="ORDER_C">
                        <xsl:value-of select="ORDER_C"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="position()"/>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="awardCriterion">
            <xsl:with-param name="isLowestPrice" select="false()"/>
            <xsl:with-param name="name" select="CRITERIA"/>
            <xsl:with-param name="weight" select="WEIGHTING"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- contract file identifier -->
    <xsl:template match="FILE_REFERENCE_NUMBER">
        <adms:identifier>
            <adms:Identifier rdf:about="{$pc_identifier_uri_1}">
                <skos:notation>
                    <xsl:value-of select="normalize-space(.)" />
                </skos:notation>
            </adms:Identifier>
        </adms:identifier>
    </xsl:template>
    
    <!-- contract documentation request deadline -->
    <xsl:template match="TIME_LIMIT">
        <pc:documentationRequestDeadline rdf:datatype="xsd:dateTime">
            <xsl:value-of select="f:getDateTime(YEAR, MONTH, DAY, TIME)"/>
        </pc:documentationRequestDeadline>
    </xsl:template>
    
    <!-- contract documentation price -->
    <xsl:template match="PAYABLE_DOCUMENTS/DOCUMENT_COST">
        <pc:documentationPrice>
            <gr:PriceSpecification rdf:about="{$pc_documentation_price_uri_1}">
                <xsl:call-template name="priceValue">
                    <xsl:with-param name="value" select="@FMTVAL"/>
                </xsl:call-template>
                <xsl:call-template name="currency">
                    <xsl:with-param name="currencyCode" select="@CURRENCY"/>
                </xsl:call-template>
            </gr:PriceSpecification>
        </pc:documentationPrice>
    </xsl:template>
    
    <!-- contract tender deadline -->
    <xsl:template match="RECEIPT_LIMIT_DATE">
        <pc:tenderDeadline rdf:datatype="xsd:dateTime">
            <xsl:value-of select="f:getDateTime(YEAR, MONTH, DAY, TIME)"/>
        </pc:tenderDeadline>
    </xsl:template>
    
    <!-- tender maintenance duration -->
    <xsl:template match="MINIMUM_TIME_MAINTAINING_TENDER">
        <xsl:if test="PERIOD_DAY|PERIOD_MONTH">
            <pc:tenderMaintenanceDuration rdf:datatype="xsd:duration">
                <xsl:apply-templates select="PERIOD_DAY"/>
                <xsl:apply-templates select="PERIOD_MONTH"/>
            </pc:tenderMaintenanceDuration>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="PERIOD_DAY">
        <xsl:value-of select="f:getDuration(text(), 'D')"/>
    </xsl:template>
    
    <xsl:template match="PERIOD_MONTH">
        <xsl:value-of select="f:getDuration(text(), 'M')"/>
    </xsl:template>
    
    <!-- tenders opening (is outside of Contract element!) -->
    <xsl:template match="CONDITIONS_FOR_OPENING_TENDERS">
        <xsl:if test="DATE_TIME|PLACE_OPENING">
            <pc:TendersOpening>
                <pc:Contract rdf:resource="{$pc_uri}"/>
                <xsl:apply-templates select="DATE_TIME"/>
                <xsl:apply-templates select="PLACE_OPENING"/>
           </pc:TendersOpening>
        </xsl:if>
    </xsl:template>
    
    <!-- tenders opening date -->
    <xsl:template match="CONDITIONS_FOR_OPENING_TENDERS/DATE_TIME">
        <dcterms:date rdf:datatype="xsd:dateTime">
            <xsl:value-of select="f:getDateTime(YEAR, MONTH, DAY, TIME)"/>
        </dcterms:date>
    </xsl:template>
    
    <!-- tenders opening place -->
    <xsl:template match="CONDITIONS_FOR_OPENING_TENDERS/PLACE_OPENING">
        <s:location>
            <s:Place rdf:about="{$tenders_opening_place_uri_1}">
                <xsl:call-template name="postalAddress"></xsl:call-template>
                <xsl:apply-templates select="PLACE_NOT_STRUCTURED"/>
            </s:Place>
        </s:location>
    </xsl:template>
    
    <xsl:template match="PLACE_NOT_STRUCTURED">
        <s:description>
            <xsl:value-of select="normalize-space(.)"/>
        </s:description>
    </xsl:template>
    
    
    <!--
    *********************************************************
    *** NAMED TEMPLATES
    *********************************************************
    -->
    <xsl:template name="legalName">
        <gr:legalName>
            <xsl:value-of select="normalize-space(ORGANISATION/OFFICIALNAME/text())"/>
        </gr:legalName>
    </xsl:template>

    <xsl:template name="postalAddress">
        <xsl:if test="(ADDRESS|TOWN|POSTAL_CODE|COUNTRY)/text()">
            <s:address>
                <s:PostalAddress>
                    <xsl:apply-templates select="ADDRESS"/>
                    <xsl:apply-templates select="TOWN"/>
                    <xsl:apply-templates select="POSTAL_CODE"/>
                    <xsl:apply-templates select="COUNTRY"/>
                </s:PostalAddress>
            </s:address>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="description">
        <dcterms:description xml:lang="{$lang}">
            <xsl:value-of select="normalize-space(.)"/>
        </dcterms:description> 
    </xsl:template>
    
    <xsl:template name="priceValue">
        <xsl:param name="value"/>
        <gr:hasCurrencyValue rdf:datatype="xsd:decimal">
            <xsl:value-of select="$value"/>
        </gr:hasCurrencyValue>
    </xsl:template>
    
    <xsl:template name="currency">
        <xsl:param name="currencyCode"/>
        <gr:hasCurrency>
            <xsl:value-of select="$currencyCode"/>
        </gr:hasCurrency>
    </xsl:template>
    
    <xsl:template name="procedureType">
        <xsl:param name="ptElementName"/>
        <pc:procedureType rdf:resource="{f:getProcedureType($ptElementName)}"/>      
    </xsl:template>
    
    <xsl:template name="awardCriterion">
        <xsl:param name="isLowestPrice" as="xsd:boolean"/>
        <xsl:param name="name"/>
        <xsl:param name="weight"/>
        <xsl:param name="id" required="yes"/>
        <pc:awardCriterion>
            <pc:CriterionWeighting>
                <xsl:choose>
                    <xsl:when test="$isLowestPrice = true()">
                        <pc:weightedCriterion rdf:resource="{$pc_criterion_lowest_price_uri}"/>
                        <xsl:call-template name="criterionWeight">
                            <xsl:with-param name="weight" select="100"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <pc:weightedCriterion>
                            <skos:Concept  rdf:about="{concat($pc_weighted_criterion_nm, $id)}">
                                <skos:prefLabel xml:lang="{$lang}">
                                    <xsl:value-of select="$name"/>
                                </skos:prefLabel>
                                <skos:inScheme rdf:resource="{$pc_criteria_nm}" />
                                <skos:topConceptOf rdf:resource="{$pc_criteria_nm}" />
                            </skos:Concept>
                        </pc:weightedCriterion>
                        <xsl:call-template name="criterionWeight">
                            <xsl:with-param name="weight" select="$weight"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                </pc:CriterionWeighting>
        </pc:awardCriterion>
    </xsl:template>
    
    <xsl:template name="criterionWeight">
        <xsl:param name="weight"/>
        <xsl:if test="$weight">
            <pc:criterionWeight rdf:datatype="pcdt:percentage">
                <xsl:value-of select="$weight"/>       
            </pc:criterionWeight>
        </xsl:if>
    </xsl:template>
    
    
    <!--
    *********************************************************
    *** COMMON TEMPLATES
    *********************************************************
    -->
    <xsl:template match="ADDRESS">
        <xsl:if test="text()">
            <s:streetAddress>
                <xsl:value-of select="text()"/>
            </s:streetAddress>
        </xsl:if>
    </xsl:template>

    <xsl:template match="TOWN">
        <xsl:if test="text()">
            <s:addressLocality>
                <xsl:value-of select="text()"/>
            </s:addressLocality>
        </xsl:if>
    </xsl:template>

    <xsl:template match="POSTAL_CODE">
        <xsl:if test="text()">
            <s:postalCode>
                <xsl:value-of select="text()"/>
            </s:postalCode>
        </xsl:if>
    </xsl:template>

    <xsl:template match="COUNTRY">
        <xsl:if test="@VALUE">
            <s:addressCountry>
                <xsl:value-of select="@VALUE"/>
            </s:addressCountry>
        </xsl:if>
    </xsl:template>

    <xsl:template match="CONTACT_POINT">
        <xsl:if test="text()">
            <vcard:note>
                <xsl:value-of select="text()"/>
            </vcard:note>
        </xsl:if>
    </xsl:template>

    <xsl:template match="ATTENTION">
        <xsl:if test="text()">
            <vcard:fn>
                <xsl:value-of select="text()"/>
            </vcard:fn>
        </xsl:if>
    </xsl:template>

    <xsl:template match="E_MAIL">
        <xsl:if test="text()">
            <vcard:email rdf:resource="{concat('mailto:', text())}"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="PHONE">
        <xsl:if test="text()">
            <vcard:tel>
                <vcard:Work>
                    <rdf:value>
                        <xsl:value-of select="text()"/>
                    </rdf:value>
                </vcard:Work>
            </vcard:tel>
        </xsl:if>
    </xsl:template>

    <xsl:template match="FAX">
        <xsl:if test="text()">
            <vcard:tel>
                <vcard:Fax>
                    <rdf:value>
                        <xsl:value-of select="text()"/>
                    </rdf:value>
                </vcard:Fax>
            </vcard:tel>
        </xsl:if>
    </xsl:template>



    <!--
    *********************************************************
    *** EMPTY TEMPLATES
    *********************************************************
    -->
    <xsl:template match="text()|@*"/>

</xsl:stylesheet>
