xquery version "3.1" encoding "UTF-8";

(:
    XQuery script that validates the reported data on the EPRTR and LCP report.
:)

import module namespace functx = "http://www.functx.com" at "eprtr-lcp-functx.xq";
import module namespace eworx = "http://www.eworx.gr" at "eprtr-lcp-eworx.xq";
import module namespace scripts = "eprtr-lcp-scripts" at "eprtr-lcp-scripts.xq";

declare namespace xmlconv = "http://converters.eionet.europa.eu";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace array = "http://www.w3.org/2005/xpath-functions/array";

declare variable $source_url as xs:string external;
(: xml files paths:)

(:declare variable $xmlconv:BASIC_DATA_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_basicdata.xml");:)
(:declare variable $xmlconv:OLD_PLANTS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_v2_plantsdb.xml");:)
(:declare variable $xmlconv:CLRTAP_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_clrtap.xml");:)
(:declare variable $xmlconv:FINDINGS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_Findings_Step1.xml");:)

(:declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/average_emissions.xml";:)
declare variable $xmlconv:PRODUCTION_FACILITY_LOOKUP as xs:string :=
    "../lookup-tables/ProductionFacility.xml";
declare variable $xmlconv:PRODUCTION_INSTALLATIONPART_LOOKUP as xs:string :=
    "../lookup-tables/ProductionInstallationPart.xml";
declare variable $xmlconv:POLLUTANT_LOOKUP as xs:string :=
    "../lookup-tables/EPRTR-LCP_PollutantLookup.xml";
declare variable $xmlconv:CrossPollutants as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C10.3_CrossPollutants.xml";
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C12.1_OffsiteWasteTransfer.xml";
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C12.1_PollutantTransfer.xml";
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantRelease as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C12.1_PollutantRelease.xml";
declare variable $xmlconv:ANNEX_II_THRESHOLD as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C12.2_ThreshholdLookup.xml";
declare variable $xmlconv:QUANTITY_OF_PollutantRelease as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.4_PollutantRelease.xml";
declare variable $xmlconv:QUANTITY_OF_PollutantTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.4_PollutantTransfer.xml";
declare variable $xmlconv:QUANTITY_OF_OffsiteWasteTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.4_OffsiteWasteTransfer.xml";
declare variable $xmlconv:EUROPEAN_TOTAL_PollutantRelease as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C14.2_PollutantRelease.xml";
declare variable $xmlconv:EUROPEAN_TOTAL_PollutantTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C14.2_PollutantTransfer.xml";
declare variable $xmlconv:EUROPEAN_TOTAL_OffsiteWasteTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C14.2_OffsiteWasteTransfer.xml";
declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C10.1-C10.2_EFLookup.xml";
declare variable $xmlconv:COUNT_OF_PROD_FACILITY_WASTE_TRANSFER as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.1_OffsiteWasteTransfer.xml";
declare variable $xmlconv:AVERAGE_3_YEARS as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C12.6.xml";
declare variable $xmlconv:CLRTAP_DATA as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C15.1_CLRTAP_data.xml";
declare variable $xmlconv:CLRTAP_POLLUTANT_LOOKUP as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C15.1_CLRTAP_pollutant_lookup.xml";
declare variable $xmlconv:UNFCC_DATA as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C15.1_UNFCCC_data.xml";
declare variable $xmlconv:UNFCC_POLLUTANT_LOOKUP as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C15.1_UNFCCC_pollutant_lookup.xml";
declare variable $xmlconv:COUNT_OF_PollutantRelease as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.1-C13.2-C13.3_PollutantRelease.xml";
declare variable $xmlconv:COUNT_OF_PollutantTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.1-C13.2-C13.3_PollutantTransfer.xml";
declare variable $xmlconv:COUNT_OF_OffsiteWasteTransfer as xs:string :=
    "https://converterstest.eionet.europa.eu/xmlfile/EPRTR-LCP_C13.2_OffsiteWasteTransfer.xml";

(:declare variable $eworx:SchemaModel := eworx:getSchemaModel($source_url);:)

declare function xmlconv:RowBuilder (
        $RuleCode as xs:string,
        $RuleName as xs:string,
        $ResDetails as element()*
) as element( ) *{

  let $RuleCode := fn:substring-after($RuleCode, ' ')

    let $errors := $ResDetails/td[@class = 'error']
    let $warnings := $ResDetails/td[@class = 'warning']
    let $info := $ResDetails/td[@class = 'info']

    let $ResCode := if ( fn:count($errors) > 0) then 'error'
    else if   ( fn:count($warnings) > 0 ) then 'warning'
    else if   ( fn:count($info) > 0 ) then 'info'
    else 'passed'

    (: $ResCode the result of the QA :)

    (: TESTING :)
    let $ResMessage :=
        <p>
            { fn:count($errors) } Errors,
            { fn:count($warnings) } Warnings
            { if (fn:count($info) > 0) then fn:concat(' , ' ,xs:string(fn:count($info)), ' Info' ) else () }
        </p>

    let $step1 :=
        (: Row Result :)
        <tr class="mainviewrow">
            <td class="bullet">
                <div class="{$ResCode}">{ $RuleCode }</div>
            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (fn:count($ResDetails) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}'
                        href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")' class="feedback">
                        Show records
                    </a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
                }
            </tr>

    let $step2 := if (fn:count($ResDetails) > 0 ) then
        <tr style="display:none;" id="feedbackRow-{$RuleCode}">
            <td colspan="4">
                <table class="showdatatable table table-bordered" >
                    <tr>{
                        for $th in $ResDetails[1]//td return <th>{ fn:data($th/@title) }</th>
                    }</tr>
                    {$ResDetails}


                </table>
            </td>
        </tr>
    else ()

    return ( $step1 , $step2 )


    };

declare function xmlconv:RowAggregator (
        $RuleCode as xs:string,
        $RuleName as xs:string,
        $ResRows as element()*
) as element( ) *{

  let $RuleCode := fn:substring-after($RuleCode, ' ')

    let $errors := $ResRows/td/div[@class = 'error']
    let $warnings := $ResRows/td/div[@class = 'warning']
    let $info := $ResRows/td/div[@class = 'info']

    let $ResCode := if ( fn:count($errors) > 0) then 'error'
    else if   ( fn:count($warnings) > 0 ) then 'warning'
        else if   ( fn:count($info) > 0 ) then 'info'
            else 'passed'


    (: TESTING :)
    let $ResMessage :=
        <p>
            {fn:count($errors)} Subchecks issued Errors,
            {fn:count($warnings)} Subchecks issued Warnings
            {if (fn:count($info) > 0) then fn:concat(' , ' ,xs:string(fn:count($info)), ' Info' ) else ()}
        </p>

    let $step1 :=
        (: Row Result :)
        <tr class="detailsrow">
            <td class="bullet">

                <div class="{$ResCode}">{ $RuleCode }</div>

            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (fn:count($ResRows) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}'
                        href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")'>
                        Show records
                    </a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
            }
        </tr>

    let $step2 := if (fn:count($ResRows) > 0 ) then
        <tr style="display:none;" id="feedbackRow-{$RuleCode}">
            <td colspan="1">
                <td colspan="4">
                <table class="detailstable table table-bordered">

                    {
                        for $res in $ResRows return ( $res  )
                    }

                </table>
                </td>
            </td>
        </tr>
    else ()

    return ( $step1 , $step2 )


};

declare function xmlconv:InspireIdUniqueness(
    $docRoot as node()*,
    $featureType as xs:string
) as element()*{
    let $seq := $docRoot//*[fn:local-name() = $featureType]
    let $allInspireIds := fn:data($seq/InspireId)
    for $elem in fn:distinct-values($seq/InspireId)
    return
        if(fn:count(fn:index-of($allInspireIds, fn:data($elem))) > 1)
        then
            <tr>
                <td class='error' title="Details">InspireId is not unique</td>
                <td class="tderror" title="InspireId"> {fn:data($elem)} </td>
            </tr>
        else
            ()
};

declare function xmlconv:isInVocabulary(
        $seq as element()*,
        $concept as xs:string
) as element()*{
    let $valid := scripts:getValidConcepts($concept)
        for $elem in $seq
        let $ok := (
            $valid = fn:data($elem)
            or
            fn:string-length(fn:data($elem)) = 0
        )
        return
            if (fn:not($ok))
            then
                <tr>
                    <td class='error' title="Details"> {$concept} has not been recognised</td>
                    <td title='inspireId'>{$elem/ancestor::*[InspireId]/InspireId}</td>
                    <td title='Feature type'>{$elem/parent::*/local-name()}</td>
                    <td class="tderror" title="{fn:node-name($elem)}"> {fn:data($elem)} </td>

                </tr>
            else
                ()
};

declare function xmlconv:RunQAs(
        $source_url
) as element()* {

    let $docRoot := fn:doc($source_url)
    let $docPollutantLookup := fn:doc ($xmlconv:POLLUTANT_LOOKUP)
    let $docAverage := fn:doc($xmlconv:AVERAGE_3_YEARS)
    let $docEmissions := fn:doc($xmlconv:AVG_EMISSIONS_PATH)
    let $docCrossPollutants := fn:doc($xmlconv:CrossPollutants)
    let $docANNEXII := fn:doc($xmlconv:ANNEX_II_THRESHOLD)
    let $docEUROPEAN_TOTAL_PollutantRelease := fn:doc($xmlconv:EUROPEAN_TOTAL_PollutantRelease)
    let $docEUROPEAN_TOTAL_PollutantTransfer := fn:doc($xmlconv:EUROPEAN_TOTAL_PollutantTransfer)
    let $docEUROPEAN_TOTAL_OffsiteWasteTransfer := fn:doc($xmlconv:EUROPEAN_TOTAL_OffsiteWasteTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer := fn:doc($xmlconv:NATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_PollutantTransfer := fn:doc($xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_PollutantRelease := fn:doc($xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantRelease)
    let $docQUANTITY_OF_OffsiteWasteTransfer := fn:doc($xmlconv:QUANTITY_OF_OffsiteWasteTransfer)
    let $docQUANTITY_OF_PollutantRelease := fn:doc($xmlconv:QUANTITY_OF_PollutantRelease)
    let $docQUANTITY_OF_PollutantTransfer := fn:doc($xmlconv:QUANTITY_OF_PollutantTransfer)
    let $docRootCOUNT_OF_PollutantRelease := fn:doc($xmlconv:COUNT_OF_PollutantRelease)
    let $docRootCOUNT_OF_PollutantTransfer := fn:doc($xmlconv:COUNT_OF_PollutantTransfer)
    let $docRootCOUNT_OF_ProdFacilityOffsiteWasteTransfer := fn:doc($xmlconv:COUNT_OF_PROD_FACILITY_WASTE_TRANSFER)
    let $docRootCOUNT_OF_OffsiteWasteTransfer := fn:doc($xmlconv:COUNT_OF_OffsiteWasteTransfer)

    let $docProductionFacilities := fn:doc($xmlconv:PRODUCTION_FACILITY_LOOKUP)
    let $docProductionInstallationParts := fn:doc($xmlconv:PRODUCTION_INSTALLATIONPART_LOOKUP)

    let $country_code := $docRoot//countryId/fn:data()=>functx:substring-after-last("/")
    let $look-up-year := $docRoot//reportingYear => fn:number() - 2
    let $previous-year := $docRoot//reportingYear => fn:number() - 1
    let $pollutantCodes := $docPollutantLookup//row/PollutantCode/text() => fn:distinct-values()

    (:  C1.1 – combustionPlantCategory consistency  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/combustionPlantCategory/combustionPlantCategory
        return xmlconv:isInVocabulary($seq, "CombustionPlantCategoryValue")
    let $LCP_1_1 := xmlconv:RowBuilder("EPRTR-LCP 1.1","combustionPlantCategory consistency", $res )

    (:  C1.2 – CountryCode consistency  :)
    let $res :=
        let $seq := $docRoot//*[fn:local-name() = ("countryCode", "countryId") and text()=>fn:string-length() > 0]
        return xmlconv:isInVocabulary($seq, "CountryCodeValue")
    let $LCP_1_2 := xmlconv:RowBuilder("EPRTR-LCP 1.2","CountryCode consistency", $res )

    (:  C1.3 – EPRTRPollutant consistency   :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
                /*[fn:local-name() = ("offsitePollutantTransfer", "pollutantRelease")]//pollutant
        return xmlconv:isInVocabulary($seq, "EPRTRPollutantCodeValue")
    let $LCP_1_3 := xmlconv:RowBuilder("EPRTR-LCP 1.3","EPRTRPollutantCodeValue consistency", $res )

    (:  C1.4 – fuelInput consistency    :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport//fuelInput/fuelInput
        return xmlconv:isInVocabulary($seq, "FuelInputValue")
    let $LCP_1_4 := xmlconv:RowBuilder("EPRTR-LCP 1.4","FuelInputValue consistency", $res )

    (:  C1.5 – LCPPollutant consistency :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant
        return xmlconv:isInVocabulary($seq, "LCPPollutantCodeValue")
    let $LCP_1_5 := xmlconv:RowBuilder("EPRTR-LCP 1.5","LCPPollutantCodeValue consistency", $res )

    (:  C1.6 – mediumCode consistency   :)
    let $res :=
        let $seq := $docRoot//pollutantRelease/mediumCode
        return xmlconv:isInVocabulary($seq, "MediumCodeValue")
    let $LCP_1_6 := xmlconv:RowBuilder("EPRTR-LCP 1.6","MediumCodeValue consistency", $res )

    (:  C1.7 - methodClassification consistency :)
    let $res :=
        let $seq := $docRoot//methodClassification
        return xmlconv:isInVocabulary($seq, "MethodClassificationValue")
    let $LCP_1_7 := xmlconv:RowBuilder("EPRTR-LCP 1.7","MethodClassificationValue consistency", $res )

    (:  C1.8 - methodCode consistency   :)
    let $res :=
        let $seq := $docRoot//methodCode
        return xmlconv:isInVocabulary($seq, "MethodCodeValue")
    let $LCP_1_8 := xmlconv:RowBuilder("EPRTR-LCP 1.8","MethodCodeValue consistency", $res )

    (:  C1.9 – Month Consistency    :)
    let $res :=
        let $seq := $docRoot//desulphurisationInformation[fn:string-length(desulphurisationRate) != 0]/month
        return xmlconv:isInVocabulary($seq, "MonthValue")
    let $LCP_1_9 := xmlconv:RowBuilder("EPRTR-LCP 1.9","MonthValue consistency", $res )

    (:  C1.10 – OtherGaseousFuel consistency    :)
    let $res :=
        let $otherGases := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherGases"
        let $seq :=
            $docRoot//ProductionInstallationPartReport/energyInput/fuelInput[fuelInput = $otherGases]/otherGaseousFuel
        return xmlconv:isInVocabulary($seq, "OtherGaseousFuelValue")
    let $LCP_1_10 := xmlconv:RowBuilder("EPRTR-LCP 1.10","OtherGaseousFuelValue consistency", $res )

    (:  C1.11 – OtherSolidFuel consistency  :)
    let $res :=
        let $otherSolidFuel := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels"
        let $seq :=
            $docRoot//ProductionInstallationPartReport/energyInput/fuelInput[fuelInput = $otherSolidFuel]/otherSolidFuel
        return xmlconv:isInVocabulary($seq, "OtherSolidFuelValue")
    let $LCP_1_11 := xmlconv:RowBuilder("EPRTR-LCP 1.11","OtherSolidFuelValue consistency", $res )

    (:  C1.12 - ReasonValue consistency :)
    let $res :=
        let $seq := $docRoot//confidentialityReason[text() => fn:string-length() > 0]
        return xmlconv:isInVocabulary($seq, "ReasonValue")
    let $LCP_1_12 := xmlconv:RowBuilder("EPRTR-LCP 1.12","ReasonValue consistency", $res )

    (:  C1.13 – UnitCode consistency    :)
    let $res :=
        let $seq := $docRoot//productionVolumeUnits
        return xmlconv:isInVocabulary($seq, "UnitCodeValue")
    let $LCP_1_13 := xmlconv:RowBuilder("EPRTR-LCP 1.13","UnitCodeValue consistency", $res )

    (:  C1.14 – wasteClassification consistency :)
    let $res :=
        let $seq := $docRoot//wasteClassification
        return xmlconv:isInVocabulary($seq, "WasteClassificationValue")
    let $LCP_1_14 := xmlconv:RowBuilder("EPRTR-LCP 1.14","WasteClassificationValue consistency", $res )

    (:  C1.15 – wasteTreatment consistency  :)
    let $res :=
        let $seq := $docRoot//wasteTreatment
        return xmlconv:isInVocabulary($seq, "WasteTreatmentValue")
    let $LCP_1_15 := xmlconv:RowBuilder("EPRTR-LCP 1.15","WasteTreatmentValue consistency", $res )

    let $LCP_1 := xmlconv:RowAggregator(
            "EPRTR-LCP 1",
            "Code list checks",
            (
                $LCP_1_1,
                $LCP_1_2,
                $LCP_1_3,
                $LCP_1_4,
                $LCP_1_5,
                $LCP_1_6,
                $LCP_1_7,
                $LCP_1_8,
                $LCP_1_9,
                $LCP_1_10,
                $LCP_1_11,
                $LCP_1_12,
                $LCP_1_13,
                $LCP_1_14,
                $LCP_1_15
            )
    )

    let $facilityInspireIds :=
        $docProductionFacilities//ProductionFacility[year = $previous-year]/InspireId
    let $installationPartInspireIds :=
        $docProductionInstallationParts//ProductionInstallationPart[year = $previous-year]/InspireId

    (: TODO not final version :)
    (:  C2.1 – inspireId consistency    :)
    let $res :=
        let $errorType := 'error'
        let $text := 'InspireId could not be found within the EU Registry'
        let $map := map {
            'ProductionInstallationPartReport': $installationPartInspireIds,
            'ProductionFacilityReport': $facilityInspireIds
        }
        for $featureType in $docRoot//*[local-name() = map:keys($map)]
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'Feature type': map {'pos': 2, 'text': $featureType/local-name()},
                'InspireId':
                    map {'pos': 3, 'text': $featureType/InspireId, 'errorClass': 'td' || $errorType}
            }
            let $ok := $featureType/InspireId/data() = $map?($featureType/local-name())
            return
                if(not($ok))
                (:if(false()):)
                (:if(true()):)
                then scripts:generateResultTableRow($dataMap)
                else ()
    let $LCP_2_1 := xmlconv:RowBuilder("EPRTR-LCP 2.1","inspireId consistency", $res)

    (: TODO needs more testing :)
    (:  C2.2 – Comprehensive LCP reporting    :)
    let $res :=
        let $errorType := 'error'
        let $text := 'InspireId could not be found within the E-PRTR and LCP integrated reporting XML'
        let $map := map {
            'ProductionInstallationPartReport': $installationPartInspireIds,
            'ProductionFacilityReport': $facilityInspireIds
        }
        for $featureType in map:keys($map)
            let $reportInspireIds := $docRoot//*[local-name() = $featureType]/InspireId/data()
            for $inspideId in $map?($featureType)
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'Feature type': map {'pos': 2, 'text': $featureType},
                'InspireId': map {'pos': 3, 'text': $inspideId, 'errorClass': 'td' || $errorType}
            }
            let $ok := $inspideId = $reportInspireIds
            return
                if(not($ok))
                (:if(false()):)
                (:if(true()):)
                then scripts:generateResultTableRow($dataMap)
                else ()
    let $LCP_2_2 := xmlconv:RowBuilder("EPRTR-LCP 2.2","Comprehensive LCP reporting", $res)

    (:  C2.3 – ProductionFacility inspireId uniqueness    :)
    let $res := xmlconv:InspireIdUniqueness($docRoot, "ProductionFacilityReport")
    let $LCP_2_3 := xmlconv:RowBuilder("EPRTR-LCP 2.3","ProductionFacility inspireId uniqueness", $res)

    (:  C2.4 – ProductionInstallationPart inspireId uniqueness    :)
    let $res := xmlconv:InspireIdUniqueness($docRoot, "ProductionInstallationPartReport")
    let $LCP_2_4 := xmlconv:RowBuilder("EPRTR-LCP 2.4","ProductionInstallationPart inspireId uniqueness", $res)

    let $LCP_2 := xmlconv:RowAggregator(
            "EPRTR-LCP 2",
            "inspireId checks",
            (
                $LCP_2_1,
                $LCP_2_2,
                $LCP_2_3,
                $LCP_2_4
            )
    )

    let $getAdditionalInformation := function (
        $element as element()
    ) as xs:string {
        let $map := map {
            'offsiteWasteTransfer': ('wasteClassification', 'wasteTreatment'),
            'offsitePollutantTransfer': ('pollutant'),
            'pollutantRelease': ('pollutant', 'mediumCode'),
            'emissionsToAir': ('pollutant')
        }
        let $elementName := $element/local-name()
        let $infoSequence :=
            for $info in $map?($elementName)
                return $element/*[local-name() = $info]/data() => functx:substring-after-last("/")
        return $infoSequence => fn:string-join(' / ')
    }

    (:  C3.1 – Pollutant reporting completeness     :)
    let $res :=
(:
        let $pollutants := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOx",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/Dust"
        )
:)
        let $pollutants :=
            $docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant => fn:distinct-values()

        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        for $pollutant in $pollutants
        return
            if (fn:count(fn:index-of($elem/emissionsToAir/pollutant, $pollutant)) = 0)
            then
                <tr>
                    <td class='warning' title="Details"> Pollutant has not been reported</td>
                    <td class="tdwarning" title="Pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
                    <td title="Feature type">emissionsToAir</td>
                    <td title="inspireId">{$elem/InspireId}</td>
                </tr>
            else
                ()
    let $LCP_3_1 := xmlconv:RowBuilder("EPRTR-LCP 3.1","Pollutant reporting completeness", $res)

    (:  C3.2 - EnergyInput reporting completeness   :)
    let $res :=
        let $fuelInputs := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Biomass",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Coal",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Lignite",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/LiquidFuels",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/NaturalGas",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherGases",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Peat"
        )
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        for $fuel in $fuelInputs
        return
            if (fn:count(fn:index-of($elem/energyInput/fuelInput/fuelInput, $fuel)) = 0)
            then
                <tr>
                    <td class='warning' title="Details"> FuelInput has not been reported</td>
                    <td class="tdwarning" title="FuelInput"> {functx:substring-after-last($fuel, "/")} </td>
                    <td title="localId">{$elem/descendant::*/localId}</td>
                    <td title="namespace">{$elem/descendant::*/namespace}</td>
                </tr>
            else
                ()
    let $LCP_3_2 := xmlconv:RowBuilder("EPRTR-LCP 3.2","EnergyInput reporting completeness", $res)

    (:  C3.3 – ‘other’ fuel reporting completeness  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        for $fuel in $elem/energyInput/fuelInput
        let $ok :=
            if (functx:substring-after-last($fuel/otherGaseousFuel, "/") = "Other")
            then
                functx:if-empty($fuel/furtherDetails, "") != ""
            else
                if (functx:substring-after-last($fuel/otherSolidFuel, "/") = "Other")
                then
                functx:if-empty($fuel/furtherDetails, "") != ""
                else
                    fn:true()
        return
            if(fn:not($ok))
            then
                <tr>
                    <td class='warning' title="Details">
                        Other fuel has not been expanded upon under the furtherDetails attribute
                    </td>
                    <td title="FuelInput"> {functx:substring-after-last($fuel/fuelInput, "/")} </td>
                    <td title="Other fuel">
                        {
                            if (functx:substring-after-last($fuel/otherGaseousFuel, "/") = "Other")
                            then
                                functx:substring-after-last($fuel/otherGaseousFuel, "/")
                            else
                                functx:substring-after-last($fuel/otherSolidFuel, "/")
                        }
                    </td>
                    <td class="tdwarning" title="furtherDetails">{$fuel/furtherDetails}</td>
                    <td title="localId">{$elem/descendant::*/localId}</td>
                    <td title="namespace">{$elem/descendant::*/namespace}</td>
                </tr>
            else
                ()
    let $LCP_3_3 := xmlconv:RowBuilder("EPRTR-LCP 3.3","Other fuel reporting completeness", $res)

    (:  C3.4 – Comprehensive methodClassification reporting :)
    let $res :=
        let $seq := $docRoot//method
        let $concept := "MethodClassificationValue"
        let $valid := scripts:getValidConcepts($concept)
        for $elem in $seq
        let $ok := ($valid = fn:data($elem/methodClassification))
        return
            if (
                fn:not($ok)
                and
                functx:substring-after-last($elem/methodCode, "/") = ("M", "C")
            )
            then
                <tr>
                    <td class='warning' title="Details"> {$concept} has not been recognised</td>
                    <td title="inspireId">{$elem/ancestor::*[InspireId]/InspireId}</td>
                    <td class="tdwarning" title="{fn:node-name($elem/methodClassification)}">
                        {$elem/methodClassification/text()}
                    </td>
                    <td title="methodCode">{functx:substring-after-last($elem/methodCode, "/")}</td>
                    <td title="Feature type">{$elem/parent::*/local-name()}</td>
                    <td title="Additional info">{$getAdditionalInformation($elem/parent::*)}</td>
                </tr>
            else
                ()
    let $LCP_3_4 := xmlconv:RowBuilder("EPRTR-LCP 3.4","Comprehensive methodClassification reporting", $res)

    (:  C3.5 – Required furtherDetails for reporting methodClassification   :)
    let $res :=
        let $methodClassifications := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/CEN-ISO",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/UNECE-EMEP",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/OTH",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/IPCC"
        )
        let $seq := $docRoot//method
        for $elem in $seq
        return
            if(
                $elem/methodClassification = $methodClassifications
                and
                functx:if-empty($elem/furtherDetails, "") = ""
            )
            then
                <tr>
                    <td class='warning' title="Details">
                        Not met reporting requirements for the method classification
                    </td>
                    <td title="inspireId">{$elem/ancestor::*[InspireId]/InspireId}</td>
                    <td class="tdwarning" title="furtherDetails"> {fn:data($elem/furtherDetails)} </td>
                    <td title="methodClassifications">{$elem/methodClassification}</td>
                    <td title="Feature type">{$elem/parent::*/local-name()}</td>
                    <td title="Additional info">{$getAdditionalInformation($elem/parent::*)}</td>
                </tr>
            else
                ()
    let $LCP_3_5 := xmlconv:RowBuilder("EPRTR-LCP 3.5",
            "Required furtherDetails for reporting methodClassification", $res)

    (:  C3.6 – transboundaryTransfer completeness   :)
    let $res :=
        let $attributesToVerify := (
            "nameOfReceiver",
            "buildingNumber",
            "city",
            "countryCode",
            "postalCode",
            "streetName"
        )
        let $seq := $docRoot//offsiteWasteTransfer[wasteClassification => functx:substring-after-last("/") = 'HW']
        for $elem in $seq
        for $attr in $attributesToVerify
        for $el in $elem//*[fn:local-name() = $attr]
        return
            if(functx:if-empty($el, "") = "")
            then
                <tr>
                    <td class='info' title="Details"> Attribute should contain a character string</td>
                    <td class="tdinfo" title="Value"> {fn:data($el)} </td>
                    <td title="InspireId">
                        {$el/ancestor::*[fn:local-name()="ProductionFacilityReport"]/InspireId}
                    </td>
                    <td title="Parent feature type"> {$el/parent::*/local-name()} </td>
                    <td title="attribute"> {$attr} </td>
                    <td title="wasteClassification">
                        {$el/ancestor::offsiteWasteTransfer/wasteClassification/data() => functx:substring-after-last("/")}
                    </td>
                    <td title="wasteTreatment">
                        {$el/ancestor::offsiteWasteTransfer/wasteTreatment/data() => functx:substring-after-last("/")}
                    </td>
                </tr>
            else
                ()
    let $LCP_3_6 := xmlconv:RowBuilder("EPRTR-LCP 3.6","transboundaryTransfer completeness", $res)

    let $LCP_3 := xmlconv:RowAggregator(
            "EPRTR-LCP 3",
            "Comprehensive reporting checks",
            (
                $LCP_3_1,
                $LCP_3_2,
                $LCP_3_3,
                $LCP_3_4,
                $LCP_3_5,
                $LCP_3_6
            )
    )

    (:  C4.1 – ReportingYear plausibility   :)
    let $res :=
        let $envelope-url := functx:substring-before-last-match($source_url, '/') || '/xml'
        let $envelope-available := fn:doc-available($envelope-url)
        return
            if(fn:not($envelope-available))
            then
                <tr>
                    <td class="error" title="Details">
                        Could not verify envelope year because envelope XML is not available.
                    </td>
                </tr>
            else
                let $envelopeDoc := fn:doc($envelope-url)
                let $envelopeYear := $envelopeDoc//year
                for $report in $docRoot//ReportData
                let $reportYear := $report/reportingYear
                return
                    if($envelopeYear != $reportYear)
                    then
                        <tr>
                            <td class="error" title="Details">Reporting year is different from envelope year.</td>
                            <td title="envelopeYear">{$envelopeYear}</td>
                            <td class="tderror" title="reportYear">{$reportYear}</td>
                        </tr>
                    else
                        ()

    let $LCP_4_1 := xmlconv:RowBuilder("EPRTR-LCP 4.1","ReportingYear plausibility", $res)

    (:  C4.2 – accidentalPollutantQuantityKg plausibility   :)
    let $res :=
        let $seq := $docRoot//pollutantRelease
        for $elem in $seq
        let $totalPollutantQuantityKg :=
            functx:if-empty($elem/totalPollutantQuantityKg/fn:data(), 0)=>fn:number()
        let $accidentalPollutantQuantityKg :=
            functx:if-empty($elem/accidentalPollutantQuantityKg/fn:data(), 0)=>fn:number()
        let $ok := (
            $totalPollutantQuantityKg >= $accidentalPollutantQuantityKg
            and
            $totalPollutantQuantityKg castable as xs:double
            and
            $accidentalPollutantQuantityKg castable as xs:double
        )
        return
            if(fn:not($ok))
            then
                <tr>
                    <td class='warning' title="Details">accidentalPollutantQuantityKg attribute value is not valid</td>
                    <td class="tdwarning" title="accidentalPollutantQuantityKg"> {$accidentalPollutantQuantityKg} </td>
                    <td title="totalPollutantQuantityKg"> {$totalPollutantQuantityKg} </td>
                    <td title="localId">
                        {$elem/ancestor::*[fn:local-name()="ProductionFacilityReport"]/InspireId/localId}
                    </td>
                    <td title="namespace">
                        {$elem/ancestor::*[fn:local-name()="ProductionFacilityReport"]/InspireId/namespace}
                    </td>
                </tr>
            else
                ()

    let $LCP_4_2 := xmlconv:RowBuilder("EPRTR-LCP 4.2","accidentalPollutantQuantityKg plausibility", $res)

    (: C4.3 – CO2 reporting plausibility :)
    let $res :=
        let $co2 := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CO2"
        let $co2exclBiomass :=
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CO2EXCLBIOMASS"
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $co2_amount :=
                functx:if-empty($elem//pollutantRelease[pollutant = $co2]
                        /totalPollutantQuantityKg/data(), 0) => fn:number()
            let $co2exclBiomass_amount :=
                functx:if-empty($elem//pollutantRelease[pollutant = $co2exclBiomass]
                        /totalPollutantQuantityKg/data(), 0) => fn:number()
            let $ok := (
                $co2_amount >= $co2exclBiomass_amount
                and
                $co2_amount castable as xs:double
                and
                $co2exclBiomass_amount castable as xs:double
            )
        return
            if(fn:not($ok))
                then
                <tr>
                    <td class='warning' title="Details">
                        Reported CO2 excluding biomass exceeds reported CO2 emissions
                    </td>
                    <td class="tdwarning" title="CO2 excluding biomass"> {fn:data($co2exclBiomass_amount)} </td>
                    <td title="CO2"> {fn:data($co2_amount)} </td>
                    <td title="localId">{$elem/InspireId/localId}</td>
                    <td title="namespace">{$elem/InspireId/namespace}</td>
                </tr>
                else
                    ()

    let $LCP_4_3 := xmlconv:RowBuilder("EPRTR-LCP 4.3","CO2 reporting plausibility", $res)

    let $LCP_4 := xmlconv:RowAggregator(
            "EPRTR-LCP 4",
            "Reporting form plausibility checks",
            (
                $LCP_4_1,
                $LCP_4_2,
                $LCP_4_3
            )
    )
    (:let $asd := trace(fn:current-time(), 'started 5 at: '):)
    (:  C.5.1 – Identification of fuelInput duplicates  :)
    let $res :=
        let $fuelInputs := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Biomass",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Coal",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Lignite",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/LiquidFuels",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/NaturalGas",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Peat"
        )
        for $elem in $docRoot//ProductionInstallationPartReport
        let $fuels := $elem/energyInput/fuelInput/fuelInput
        for $fuel in $fuelInputs
        return
            if(fn:count(fn:index-of($fuels, $fuel)) > 1)
            then
                <tr>
                    <td class='error' title="Details">Fuel is duplicated within the EnergyInput feature type</td>
                    <td class="tderror" title="fuelInput"> {functx:substring-after-last($fuel, "/")} </td>
                    <td title="localId">{$elem/descendant-or-self::*/InspireId/localId}</td>
                    <td title="namespace">{$elem/descendant-or-self::*/InspireId/namespace}</td>
                </tr>
            else
                ()
    let $LCP_5_1 := xmlconv:RowBuilder("EPRTR-LCP 5.1","Identification of fuelInput duplicates", $res)

    (:  C.5.2 – Identification of otherSolidFuel duplicates   :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        let $map := map {
            'Other': 'furtherDetails',
            'SpecifiedFuel': 'otherSolidFuel'
        }
        let $fuelInput := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels"
        let $errorType := 'warning'
        let $text := map {
            'Other': 'furtherDetails exceed the similarity threshold',
            'SpecifiedFuel': 'Fuel has been duplicated within the EnergyInput feature type'
        }
        return
            scripts:checkOtherFuelDuplicates(
                $seq,
                $map,
                $errorType,
                $fuelInput,
                $text
            )
    let $LCP_5_2 := xmlconv:RowBuilder("EPRTR-LCP 5.2",
            "Identification of otherSolidFuel duplicates", $res)

    (:  C.5.3 – Identification of otherGaseousFuel duplicates   :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        let $map := map {
            'Other': 'furtherDetails',
            'SpecifiedFuel': 'otherGaseousFuel'
        }
        let $fuelInput := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherGases"
        let $errorType := 'warning'
        let $text := map {
            'Other': 'furtherDetails exceed the similarity threshold',
            'SpecifiedFuel': 'Fuel has been duplicated within the EnergyInput feature type'
        }
        return
            scripts:checkOtherFuelDuplicates(
                $seq,
                $map,
                $errorType,
                $fuelInput,
                $text
            )

    let $LCP_5_3 := xmlconv:RowBuilder("EPRTR-LCP 5.3",
            "Identification of otherGaseousFuel duplicates", $res)

    (:  C5.4 - Identification of EmissionsToAir duplicates  :)
    let $res :=
        (:let $pollutantValues := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/Dust",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOx",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2"
        ):)
        let $pollutantValues :=
            $docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant => fn:distinct-values()

        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
            let $pollutants := $elem/emissionsToAir/pollutant
            for $pollutant in $pollutantValues
                return
                if(fn:count(fn:index-of($pollutants, $pollutant)) > 1)
                then
                    <tr>
                        <td class='error' title="Details">
                            Pollutant is duplicated within the EmissionsToAir feature type
                        </td>
                        <td class="tderror" title="pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
                        <td title="localId">{$elem/descendant-or-self::*/InspireId/localId}</td>
                        <td title="namespace">{$elem/descendant-or-self::*/InspireId/namespace}</td>
                    </tr>
                else
                    ()
    let $LCP_5_4 := xmlconv:RowBuilder("EPRTR-LCP 5.4","Identification of EmissionsToAir duplicates", $res)

    (:  C.5.5 – Identification of PollutantRelease duplicates  :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $values :=
                for $el in $elem/pollutantRelease
                return
                    $el/mediumCode => functx:substring-after-last("/") || ' / '
                    || $el/pollutant => functx:substring-after-last("/")
            for $el in $values => fn:distinct-values()
            return
                if(
                    fn:count(fn:index-of($values, $el)) > 1
                )
                then
                    <tr>
                        <td class='error' title="Details">
                            Pollutant and medium pair is duplicated within the PollutantRelease feature type
                        </td>
                        <td class="tderror" title="mediumCode / pollutant">
                            {$el}
                        </td>
                        <td title="localId">
                            {$elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/InspireId/localId}
                        </td>
                        <td title="namespace">
                            {$elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/InspireId/namespace}
                        </td>
                    </tr>
                else
                    ()
    let $LCP_5_5 := xmlconv:RowBuilder(
            "EPRTR-LCP 5.5","Identification of PollutantRelease duplicates",
            $res
    )

    (:  C.5.6 – Identification of OffsitePollutantTransfer duplicates  :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $not-ok-pollutants := []
            let $allPollutants := $elem/offsitePollutantTransfer/pollutant
            for $el in fn:distinct-values($elem/offsitePollutantTransfer/pollutant)
            let $ok := fn:count(fn:index-of($allPollutants, $el)) = 1
            return
                if(fn:not($ok))
                    then
                        <tr>
                            <td class='error' title="Details">
                                Pollutant is duplicated within the OffsitePollutantTransfer feature type
                            </td>
                            <td class="tderror" title="pollutant"> {functx:substring-after-last($el, "/")} </td>
                            <td title="localId">{$elem/descendant-or-self::*/InspireId/localId}</td>
                            <td title="namespace">{$elem/descendant-or-self::*/InspireId/namespace}</td>
                        </tr>
                    else
                        ()

    let $LCP_5_6 := xmlconv:RowBuilder("EPRTR-LCP 5.6","Identification of OffsitePollutantTransfer duplicates", $res)

    (:  C.5.7 – Identification of month duplicates  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
            let $allMonths := $elem/desulphurisationInformation/month
            for $el in fn:distinct-values($elem/desulphurisationInformation/month)
            let $ok := fn:count(index-of($allMonths, $el)) = 1
            return
                if(fn:not($ok))
                    then
                        <tr>
                            <td class='warning' title="Details">
                                Month is duplicated within the DesulphurisationInformationType feature type
                            </td>
                            <td class="tdwarning" title="Month"> {functx:substring-after-last($el, "/")} </td>
                            <td title="localId">{$elem/descendant-or-self::*/InspireId/localId}</td>
                            <td title="namespace">{$elem/descendant-or-self::*/InspireId/namespace}</td>
                        </tr>
                    else
                        ()
    let $LCP_5_7 := xmlconv:RowBuilder("EPRTR-LCP 5.7","Identification of month duplicates", $res)

    let $LCP_5 := xmlconv:RowAggregator(
            "EPRTR-LCP 5",
            "Duplicate identification checks",
            (
                $LCP_5_1,
                $LCP_5_2,
                $LCP_5_3,
                $LCP_5_4,
                $LCP_5_5,
                $LCP_5_6,
                $LCP_5_7
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 6 at: '):)
    (: TODO not final version :)
    (:  C6.1 – Individual EmissionsToAir feasibility    :)
    let $res :=
        let $getParentFacilityQuantity := function (
            $namespace as xs:string,
            $localId as xs:string,
            $mediumCode as xs:string,
            $pollutant as xs:string
        ) as xs:double {
        $docRoot//ProductionFacilityReport[InspireId/namespace = $namespace
            and InspireId/localId = $localId]/pollutantRelease[mediumCode = $mediumCode
                    and pollutant=>fn:lower-case()=>functx:substring-after-last("/") = $pollutant]
                        /totalPollutantQuantityKg=> functx:if-empty(0) => fn:number()
        }

        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'warning'
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $text := 'Reported EmissionsToAir is inconsistent with the PollutantRelease
            reported to air for the parent ProductionFacility'
        for $part in $seq
            let $parentFacilityInspireId := $docProductionInstallationParts//ProductionInstallationPart
                [year = $previous-year and InspireId/data() = $part/InspireId/data()]
                    /parentFacilityInspireId
            let $namespace := $parentFacilityInspireId/namespace => functx:if-empty('Not found')
            let $localId := $parentFacilityInspireId/localId => functx:if-empty('Not found')

            for $emission in $part/emissionsToAir
                let $pol := $emission/pollutant => functx:substring-after-last("/")
                let $pollutant :=
                    if($pol = 'DUST')
                    then 'pm10'
                    else if($pol = 'SO2')
                    then 'sox'
                    else 'nox'
                let $pollutantQuantityKg :=
                    $emission/totalPollutantQuantityTNE => functx:if-empty(0) => fn:number() * 1000

                let $parentFacilityQuantityKg :=
                    $getParentFacilityQuantity($namespace, $localId, $mediumCode, $pollutant)

                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $part/InspireId},
                    'Pollutant': map {'pos': 3, 'text': $pol},
                    'Pollutant quantity (in Kg)':
                        map {'pos': 4, 'text': $pollutantQuantityKg => xs:decimal()=> fn:round-half-to-even(2)
                            , 'errorClass': 'td' || $errorType},
                    'Parent facility pollutant quantity (in Kg)':
                        map {'pos': 5, 'text': $parentFacilityQuantityKg => xs:decimal() => fn:round-half-to-even(2)}
                }
                let $ok :=
                    if($pol = 'DUST')
                    then $pollutantQuantityKg <= $parentFacilityQuantityKg div 2
                    else $pollutantQuantityKg <= $parentFacilityQuantityKg
                return
                    (:if(false()):)
                    if(not($ok))
                    (:if(true()):)
                    then scripts:generateResultTableRow($dataMap)
                    else ()
    let $LCP_6_1 := xmlconv:RowBuilder("EPRTR-LCP 6.1","Individual EmissionsToAir feasibility", $res)

    (: TODO not final version :)
    (: C6.2 – Cumulative EmissionsToAir feasibility :)
    let $res :=
        let $getTotalPartsQuantity := function (
            $partsInspireIds as xs:string+,
            $pollutant as xs:string
        ) as xs:double{
            $docRoot//ProductionInstallationPartReport[InspireId = $partsInspireIds]
                    /emissionsToAir[pollutant=>functx:substring-after-last("/") = $pollutant]
                        /functx:if-empty(totalPollutantQuantityTNE, 0) => sum()
        }

        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Cumulative EmissionsToAir for all ProductionInstallationParts under the parent ProductionFacility
            exceed the PollutantRelease value for the specified pollutant.'
        let $emissions := ('SO2', 'NOX', 'DUST')
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        for $facility in $seq
            let $partsInspireIds := $docProductionInstallationParts//ProductionInstallationPart
                [parentFacilityInspireId = $facility/InspireId]/InspireId

            for $pol in $emissions
                let $pollutant :=
                    if($pol = 'DUST')
                    then 'pm10'
                    else if($pol = 'SO2')
                    then 'sox'
                    else 'nox'
                let $facilityQuantityKg := $facility/pollutantRelease[mediumCode = $mediumCode
                    and pollutant=>fn:lower-case()=>functx:substring-after-last("/") = $pollutant]
                        /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()

                let $totalPartsQuantityKg :=
                    $getTotalPartsQuantity($partsInspireIds, $pol) * 1000

                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Pollutant': map {'pos': 3, 'text': $pol},
                    'Parts pollutant quantity (in Kg)':
                        map {'pos': 4, 'text': $totalPartsQuantityKg => xs:decimal()=> fn:round-half-to-even(2)
                            , 'errorClass': 'td' || $errorType},
                    'Facility pollutant quantity (in Kg)':
                        map {'pos': 5, 'text': $facilityQuantityKg => xs:decimal() => fn:round-half-to-even(2)}
                }
                let $ok :=
                    if($pol = 'DUST')
                    then $totalPartsQuantityKg <= $facilityQuantityKg div 2
                    else $totalPartsQuantityKg <= $facilityQuantityKg

                return
                    (:if(true()):)
                    (:if(false()):)
                    if(not($ok))
                    then scripts:generateResultTableRow($dataMap)
                    else ()
    let $LCP_6_2 := xmlconv:RowBuilder("EPRTR-LCP 6.2","Cumulative EmissionsToAir feasibility", $res)

    let $LCP_6 := xmlconv:RowAggregator(
            "EPRTR-LCP 6",
            "LCP and E-PRTR facility interrelation checks",
            (
                $LCP_6_1,
                $LCP_6_2
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 7 at: '):)
    (: TODO needs more testing :)
    (:  C7.1 – EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility     :)
    let $res :=
        let $getTotalRatedThermalInput := function(
            $inspireId as xs:string
        ) as xs:double {
            123
        }
        let $getParentFacilityNrOfOperatingHours := function(
        ) as xs:double {
            6789
        }

        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'warning'
        let $text := map {
            1: 'are above the reported numberOfOperatingHours by more than 10%',
            2: 'exceed 8784 hours',
            3: 'exceed the reported numberOfOperatingHours for the associated parent ProductionFacility'
        }
        for $part in $seq
            let $aggregatedEnergyInputMW
                := $part/energyInput/energyinputTJ/functx:if-empty(text(), 0) => sum() * 0.0317
            let $totalRatedThermalInput := $getTotalRatedThermalInput($part/InspireId/data())
            let $proportionOfFuelCapacityBurned := $aggregatedEnergyInputMW div $totalRatedThermalInput
            let $calculatedOperatingHours := $proportionOfFuelCapacityBurned * 8784
            let $nrOfOperatingHours := $part/numberOfOperatingHours => functx:if-empty(0) => fn:number()
            let $parentFacilityNrOfOperatingHours := $getParentFacilityNrOfOperatingHours()

            let $errors :=
                if($calculatedOperatingHours gt ($nrOfOperatingHours * 110) div 100)
                then 1
                else if($calculatedOperatingHours > 8784)
                then 2
                else if($calculatedOperatingHours > $parentFacilityNrOfOperatingHours)
                then 3
                else 0
            let $dataMap := map {
                'Details':
                    map {'pos': 1, 'text': 'Calculated operating hours ' || $text?($errors), 'errorClass': $errorType},
                'InspireId': map {'pos': 2, 'text': $part/InspireId},
                'Calculated operating hours':
                    map {'pos': 3, 'text': $calculatedOperatingHours => round-half-to-even(2), 'errorClass': 'td' || $errorType},
                'Number of operating hours': map {'pos': 4, 'text': $nrOfOperatingHours},
                'Parent facility number of operating hours': map {'pos': 4, 'text': $parentFacilityNrOfOperatingHours}
            }
            return
                (:if($errors > 0):)
                if(false())
                then scripts:generateResultTableRow($dataMap)
                else ()

    let $LCP_7_1 := xmlconv:RowBuilder("EPRTR-LCP 7.1",
            "EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility (Partially IMPLEMENTED)", $res)

    (: C7.2 – MethodClassification validity :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
                /*[fn:local-name() = ("offsitePollutantTransfer", "pollutantRelease")]/method/methodClassification
        for $elem in $seq
            return
                if($elem = "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/WEIGH")
                then
                    <tr>
                        <td class='info' title="Details">Attribute is incorrectly populated with WEIGH</td>
                        <td class="tdinfo" title="feature type"> {fn:node-name($elem/../..)} </td>
                        <td class="tdinfo" title="methodClassification"> {$elem} </td>
                        <td title="localId">{
                            $elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/InspireId/localId}
                        </td>
                        <td title="namespace">
                            {$elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/InspireId/namespace}
                        </td>
                    </tr>
                else
                    ()
    let $LCP_7_2 := xmlconv:RowBuilder("EPRTR-LCP 7.2","MethodClassification validity", $res)

    let $LCP_7 := xmlconv:RowAggregator(
            "EPRTR-LCP 7",
            "Thematic validity checks",
            (
                $LCP_7_1,
                $LCP_7_2
            )
    )

    let $getDerogation := function (
        $inspireId as xs:string
    ) as xs:string {
        let $derogation := $docProductionInstallationParts//ProductionInstallationPart[year = $previous-year
            and InspireId = $inspireId]/derogations => functx:substring-after-last("/")
        return $derogation
    }

    (:let $asd := trace(fn:current-time(), 'started 8 at: '):)
    (: TODO needs more testing :)
    (:   C8.1 – Article 31 derogation compliance   :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'info'
        let $text := 'Installation part has not met the specifications for reporting an Article 31 derogation'
        let $errorMap := map {
            1: 'At least one of the reported fuelInputs must reflect an indigenous solid fuel type',
            2: 'The desulphurisationInformation data type must be populated'
        }
        let $solidFuelTypes := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Coal",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Biomass",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Lignite",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/Peat"
        )
        for $part in $seq
            (: TODO inspireid = localid/namespace , maybe we need to include namespace too :)
            let $derogation := $getDerogation($part/InspireId/localId/data())
            let $fuelInputs := $part/energyInput/fuelInput/fuelInput/text()
            let $errorNr :=
                if($derogation != 'Article31')
                then 0
                else if(functx:value-intersect($solidFuelTypes, $fuelInputs)=>fn:count() = 0)
                    then 1
                else if($part/desulphurisationInformation/data()=>fn:string-join()=>fn:string-length() = 0)
                    then 2
                else 0

            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'InspireId': map {'pos': 2, 'text': $part/InspireId},
                'Additional info': map {'pos': 3, 'text': $errorMap?($errorNr), 'errorClass': 'td' || $errorType}
            }
            return
                if($errorNr > 0)
                (:if(false()):)
                (:if(true()):)
                then scripts:generateResultTableRow($dataMap)
                else ()
    let $LCP_8_1 := xmlconv:RowBuilder("EPRTR-LCP 8.1","Article 31 derogation compliance", $res)

    (: TODO needs more testing :)
    (:  C8.2 – Article 31 derogation justification  :)
    let $res :=
        let $isDerogationFirstYear := function (
            $inspireId as xs:string
        ) as xs:boolean {
            true()
        }
        let $isTechnicalJustificationOK := function (
            $part as element()
        ) as xs:boolean {
            $part/desulphurisationInformation[technicalJustification=>string-length() > 0]=> count() > 0
            and
            $part/desulphurisationInformation[technicalJustification=>string-length() = 0]=> count() = 0
        }
        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'warning'
        let $text := 'Technical justification has been omitted for the Installation part'
        for $part in $seq
            let $ok := if($isDerogationFirstYear($part/InspireId/data()))
                then $isTechnicalJustificationOK($part)
                else true()
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'InspireId': map {'pos': 2, 'text': $part/InspireId, 'errorClass': 'td' || $errorType}
            }
            return
                (:if(not($ok)):)
                if(false())
                then scripts:generateResultTableRow($dataMap)
                else ()

    let $LCP_8_2 := xmlconv:RowBuilder("EPRTR-LCP 8.2","Article 31 derogation justification (partially IMPLEMENTED)", $res)

    (: TODO not final version :)
    (:  C8.3 – Article 35 derogation and proportionOfUsefulHeatProductionForDistrictHeating comparison  :)
    let $res :=
        let $inspireIdsNedded := $docProductionInstallationParts//ProductionInstallationPart
            [year = $previous-year and derogations=>functx:substring-after-last("/") = 'Article35']
                /InspireId/data()
        let $seq := $docRoot//ProductionInstallationPartReport[InspireId/localId = $inspireIdsNedded]
        let $errorType := 'info'
        let $text := 'Proportion of useful heat production for district heating has been omitted or reported below 50%'
        for $part in $seq
            let $proportion :=
                $part/proportionOfUsefulHeatProductionForDistrictHeating => functx:if-empty(0) => fn:number()
            let $ok := $proportion >= 50
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'InspireId': map {'pos': 2, 'text': $part/InspireId},
                'Proportion of useful heat production for district heating':
                    map {'pos': 3, 'text': $proportion || '%', 'errorClass': 'td' || $errorType}
            }
            return
                if(not($ok))
                (:if(false()):)
                then scripts:generateResultTableRow($dataMap)
                else ()


    let $LCP_8_3 := xmlconv:RowBuilder("EPRTR-LCP 8.3",
            "Article 35 derogation and proportionOfUsefulHeatProductionForDistrictHeating comparison",
            $res
    )

    let $LCP_8 := xmlconv:RowAggregator(
            "EPRTR-LCP 8",
            "Derogation checks",
            (
                $LCP_8_1,
                $LCP_8_2,
                $LCP_8_3
            )
    )

    (:  C9.1 – Confidentiality overuse  :)
    let $res :=
        let $featureTypes := (
            "ProductionInstallationPartReport",
            "emissionsToAir",
            "energyInput",
            "ProductionFacilityReport",
            "offsiteWasteTransfer",
            "offsitePollutantTransfer",
            "pollutantRelease"
        )
        let $seq := $docRoot/descendant::*[fn:local-name() = $featureTypes]
        let $countConfidentialityReasons :=
            for $elem in $seq/child::*[fn:local-name() = "confidentialityReason"]
            return if($elem/text() != "") then $elem else ()
        let $ratio := fn:count($countConfidentialityReasons) div fn:count($seq)
        let $errorType :=
            if($ratio > 0.01)
            then "warning"
            else "info"
        let $errorMessage :=
            if($ratio > 0.01)
            then
                "confidentialityReason attribute exceeded the 1% threshold"
            else if($ratio > 0.005)
                then
                "confidentialityReason attribute exceeded the 0.5% threshold, but the percentage is less than 1%"
            else "all good"
        return
            if($ratio > 0.005)
            then
                for $confidentialityReason in $docRoot//confidentialityReason[fn:string-length() > 0]
                let $dataMap := map {
                    'Details': map {'pos': 1,'text': $errorMessage, 'errorClass': $errorType},
                    'confidentialityReason': map {
                        'pos': 2, 'text': $confidentialityReason, 'errorClass': 'td' || $errorType
                    },
                    'InspireId': map {'pos': 3, 'text': $confidentialityReason/ancestor::*[InspireId]/InspireId},
                    'Path': map {'pos': 4, 'text': $confidentialityReason => functx:path-to-node()}
                }
                return
                    scripts:generateResultTableRow($dataMap)
                (:<tr>
                    <td class='{$errorType}' title="Details">{$errorMessage}</td>
                    <td class="td{$errorType}" title="threshold"> {fn:round-half-to-even($ratio * 100, 1) || '%'} </td>
                </tr>:)
            else
                ()
    let $LCP_9_1 := xmlconv:RowBuilder("EPRTR-LCP 9.1","Confidentiality overuse", $res)

    let $LCP_9 := xmlconv:RowAggregator(
            "EPRTR-LCP 9",
            "Confidentiality checks",
            (
                $LCP_9_1
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 10 at: '):)
    (:  C10.1 – EmissionsToAir outlier identification   :)
    let $res :=
        let $seq:= $docRoot//ProductionInstallationPartReport
        let $emissions := fn:distinct-values($seq/emissionsToAir/pollutant)
        for $elem in $seq
            for $emission in $emissions
                let $emissionTotal :=
                    $elem/emissionsToAir[pollutant = $emission]/
                        functx:if-empty(totalPollutantQuantityTNE, 0) => fn:sum()
                let $expected := fn:sum(
                    for $pollutant in $elem/energyInput
                    let $emissionFactor :=
                        $docEmissions//row[$pollutant/fuelInput/fuelInput = fuelInput][1]
                                /*[fn:local-name() = functx:substring-after-last($emission, "/")]
                    return $pollutant/energyinputTJ * $emissionFactor
                )
                let $emissionConstant := if($emission = "NOX") then 1 div 10 else 1 div 100
                (:where $expected > 0:)
                return
                    if(
                        $emissionTotal div $expected > 20
                        or
                        $emissionTotal div $expected < $emissionConstant
                    )
                    (:if(true()):)
                    then
                        <tr>
                            <td class="info" title="Details">Reported emissions deviate from expected quantities</td>
                            <td title="inspireId">{$elem/InspireId}</td>
                            <td title="fuelInput">{$emission => functx:substring-after-last("/")}</td>
                            <td class="tdinfo" title="total reported">{$emissionTotal => xs:long()}</td>
                            <td title="expected">{$expected => xs:long()}</td>
                        </tr>
                    else
                        ()
    let $LCP_10_1 := xmlconv:RowBuilder("EPRTR-LCP 10.1","EmissionsToAir outlier identification", $res)

    (:let $asd := trace(fn:current-time(), 'started 10.2 at: '):)
    (: TODO not final version :)
    (:  C10.2 – Energy input and CO2 emissions feasibility  :)
    let $res :=
        let $getAggregatedPartsCO2 := function (
            $inspireId as element()
        ) as xs:double {
            (: 000000001.FACILITY
            1200 * 94.6 + 8 * 44.4 + 8 * 44.4 + 150 * 107 + 150 * 107 + 300 * 97.5 + 300 * 97.5
            204830.4
            :)
            let $partsInspireIds :=
                $docProductionInstallationParts//ProductionInstallationPart[year = $previous-year
                    and parentFacilityInspireId = $inspireId/localId/data()]
                    /InspireId
            let $result :=
            for $emission in $docRoot//ProductionInstallationPartReport[InspireId/localId = $partsInspireIds]
                    /energyInput
                let $energyinput := $emission/energyinputTJ => functx:if-empty(0) => fn:number()
                let $fuelInput :=
                    let $fuel := $emission/fuelInput/fuelInput/data()
                    return
                    if($fuel => functx:substring-after-last("/") = 'OtherSolidFuels')
                    then $emission/fuelInput/otherSolidFuel/data()
                    else if($fuel => functx:substring-after-last("/") = 'OtherGases')
                    then $emission/fuelInput/otherGaseousFuel/data()
                    else $fuel

                let $emissionFactor :=
                    $docEmissions//row[EF_LOOKUP = $fuelInput]/CO2 => functx:if-empty(0) => fn:number()
                return $energyinput * $emissionFactor

            return $result => fn:sum()
        }

        let $pollutant := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CO2'
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'CO2 emissions deviate from expected emissions given the fuel inputs
            reported for associated LCP InstallationParts'
        for $facility in $seq
            let $reportedCO2 := $facility/pollutantRelease[pollutant = $pollutant and mediumCode = $mediumCode]
                /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            let $aggregatedPartsCO2 := $getAggregatedPartsCO2($facility/InspireId)
            let $percentage := if($reportedCO2 >= $aggregatedPartsCO2 or $reportedCO2 = 0)
                then ($reportedCO2 div $aggregatedPartsCO2) * 100 - 100
                else ($aggregatedPartsCO2 div $reportedCO2) * 100 - 100
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                'Deviation percentage': map {
                    'pos': 3,
                    'text': $percentage (:=> xs:decimal() => fn:round-half-to-even(2):) || '%',
                    'errorClass': 'td' || $errorType
                },
                'Facility reported CO2 amount': map {
                    'pos': 4,
                    'text': $reportedCO2 => xs:decimal() => fn:round-half-to-even(2)
                },
                'Installation part aggregated CO2 amount':
                    map {'pos': 5, 'text': $aggregatedPartsCO2 => xs:decimal() => fn:round-half-to-even(2)}
            }
            let $ok := if($reportedCO2 > $aggregatedPartsCO2)
                then ($reportedCO2 div $aggregatedPartsCO2) * 100 - 100 < 100
                else ($aggregatedPartsCO2 div $reportedCO2) * 100 - 100 < 30
            return
                if(fn:not($ok))
                (:if(fn:false()):)
                (:if($reportedCO2 > 0):)
                then
                    scripts:generateResultTableRow($dataMap)
                else()
    let $LCP_10_2 := xmlconv:RowBuilder("EPRTR-LCP 10.2",
            "Energy input and CO2 emissions feasibility", $res)

    (:let $asd := trace(fn:current-time(), 'started 10.3 at: '):)
    (: TODO not final version :)
    (:  C10.3 – ProductionFacility cross pollutant identification   :)
    let $res :=
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'

        let $getPollutantValue := function (
            $facility as element(),
            $sourcePollutant as xs:string
        ) as xs:double {
            let $codeListValue := scripts:getCodelistvalue($sourcePollutant, $docPollutantLookup)
            return $facility/pollutantRelease[mediumCode = $mediumCode and pollutant = $codeListValue][1]
                /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
        }

        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := map {
            1: 'Resultant pollutant emissions to air is missing',
            2: 'Resultant pollutant is low/high based on comparison with expected ranges'
        }

        for $facility in $seq
            let $EPRTRAnnexIActivity := scripts:getEPRTRAnnexIActivity(
                    $facility/InspireId/localId,
                    $previous-year,
                    $docProductionFacilities
            )
            for $row in $docCrossPollutants//row[AnnexIActivityCode => replace('\.', '') = $EPRTRAnnexIActivity]
                let $reportingThreshold := $row/ReportingThreshold => fn:number()
                let $sourcePollutantValue := $getPollutantValue($facility, $row/SourcePollutant)
                let $resultingPollutantValue := $getPollutantValue($facility, $row/ResultingPollutant)
                let $minExpectedEmission :=
                    ($sourcePollutantValue * $row/MinFactor => functx:if-empty(0)) => fn:number()
                let $maxExpectedEmission :=
                    ($sourcePollutantValue * $row/MaxFactor => functx:if-empty(0)) => fn:number()
                let $distanceMin := ($resultingPollutantValue - $minExpectedEmission) => fn:abs()
                let $distanceMax := ($resultingPollutantValue - $maxExpectedEmission) => fn:abs()
                let $expectedEmissionFactorMin := $distanceMin div $reportingThreshold
                let $expectedEmissionFactorMax := $distanceMax div $reportingThreshold

(:
                let $tracer :=
                if($resultingPollutantValue > 0)
                then
                    let $asd := trace($row/SourcePollutant/text(), "Source pollutant: ")
                    let $asd := trace($sourcePollutantValue => xs:decimal() => fn:round-half-to-even(2), "Source pollutant amount: ")
                    let $asd := trace($row/ResultingPollutant/text(), "Resulting pollutant: ")
                    let $asd := trace($resultingPollutantValue => xs:decimal() => fn:round-half-to-even(2), "Resulting pollutant amount: ")
                    let $asd := trace($minExpectedEmission => xs:decimal() => fn:round-half-to-even(2), "minExpectedEmission: ")
                    let $asd := trace($maxExpectedEmission => xs:decimal() => fn:round-half-to-even(2), "maxExpectedEmission: ")
                    let $asd := trace($distanceMin => xs:decimal() => fn:round-half-to-even(2), "distanceMin: ")
                    let $asd := trace($distanceMax => xs:decimal() => fn:round-half-to-even(2), "distanceMax: ")
                    let $asd := trace($expectedEmissionFactorMin => xs:decimal() => fn:round-half-to-even(2), "expectedEmissionFactorMin: ")
                    let $asd := trace($expectedEmissionFactorMax => xs:decimal() => fn:round-half-to-even(2), "expectedEmissionFactorMax: ")
                    return 0
                else 0
:)

                let $priority :=
                    if($expectedEmissionFactorMax <= 2)
                    then 'low'
                    else if($expectedEmissionFactorMax > 2 and $expectedEmissionFactorMax < 10)
                    then 'medium'
                    else 'high'
                let $additionalComment := 'The priority of the failure of this check has been classified as
                    '|| $priority ||' based on the expected emissions factor.'

                let $errorNR := if($resultingPollutantValue = 0)
                    then 1
                    else 2

                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text?($errorNR), 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Source pollutant': map {'pos': 3, 'text': $row/SourcePollutant/text()},
                    'Source pollutant amount': map {
                        'pos': 4,
                        'text': $sourcePollutantValue => xs:decimal() => fn:round-half-to-even(2)
                    },
                    'Resulting pollutant': map {'pos': 5, 'text': $row/ResultingPollutant/text()},
                    'Resulting pollutant amount': map {
                        'pos': 6,
                        'text': $resultingPollutantValue => xs:decimal() => fn:round-half-to-even(2),
                        'errorClass': 'td' || $errorType
                    },
                    'Minimum expected emission':
                        map {'pos': 7, 'text': $minExpectedEmission => xs:decimal() => fn:round-half-to-even(2)},
                    'Maximum expected emission':
                        map {'pos': 8, 'text': $maxExpectedEmission => xs:decimal() => fn:round-half-to-even(2)},
                    'Priority': map {'pos': 9, 'text': $additionalComment}
                }
                let $ok := (
                    $maxExpectedEmission < $reportingThreshold
                    or
                    (
                        $resultingPollutantValue > $minExpectedEmission
                        and
                        $resultingPollutantValue > $maxExpectedEmission
                    )
                )
                return
                    if(fn:not($ok))
                    (:if(fn:true()):)
                    (:if($resultingPollutantValue > 0):)
                    (:if($reportValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()
    let $LCP_10_3 := xmlconv:RowBuilder("EPRTR-LCP 10.3",
            "ProductionFacility cross pollutant identification", $res)

    let $LCP_10 := xmlconv:RowAggregator(
            "EPRTR-LCP 10",
            "Expected pollutant identification",
            (
                $LCP_10_1,
                $LCP_10_2,
                $LCP_10_3
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 11 at: '):)
    (:  C11.1 - ProductionFacilityReports without transfers or releases :)
    let $res :=
        let $attributes := (
            "offsiteWasteTransfer",
            "offsitePollutantTransfer",
            "pollutantRelease"
        )
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
        let $elems := $elem/*[fn:local-name() = $attributes]
        return
            if(fn:empty($elems))
            then
                <tr>
                    <td class='info' title="Details">
                        No releases/transfers of pollutants nor transfers of waste have been reported
                    </td>
                    <td class="tdinfo" title="localId">
                        {$elem/ancestor-or-self::*[fn:local-name() = ("ProductionFacilityReport")]/InspireId/localId}
                    </td>
                    <td class="tdinfo" title="namespace">
                        {$elem/ancestor-or-self::*[fn:local-name() = ("ProductionFacilityReport")]/InspireId/namespace}
                    </td>
                </tr>
            else
                ()
    let $LCP_11_1 := xmlconv:RowBuilder("EPRTR-LCP 11.1",
            "ProductionFacilityReports without transfers or releases", $res)

    let $getCodes := function (
        $pollutantNode as element()
    ) as xs:string {
        let $nodeName := $pollutantNode/local-name()
        return
        if($nodeName = 'pollutantRelease')
        then ' - ' || scripts:getPollutantCode($pollutantNode/pollutant, $docPollutantLookup)
            || ' / ' || $pollutantNode/mediumCode => functx:substring-after-last("/")
        else if($nodeName = 'offsiteWasteTransfer')
        then ' - ' || $pollutantNode/wasteClassification => functx:substring-after-last("/")
            (:|| ' / ' || $pollutantNode/wasteTreatment => functx:substring-after-last("/"):)
        else ' - ' || scripts:getPollutantCode($pollutantNode/pollutant, $docPollutantLookup)
    }

    let $getThresholdPollutantRelease := function (
        $pollutantNode as element()
    ) as xs:double {
        let $mediumCode := $pollutantNode/mediumCode => functx:substring-after-last("/")
        let $mediumMap := map {
            'AIR': 'toAir',
            'WATER': 'toWater',
            'LAND': 'toLand'
        }
        let $threshold := $docANNEXII//row[Codelistvalue
                = $pollutantNode/pollutant=>scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                    /*[local-name() = $mediumMap?($mediumCode)]
        return if($threshold = 'NA')
            then -1
            else $threshold => functx:if-empty(0) => fn:number()
    }

    let $getThresholdOffsitePollutantTransfer := function (
        $pollutantNode as element()
    ) as xs:double {
        let $threshold := $docANNEXII//row[Codelistvalue
                = $pollutantNode/pollutant=>scripts:getCodelistvalueForOldCode($docPollutantLookup)]/toWater
        return if($threshold = 'NA')
            then -1
            else $threshold => functx:if-empty(0) => fn:number()
    }

    let $getThresholdOffsiteWasteTransfer := function (
        $pollutantNode as element()
    ) as xs:double {
        let $wasteClassification := $pollutantNode/wasteClassification => functx:substring-after-last("/")
        let $threshold :=
            if($wasteClassification = 'HW')
            then 2
            else 2000
        return $threshold
    }
    (: TODO not final version :)
    (:  C11.2 - ProductionFacility releases and transfers reported below the thresholds :)
    let $res :=
        let $map := map {
            "pollutantRelease": map {
                'getFunction': $getThresholdPollutantRelease,
                'nodeNameQuantity': 'totalPollutantQuantityKg'
                } ,
            "offsitePollutantTransfer": map {
                'getFunction': $getThresholdOffsitePollutantTransfer,
                'nodeNameQuantity': 'totalPollutantQuantityKg'
            },
            "offsiteWasteTransfer": map {
                'getFunction': $getThresholdOffsiteWasteTransfer,
                'nodeNameQuantity': 'totalWasteQuantityTNE'
            }
        }

        let $seq := $docRoot//*[local-name() = map:keys($map)]
        let $errorType := 'info'
        let $text := 'Amount reported is below the threshold value'

        for $pollutantNode in $seq
            let $pollutantType := $pollutantNode/local-name()
            let $reportedAmount := $pollutantNode/*[local-name() = $map?($pollutantType)?nodeNameQuantity]
            let $thresholdValue := $map?($pollutantType)?getFunction($pollutantNode)
            let $dataMap := map {
                'Details' : map {'pos' : 1, 'text' : $text, 'errorClass' : $errorType},
                'InspireId' : map {'pos' : 2, 'text' : $pollutantNode/ancestor::*/InspireId/data()},
                'Type' : map {'pos' : 3, 'text' : $pollutantType || $getCodes($pollutantNode)},
                'Reported amount':
                    map {'pos' : 4, 'text' : $reportedAmount => xs:decimal(), 'errorClass': 'td' || $errorType},
                'Threshold value': map {'pos' : 5, 'text' : $thresholdValue => xs:decimal()}
            }
            let $ok := (
                $reportedAmount >= $thresholdValue
                or $thresholdValue = -1
            )
            return
                if(not($ok))
                (:if(true()):)
                then scripts:generateResultTableRow($dataMap)
                else ()

    let $LCP_11_2 := xmlconv:RowBuilder("EPRTR-LCP 11.2",
            "ProductionFacility releases and transfers reported below the thresholds", $res)

    let $LCP_11 := xmlconv:RowAggregator(
            "EPRTR-LCP 11",
            "ProductionFacility voluntary reporting checks",
            (
                $LCP_11_1,
                $LCP_11_2
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 12 at: '):)
    (: TODO not final version :)
    (: C12.1 - Identification of ProductionFacility release/transfer outliers
        against previous year data at the national level :)
    let $res :=
        let $getCode1 := function (
                $pollutantNode as element(),
                $nodeName as xs:string
            ) as xs:string? {
                if($pollutantNode/local-name() = 'offsiteWasteTransfer')
                then
                    let $code1 := $pollutantNode/*[local-name() = $nodeName]/data() => functx:substring-after-last("/")
                    let $transboundaryTransfer := $pollutantNode/transboundaryTransfer/data()
                    return
                        if($code1 = 'NONHW')
                        then 'NONHW'
                        else if (fn:string-length($transboundaryTransfer) > 0)
                            then $code1 || 'OC'
                            else $code1 || 'IC'

                else
                    scripts:getPollutantCode($pollutantNode/*[local-name() = $nodeName]/text(), $docPollutantLookup)
            }
        let $getCode2 := function (
                $pollutantNode as element(),
                $nodeName as xs:string
            ) as xs:string {
                $pollutantNode/*[local-name() = $nodeName]/data() => functx:substring-after-last("/")
                    => functx:if-empty("")
            }

        let $getLookupHighestValue := function (
                $map as map(*),
                $pollutant,
                $activity,
                $code1,
                $code2
            ) as xs:double {
            let $value :=
                if($pollutant = 'pollutantRelease')
                then $map?doc//row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity and PollutantCode = $code1
                        and ReleaseMediumCode = $code2]
                            /SumOfTotalQuantity
                else if($pollutant = 'offsitePollutantTransfer')
                then $map?doc//row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity and PollutantCode = $code1]
                        /SumOfQuantity
                else $map?doc//row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity and WasteTypeCode = $code1
                        and WasteTreatmentCode = $code2]
                            /SumOfQuantity
            return $value => functx:if-empty(0) => fn:number()
            }
        let $map := map {
            "pollutantRelease": map {
                'doc': $docNATIONAL_TOTAL_ANNEXI_PollutantRelease,
                'filters': map {
                    'code1': 'pollutant', (: pollutantCode :)
                    'code2': 'mediumCode' (: mediumCode :)
                },
                'lookupNodeName': 'SumOfTotalQuantity',
                'reportNodeName': 'totalPollutantQuantityKg'
            } ,
            "offsitePollutantTransfer": map {
                'doc': $docNATIONAL_TOTAL_ANNEXI_PollutantTransfer,
                'filters': map {
                    'code1': 'pollutant', (: pollutantCode :)
                    'code2': ''
                },
                'lookupNodeName': 'SumOfQuantity',
                'reportNodeName': 'totalPollutantQuantityKg'
            },
            "offsiteWasteTransfer": map {
                'doc': $docNATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer,
                'filters': map {
                    'code1': 'wasteClassification', (: wasteClassification :)
                    'code2': 'wasteTreatment' (: wasteTreatment :)
                },
                'lookupNodeName': 'SumOfQuantity',
                'reportNodeName': 'totalWasteQuantityTNE'
            }
        }
        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Reported value exceeded parameter value'
        for $facility in $seq
            let $EPRTRAnnexIActivity := scripts:getEPRTRAnnexIActivity(
                    $facility/InspireId/localId,
                    $previous-year,
                    $docProductionFacilities
            )
            for $pollutantNode in $facility/*[local-name() = map:keys($map)]
                let $pollutant := $pollutantNode/local-name()
                let $code1 :=
                    $getCode1(
                            $pollutantNode,
                            $map?($pollutant)?filters?code1
                    )
                let $code2 :=
                    $getCode2(
                            $pollutantNode,
                            $map?($pollutant)?filters?code2
                    )
                let $reportValue := $pollutantNode/*[local-name() = $map?($pollutant)?reportNodeName]
                        /data() => functx:if-empty(0) => fn:number()
                let $lookupHighestValue :=
                    $getLookupHighestValue(
                        $map?($pollutant),
                        $pollutant,
                        $EPRTRAnnexIActivity,
                        $code1,
                        $code2
                    )
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Annex I activity': map {'pos': 3, 'text': $EPRTRAnnexIActivity},
                    'Type': map {'pos': 4,
                        'text': $pollutant || ' - ' || $code1 || (if($code2 = '') then '' else ' / ' || $code2)
                    },
                    'Reported value': map {'pos': 5,
                        'text': $reportValue => xs:decimal(), 'errorClass': 'td' || $errorType
                    },
                    'Parameter value': map {'pos': 6,
                        'text': $lookupHighestValue => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                let $ok := (
                    $reportValue < 4 * $lookupHighestValue
                    or
                    $lookupHighestValue = 0
                )
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if($reportValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()

    let $LCP_12_1 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.1",
            "Identification of ProductionFacility release/transfer outliers
            against previous year data at the national level",
            $res
    )
    (: TODO not final version :)
    (: C12.2 - Identification of ProductionFacility release/transfer outliers
        against national total and pollutant threshold :)
    let $res :=
        let $getThresholdValue := function (
            $pollutantNode as element()
        ) as xs:double {
            let $type := $pollutantNode/local-name()
            return
                if($type = 'pollutantRelease')
                then $getThresholdPollutantRelease($pollutantNode)
                else if($type = 'offsitePollutantTransfer')
                then $getThresholdOffsitePollutantTransfer($pollutantNode)
                else $getThresholdOffsiteWasteTransfer($pollutantNode)
        }
        let $pollutantTypes := ('pollutantRelease', 'offsitePollutantTransfer', 'offsiteWasteTransfer')
        let $nationalValuesXML :=
        <data>
        {
            for $pollutantNode in $docRoot//ProductionFacilityReport/*[local-name() = $pollutantTypes]
            return
            <row>
                <InspireId>{$pollutantNode/ancestor::ProductionFacilityReport/InspireId/*}</InspireId>
                <type>{$pollutantNode/local-name()}</type>
                <EPRTRAnnexIActivity>
                    {scripts:getEPRTRAnnexIActivity(
                            $pollutantNode/ancestor::ProductionFacilityReport/InspireId/localId,
                            $previous-year,
                            $docProductionFacilities)}
                </EPRTRAnnexIActivity>
                <pollutant>{$pollutantNode/pollutant/text()}</pollutant>
                <mediumCode>{$pollutantNode/mediumCode/text()}</mediumCode>
                <totalPollutantQuantityKg>
                    {$pollutantNode/totalPollutantQuantityKg => functx:if-empty(0) => fn:number()}
                </totalPollutantQuantityKg>
                <totalWasteQuantityTNE>
                    {$pollutantNode/totalWasteQuantityTNE => functx:if-empty(0) => fn:number()}
                </totalWasteQuantityTNE>
                <wasteClassification>
                    {$pollutantNode/wasteClassification/text()}
                </wasteClassification>
            </row>
        }
        </data>
        (:let $trace := trace($nationalValuesXML, "nationalTotal: "):)

        let $getNationalTotal := function (
            $pollutantNode as element(),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            let $type := $pollutantNode/local-name()
            return
            if($type = 'offsiteWasteTransfer')
            then
                $nationalValuesXML//row[type = $type
                    and EPRTRAnnexIActivity = $EPRTRAnnexIActivity
                        and wasteClassification = $pollutantNode/wasteClassification]
                        /totalWasteQuantityTNE => fn:sum()
            else if($type = 'pollutantRelease')
            then
                $nationalValuesXML//row[type = $type and pollutant = $pollutantNode/pollutant
                    and EPRTRAnnexIActivity = $EPRTRAnnexIActivity and mediumCode = $pollutantNode/mediumCode]
                        /totalPollutantQuantityKg => fn:sum()
            else
                $nationalValuesXML//row[type = $type and pollutant = $pollutantNode/pollutant
                    and EPRTRAnnexIActivity = $EPRTRAnnexIActivity]
                        /totalPollutantQuantityKg => fn:sum()
        }

        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Reported value exceeds the threshold conditions'

        for $facility in $seq
            let $InspireId := $facility/InspireId
            let $EPRTRAnnexIActivity :=
                $nationalValuesXML//row[InspireId/data() = $InspireId/data()][1]
                    /EPRTRAnnexIActivity/text() => functx:if-empty('Activity not found')
            for $pollutantNode in $facility/*[local-name() = $pollutantTypes]
                let $pollutantType := $pollutantNode/local-name()
                let $nationalTotal := $getNationalTotal($pollutantNode, $EPRTRAnnexIActivity)
                let $reportedValue :=
                    $pollutantNode/totalPollutantQuantityKg => functx:if-empty($pollutantNode/totalWasteQuantityTNE)
                        => functx:if-empty(0) => fn:number()
                let $thresholdValue := $getThresholdValue($pollutantNode)
                let $notOk := (
                    $reportedValue > $thresholdValue * 10000
                    and
                    $reportedValue > $nationalTotal div 10
                )
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Type': map {'pos': 3, 'text': $pollutantType || $getCodes($pollutantNode)
                    },
                    'Reported value': map {'pos': 4,
                        'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                    },
                    'National total': map {'pos': 5,
                        'text': $nationalTotal => xs:decimal() => fn:round-half-to-even(2)
                    },
                    'Threshold value': map {'pos': 6,
                        'text': $thresholdValue => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                return
                    if($notOk)
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()


    let $LCP_12_2 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.2",
            "Identification of ProductionFacility release/transfer outliers
            against national total and pollutant threshold",
            $res
    )
    (: TODO not final version :)
    (: C12.3 - Identification of ProductionFacility release/transfer outliers against previous year data :)
    let $res :=
        let $getLastYearValue := function (
            $pollutantNode as element(),
            $inspireId as xs:string
        ) as xs:double {
            if($pollutantNode/local-name() = 'pollutantRelease')
            then $docProductionFacilities//ProductionFacility[year = $previous-year
                and InspireId = $inspireId]/pollutantRelease[mediumCode = $pollutantNode/mediumCode
                    and pollutant = $pollutantNode/pollutant]
                        /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            else if($pollutantNode/local-name() = 'offsitePollutantTransfer')
            then $docProductionFacilities//ProductionFacility[year = $previous-year
                and InspireId = $inspireId]/offsitePollutantTransfer[pollutant = $pollutantNode/pollutant]
                    /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            else -1
        }
        let $getLastYearValueOffsiteWasteTransfer := function (
            $wasteClassification as xs:string,
            $inspireId as xs:string
        ) as xs:double {
            $docProductionFacilities//ProductionFacility[year = $previous-year
                and InspireId = $inspireId]/offsiteWasteTransfer
                    [wasteClassification => functx:substring-after-last("/") = $wasteClassification]
                        /totalWasteQuantityTNE => fn:sum()

        }
        let $pollutantTypes := ('pollutantRelease', 'offsitePollutantTransfer', 'offsiteWasteTransfer')
        let $seq := $docRoot//ProductionFacilityReport[InspireId/localId = $facilityInspireIds]
        let $errorType := 'warning'
        let $text := 'Threshold exceeded the data compared to the previous year'
        for $facility in $seq
            for $pollutantType in $pollutantTypes
            (:let $trace := trace($pollutantType, "pollutantType: "):)
            let $result :=
            if($pollutantType != 'offsiteWasteTransfer')
            then
                for $pollutantNode in $facility/*[local-name() = $pollutantType]
                let $reportedValue := $pollutantNode/totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
                let $lastYearValue := $getLastYearValue($pollutantNode, $facility/InspireId/localId/data())
                (:let $trace := trace($reportedValue, "reportedValue: "):)
                (:let $trace := trace($lastYearValue, "lastYearValue: "):)
                let $ok := (
                    $reportedValue + $lastYearValue = 0
                    or
                    ($reportedValue < $lastYearValue * 2
                    and
                    $reportedValue * 10 > $lastYearValue)
                )
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Type': map {'pos': 3, 'text': $pollutantType || $getCodes($pollutantNode)
                    },
                    'Reported value': map {'pos': 4,
                        'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                    },
                    'Last year value': map {'pos': 5,
                        'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()

            else
                for $wasteClassification in ('HW', 'NONHW')
                let $reportedValue := $facility/offsiteWasteTransfer
                    [wasteClassification => functx:substring-after-last("/") = $wasteClassification]
                        /functx:if-empty(totalWasteQuantityTNE, 0) => fn:sum()
                let $lastYearValue := $getLastYearValueOffsiteWasteTransfer(
                        $wasteClassification,
                        $facility/InspireId/localId/data()
                )
                (:let $trace := trace($wasteClassification, "wasteClassification: "):)
                (:let $trace := trace($reportedValue, "reportedValue: "):)
                (:let $trace := trace($lastYearValue, "lastYearValue: "):)
                let $ok := (
                    $reportedValue + $lastYearValue = 0
                    or
                    ($reportedValue < $lastYearValue * 10
                    and
                    $reportedValue * 10 > $lastYearValue)
                )
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                    'Type': map {'pos': 3, 'text': $pollutantType || ' - ' || $wasteClassification
                    },
                    'Reported value': map {'pos': 4,
                        'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                    },
                    'Last year value': map {'pos': 5,
                        'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()
            return $result

    let $LCP_12_3 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.3",
            "Identification of ProductionFacility release/transfer outliers
            against previous year data at the ProductionFacility level",
            $res
    )

    (: TODO not final version :)
    (: C12.4 - Identification of ProductionInstallationPart emission outliers
        against previous year data at the ProductionInstallationPart level. :)
    let $res :=
        let $getLastYearValue := function (
            $emissionNode as element(),
            $inspireId as xs:string
        ) as xs:double {
            $docProductionInstallationParts//ProductionInstallationPart[year = $previous-year
                and InspireId = $inspireId]/emissionsToAir
                    [pollutant = $emissionNode/pollutant]
                        /totalPollutantQuantityTNE => functx:if-empty(0) => fn:number()

        }
        let $seq := $docRoot//ProductionInstallationPartReport[InspireId/localId = $installationPartInspireIds]
        let $errorType := 'warning'
        let $text := 'Threshold exceeded the data compared to the previous year'
        for $part in $seq
            for $emissionNode in $part/emissionsToAir
                let $reportedValue := $emissionNode/totalPollutantQuantityTNE => functx:if-empty(0) => fn:number()
                let $lastYearValue := $getLastYearValue($emissionNode, $part/InspireId/localId/data())
                (:let $trace := trace($reportedValue, "reportedValue: "):)
                (:let $trace := trace($lastYearValue, "lastYearValue: "):)
                let $ok := (
                    $reportedValue < $lastYearValue * 2
                    and
                    $reportedValue * 10 > $lastYearValue
                )
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'InspireId': map {'pos': 2, 'text': $part/InspireId},
                    'Type': map {'pos': 3, 'text': $emissionNode/pollutant => functx:substring-after-last("/")},
                    'Reported value': map {'pos': 4,
                        'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                    },
                    'Last year value': map {'pos': 5,
                        'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if($reportedValue > 0):)
                    then
                        scripts:generateResultTableRow($dataMap)
                    else()


    let $LCP_12_4 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.4",
            "Identification of ProductionInstallationPart emission outliers against
            previous year data at the ProductionInstallationPart level"
            , $res
    )
    (: TODO not final version :)
    (: C12.5 – Time series consistency for ProductionInstallationPart emissions :)
    let $res :=
        let $getLowestPollutant := function (
        ) as xs:string {
            'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CRANDCOMPOUNDS'
        }

        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $errorType := 'warning'
        let $text := 'Pollutant release ratio threshold has been exceeded'
        for $facility in $docRoot//ProductionFacilityReport
            let $lowestValuePrevYears := 1234
            let $lowestValueActualYear := $facility/pollutantRelease/totalPollutantQuantityKg => fn:min()
            let $lowestValue := fn:min($lowestValuePrevYears, $lowestValueActualYear)
            let $lowestPollutant :=
                if($lowestValuePrevYears < $lowestValueActualYear)
                then $getLowestPollutant()
                else $facility/pollutantRelease[totalPollutantQuantityKg = $lowestValueActualYear]/pollutant
            let $thresholdValue := $docANNEXII//row[Codelistvalue
                = $lowestPollutant=>scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                    /toAir => functx:if-empty(0) => fn:number()

            let $eligible := $lowestValue > $thresholdValue * 20
            return
                (:if($eligible):)
                if(fn:false())
                (:if($reportValue > 0):)
                then
                    let $maxQuantity := 123
                    let $minQuantity := 1
                    let $ratio := $maxQuantity div $minQuantity

                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                        'PollutantRelease': map {'pos': 3,
                            'text': '', 'errorClass': 'td' || $errorType
                        },
                        'Year': map {'pos': 4, 'text': ''}
                    }
                    return
                        scripts:generateResultTableRow($dataMap)
                else ()


    let $LCP_12_5 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.5",
            "Time series consistency for ProductionFacility emissions",
            $res
    )
    (: C12.6 - Time series consistency for ProductionInstallationPart emissions :)
    let $res :=
        let $pollutants := ('SO2', 'NOX', 'DUST')
        for $pollutant in $pollutants
            let $total := fn:sum(
                $docRoot//emissionsToAir[pollutant => functx:substring-after-last("/") = $pollutant]
                        /totalPollutantQuantityTNE/fn:data()
            )
            let $average3Year :=
                $docAverage//row[MemberState = $country_code and ReferenceYear = $look-up-year][1]
                    /*[fn:local-name() = 'Avg_3yr_' || $pollutant]/fn:data() => functx:if-empty(0) => fn:number()
            (:let $asd := trace($pollutant, "pollutant: "):)
            (:let $asd := trace($total, "total: "):)
            (:let $asd := trace($average3Year, "average3Year: "):)
            let $percentage :=
                if($total > $average3Year)
                then (($total * 100) div $average3Year) - 100 => xs:decimal() => fn:round-half-to-even(2)
                else if($total < $average3Year)
                then (100 - ($total * 100) div $average3Year) => xs:decimal() => fn:round-half-to-even(2)
                else 100

            let $errorType :=
                if($total > $average3Year and $percentage > 30)
                then 'warning'
                else if($total > $average3Year and $percentage <= 30 and $percentage >= 10)
                then 'info'
                else if($total < $average3Year and $percentage > 30)
                then 'info'
                else 'ok'
            let $dataMap := map {
                'Details': map {
                    'pos': 1,
                    'text': 'The pollutant exceeds the three-year average',
                    'errorClass': $errorType
                },
                'Pollutant': map {'pos': 2, 'text': $pollutant},
                'Percentage': map {'pos': 3, 'text': $percentage || '%', 'errorClass': 'td' || $errorType},
                'Total value': map {'pos': 4, 'text': $total=>xs:long()},
                'Average 3 year': map {'pos': 5, 'text': $average3Year}
            }
            return
                if($errorType != 'ok')
                (:if(fn:true()):)
                then
                    scripts:generateResultTableRow($dataMap)
                else()



    let $LCP_12_6 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.6",
            "Time series consistency for ProductionInstallationPart emissions",
            $res
    )

    let $LCP_12 := xmlconv:RowAggregator(
            "EPRTR-LCP 12",
            "Identification of release and transfer outliers",
            (
                $LCP_12_1,
                $LCP_12_2,
                $LCP_12_3,
                $LCP_12_4,
                $LCP_12_5,
                $LCP_12_6
            )
    )
    (:let $asd := trace(fn:current-time(), 'started 13.1 at: '):)
    (: C13.1 - Number of ProductionFacilities reporting releases and transfers consistency :)
    let $res :=
        let $errorText := 'Number of reporting production facilities changes by more than'
        let $map1 := map {
            "pollutantRelease": map {
                'doc': $docRootCOUNT_OF_PollutantRelease,
                'filters': map {
                    'code1': ('AIR', 'WATER', 'LAND'), (: mediumCode :)
                    'code2': ('') (: empty code, pollutant type has only 1 code :)
                },
                'countNodeName': 'CountOfFacilityID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfFacilities#5
                } ,
            "offsitePollutantTransfer": map {
                'doc': $docRootCOUNT_OF_PollutantTransfer,
                'filters': map {
                    'code1': (''), (: empty codes, pollutant type does not have :)
                    'code2': ('')
                },
                'countNodeName': 'CountOfFacilityID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfFacilities#5
            },
            "offsiteWasteTransfer": map {
                'doc': $docRootCOUNT_OF_ProdFacilityOffsiteWasteTransfer,
                'filters': map {
                    'code1': (''), (: wasteClassification :)
                    'code2': ('') (: wasteTreatment :)
                },
                'countNodeName': 'CountOfFacilityID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfFacilities#5
            }

        }
        return scripts:compareNumberOfPollutants(
            $map1,
            $country_code,
            $docRoot,
            $docPollutantLookup,
            $errorText
        )
    let $LCP_13_1 := xmlconv:RowBuilder("EPRTR-LCP 13.1",
            "Number of ProductionFacilities reporting releases and transfers consistency", $res)

    (:let $asd := trace(fn:current-time(), 'started 13.2 at: '):)
    (: C13.2 - Reported number of releases and transfers per medium consistency :)
    let $res :=
        let $errorText := 'Number of releases/transfers per medium changes by more than'
        let $map1 := map {
            "pollutantRelease": map {
                'doc': $docRootCOUNT_OF_PollutantRelease,
                'filters': map {
                    'code1': ('AIR', 'WATER', 'LAND'), (: mediumCode :)
                    'code2': ('')
                },
                'countNodeName': 'CountOfPollutantReleaseID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfPollutant#5
                } ,
            "offsitePollutantTransfer": map {
                'doc': $docRootCOUNT_OF_PollutantTransfer,
                'filters': map {
                    'code1': (''),
                    'code2': ('')
                },
                'countNodeName': 'CountOfPollutantTransferID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfPollutant#5
            },
            "offsiteWasteTransfer": map {
                'doc': $docRootCOUNT_OF_OffsiteWasteTransfer,
                'filters': map {
                    'code1': ('NONHW', 'HWIC', 'HWOC'), (: wasteClassification :)
                    'code2': ('D', 'R') (: wasteTreatment :)
                },
                'countNodeName': 'CountOfWasteTransferID',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfPollutant#5
            }

        }
        return scripts:compareNumberOfPollutants(
            $map1,
            $country_code,
            $docRoot,
            $docPollutantLookup,
            $errorText
        )
        (:return ():)
    let $LCP_13_2 := xmlconv:RowBuilder(
            "EPRTR-LCP 13.2",
            "Reported number of releases and transfers per medium consistency",
            $res
    )

    (:let $asd := trace(fn:current-time(), 'started 13.3 at: '):)
    (: C13.3 - Reported number of pollutants per medium consistency :)
    let $res :=
        let $errorText := 'Total pollutant release changes by more than'
        (: map with options for pollutant types :)
        let $map1 := map {
            "pollutantRelease": map {
                'doc': $docRootCOUNT_OF_PollutantRelease,
                'filters': map {
                    'code1': ('AIR', 'WATER', 'LAND'), (: mediumCode :)
                    'code2': ('')
                },
                'countNodeName': 'CountOfPollutantCode',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfPollutantDistinct#5
                },
            "offsitePollutantTransfer": map {
                'doc': $docRootCOUNT_OF_PollutantTransfer,
                'filters': map {
                    'code1': (''),
                    'code2': ('')
                }, (: NA = not available:)
                'countNodeName': 'CountOfPollutantCode',
                'countFunction': scripts:getCountOfPollutant#6,
                'reportCountFunction': scripts:getreportCountOfPollutantDistinct#5
            }
        }
        return scripts:compareNumberOfPollutants(
            $map1,
            $country_code,
            $docRoot,
            $docPollutantLookup,
            $errorText
        )
        (:
        for $pollutant in $pollutantTypes
            for $mediumCode in $map1?($pollutant)?mediumCode
            :)(:let $asd := trace($pollutant, 'pollutant: '):)(:
            :)(:let $asd := trace($mediumCode, 'mediumCode: '):)(:
            let $result :=
                let $CountOfPollutantCode :=
                    if($mediumCode = 'NA')
                    then $map1?($pollutant)?doc//row[CountryCode = $country_code]/CountOfPollutantCode => fn:number()
                    else $map1?($pollutant)?doc//row[CountryCode = $country_code and ReleaseMediumCode = $mediumCode]
                            /CountOfPollutantCode => fn:number()
                let $reportCountOfPollutantCode :=
                    if($mediumCode = 'NA')
                    then $docRoot//*[fn:local-name() = $pollutant]/pollutant => fn:distinct-values() => fn:count()
                    else $docRoot//*[fn:local-name() = $pollutant
                            and mediumCode=>functx:substring-after-last("/") = $mediumCode]
                                /pollutant => fn:distinct-values() => fn:count()
                :)(:let $asd := trace($CountOfPollutantCode, 'CountOfPollutantCode: '):)(:
                :)(:let $asd := trace($reportCountOfPollutantCode, 'reportCountOfPollutantCode: '):)(:
                let $changePercentage := 100-(($reportCountOfPollutantCode * 100) div $CountOfPollutantCode)
                :)(:let $asd := trace($changePercentage, 'changePercentage: '):)(:
                let $ok := $changePercentage <= 50
                let $errorType :=
                    if($changePercentage > 100)
                    then 'warning'
                    else 'info'
                return
                    if(fn:not($ok))
                    then
                    <tr>
                        <td class='{$errorType}' title="Details">
                            Number of reported pollutants changes by more than {
                            if($errorType = 'warning')
                            then '100%' else '50%'
                        }
                        </td>
                        <td title="Polutant">
                            {$pollutant} {if($mediumCode = 'NA') then '' else ', mediumCode - '||$mediumCode}
                        </td>
                        <td class="td{$errorType}" title="Change percentage">
                            {$changePercentage=>fn:round-half-to-even(2)}%
                        </td>
                        <td title="National level count">{$reportCountOfPollutantCode}</td>
                        <td title="Previous year count">{$CountOfPollutantCode}</td>
                    </tr>
                    else
                        ()
            return
                $result:)
    let $LCP_13_3 := xmlconv:RowBuilder("EPRTR-LCP 13.3","Reported number of pollutants per medium consistency", $res)

    (:let $asd := trace(fn:current-time(), 'started 13.4 at: '):)
    (: C13.4 - Quantity of releases and transfers consistency :)
    let $res :=
        let $pollutantReleaseCodesLastYear :=
            $docQUANTITY_OF_PollutantRelease//row[CountryCode = $country_code and Year = $look-up-year]
                    /PollutantCode
        let $pollutantTransferCodesLastYear :=
            $docQUANTITY_OF_PollutantTransfer//row[CountryCode = $country_code and Year = $look-up-year]
                    /PollutantCode
        let $errorText := 'Quantity of releases and transfers changes by more than'
        let $map1 := map {
            "pollutantRelease": map {
                'doc': $docQUANTITY_OF_PollutantRelease,
                'filters': map {
                    'code1': ('AIR', 'WATER', 'LAND'), (: mediumCode :)
                    'code2': $pollutantReleaseCodesLastYear (: pollutantCode :)
                },
                'countNodeName': 'SumOfTotalQuantity',
                'countFunction': scripts:getTotalsOfPollutant#6,
                'reportCountFunction': scripts:getreportTotalsOfPollutant#5
                } ,
            "offsitePollutantTransfer": map {
                'doc': $docQUANTITY_OF_PollutantTransfer,
                'filters': map {
                    'code1': $pollutantTransferCodesLastYear, (: pollutantCode :)
                    'code2': ('')
                },
                'countNodeName': 'SumOfTotalQuantity',
                'countFunction': scripts:getTotalsOfPollutant#6,
                'reportCountFunction': scripts:getreportTotalsOfPollutant#5
            },
            "offsiteWasteTransfer": map {
                'doc': $docQUANTITY_OF_OffsiteWasteTransfer,
                'filters': map {
                    'code1': ('NONHW', 'HWIC', 'HWOC'), (: wasteClassification :)
                    'code2': ('') (: wasteTreatment :)
                },
                'countNodeName': 'SumOfQuantity',
                'countFunction': scripts:getTotalsOfPollutant#6,
                'reportCountFunction': scripts:getreportTotalsOfPollutant#5
            },
            "emissionsToAir": map {
                'doc': $docAverage,
                'filters': map {
                    'code1': ('SO2', 'NOX', 'DUST'), (: pollutantCode :)
                    'code2': ('')
                },
                'countNodeName': '',
                'countFunction': scripts:getTotalsOfPollutant#6,
                'reportCountFunction': scripts:getreportTotalsOfPollutant#5
            }
        }

        return scripts:compareNumberOfPollutants(
            $map1,
            $country_code,
            $docRoot,
            $docPollutantLookup,
            $errorText
        )
        (:return ():)
    let $LCP_13_4 := xmlconv:RowBuilder("EPRTR-LCP 13.4",
            "Quantity of releases and transfers consistency", $res)

    let $LCP_13 := xmlconv:RowAggregator(
            "EPRTR-LCP 13",
            "Overview on inter-annual reporting consistency",
            (
                $LCP_13_1,
                $LCP_13_2,
                $LCP_13_3,
                $LCP_13_4
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 14.1 at: '):)
    (: TODO partially implemented :)
    (: C14.1 – Identification of top 10 ProductionFacility releases/transfers across Europe :)
    let $res :=
        let $getPollutantReleaseValue := function (
            $pollutantNode as element()
        ) as map(*){
            map {
                'value': $pollutantNode/totalPollutantQuantityKg => functx:if-empty(0) => fn:number(),
                'pollutant': $pollutantNode/pollutant => scripts:getPollutantCode($docPollutantLookup),
                'mediumCode': $pollutantNode/mediumCode => functx:substring-after-last("/")
            }
        }
        let $getPollutantReleaseLookupValue := function (
            $pollutantTypeDataMap as map(*),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            12345
        }
        let $getOffsitePollutantTransferValue := function (
            $pollutantNode as element()
        ) as map(*){
            map {
                'value': $pollutantNode/totalPollutantQuantityKg => functx:if-empty(0) => fn:number(),
                'pollutant': $pollutantNode/pollutant => scripts:getPollutantCode($docPollutantLookup)
            }
        }
        let $getOffsitePollutantTransferLookupValue := function (
            $pollutantTypeDataMap as map(*),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            23456
        }
        let $getOffsiteWasteTransferValue := function (
            $pollutantNode as element()
        ) as map(*){
            map {
                'value': $pollutantNode/totalWasteQuantityTNE => functx:if-empty(0) => fn:number() * 1000,
                'wasteClassification':
                    let $code := $pollutantNode/wasteClassification/data() => functx:substring-after-last("/")
                    let $transboundaryTransfer := $pollutantNode/transboundaryTransfer/data()
                    return
                        if($code = 'NONHW')
                        then 'NONHW'
                        else if (fn:string-length($transboundaryTransfer) > 0)
                            then $code || 'OC'
                            else $code || 'IC',
                'wasteTreatment': $pollutantNode/wasteTreatment/text() => functx:substring-after-last("/")
            }
        }
        let $getOffsiteWasteTransferLookupValue := function (
            $pollutantTypeDataMap as map(*),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            34567
        }
        let $getCodes := function (
            $pollutantTypeDataMap as map(*)
        ) as xs:string {
            let $codes :=
                for $code in map:keys($pollutantTypeDataMap)
                return
                    if($code != 'value')
                    then
                        $pollutantTypeDataMap?($code)
                    else ()
            return $codes => string-join(' / ')
        }

        let $map1 := map {
            "pollutantRelease": map {
                'report': $getPollutantReleaseValue,
                'lookup': $getPollutantReleaseLookupValue
            },
            "offsitePollutantTransfer": map {
                'report': $getOffsitePollutantTransferValue,
                'lookup': $getOffsitePollutantTransferLookupValue
            },
            "offsiteWasteTransfer": map {
                'report': $getOffsiteWasteTransferValue,
                'lookup': $getOffsiteWasteTransferLookupValue
            }
        }
        let $errorType := 'info'
        let $text := 'ProductionFacility release/transfer rank among the top 10 at the European level'

        let $seq := $docRoot//ProductionFacilityReport
            for $facility in $seq
                let $EPRTRAnnexIActivity := scripts:getEPRTRAnnexIActivity(
                    $facility/InspireId/localId,
                    $previous-year,
                    $docProductionFacilities
            )
                for $pollutantType in $facility/*[local-name() = map:keys($map1)]
                    let $pollutantName := $pollutantType/local-name()
                    let $pollutantTypeDataMap := $map1?($pollutantName)?report($pollutantType)
                    let $reportedValue := $pollutantTypeDataMap?value
                    let $lookupTableValue := $map1?($pollutantName)?lookup($pollutantTypeDataMap, $EPRTRAnnexIActivity)
                    let $ok := $reportedValue < $lookupTableValue
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                        'Type': map {'pos': 3, 'text': $pollutantName || ' - ' || $getCodes($pollutantTypeDataMap)},
                        'Reported amount (in Kg)':
                            map {'pos': 4, 'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType},
                        'European 10th value (in Kg)': map {'pos': 5, 'text': $lookupTableValue => xs:decimal()}
                    }
                    return
                        (:if(not($ok)):)
                        if(false())
                        then scripts:generateResultTableRow($dataMap)
                        else ()
    let $LCP_14_1 := xmlconv:RowBuilder("EPRTR-LCP 14.1",
            "Identification of top 10 ProductionFacility releases/transfers across Europe (Partially IMPLEMENTED)", $res)

    (:let $asd := trace(fn:current-time(), 'started 14.2 at: '):)
    (: C14.2 – Identification of ProductionFacility release/transfer outliers against European level data :)
    let $res :=
        let $reportedPollutantCodes := $docRoot//pollutant => fn:distinct-values()
        let $pollutantCodesNeeded :=
            $docPollutantLookup//row[Newcodelistvalue = $reportedPollutantCodes]/PollutantCode/text()
        (:let $asd := trace($pollutantCodes => fn:count(), 'pollutantCodes: '):)
        (:let $asd := trace($pollutantCodesNeeded => fn:count(), 'pollutantCodesNeeded: '):)

        let $map1 := map {
            "pollutantRelease": map {
                'doc': $docEUROPEAN_TOTAL_PollutantRelease,
                'filters': map {
                    'code1': $pollutantCodesNeeded,  (:pollutantCode:)
                    'code2': ('AIR', 'WATER', 'LAND')  (:mediumCode:)
                },
                'countNodeName': 'SumOfTotalQuantity',
                'countFunction': scripts:getEuropeanTotals#5,
                'reportCountFunction': scripts:getreportFacilityTotals#5
                } ,
            "offsitePollutantTransfer": map {
                'doc': $docEUROPEAN_TOTAL_PollutantTransfer,
                'filters': map {
                    'code1': $pollutantCodesNeeded,  (:pollutantCode:)
                    'code2': ('')
                },
                'countNodeName': 'SumOfQuantity',
                'countFunction': scripts:getEuropeanTotals#5,
                'reportCountFunction': scripts:getreportFacilityTotals#5
            },
            "offsiteWasteTransfer": map {
                'doc': $docEUROPEAN_TOTAL_OffsiteWasteTransfer,
                'filters': map {
                    'code1': ('NONHW', 'HWIC', 'HWOC'),  (:wasteClassification:)
                    'code2': ('D','R')  (:wasteTreatment :)
                },
                'countNodeName': 'SumOfQuantity',
                'countFunction': scripts:getEuropeanTotals#5,
                'reportCountFunction': scripts:getreportFacilityTotals#5
            }
        }
        let $err := 'warning'
        let $text := 'ProductionFacility represents >90% of the total quantity for the specified type across Europe'
        let $seq := $docRoot//ProductionFacilityReport
        for $facility in $seq,
        $pollutant in map:keys($map1)
            let $keys := map:keys($map1?($pollutant)?filters)
            for $code1 in $map1?($pollutant)?filters?code1,
            $code2 in $map1?($pollutant)?filters?code2
                (:let $asd := trace($pollutant, 'pollutant: '):)
                (:let $asd := trace($code1, 'code1: '):)
                (:let $asd := trace($code2, 'code2: '):)

                let $reportTotal := $map1?($pollutant)?reportCountFunction (
                    $code1,
                    $code2,
                    $facility,
                    $docPollutantLookup,
                    $pollutant
                )
                let $europeanTotal := $map1?($pollutant)?countFunction(
                    $map1?($pollutant),
                    $code1,
                    $code2,
                    $look-up-year,
                    $pollutant
                )
                (:let $asd := trace($europeanTotal, 'europeanTotal: '):)
                (:let $asd := trace($reportTotal, 'reportTotal: '):)
                let $percentage := if($europeanTotal = 0)
                    then 0
                    else (($reportTotal * 100) div $europeanTotal) => xs:decimal() => fn:round-half-to-even(5)

                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $err},
                    'Type': map {'pos': 2,
                        'text': $pollutant || ' - ' || $code1 || (if($code2 = '') then '' else ' / ' || $code2)
                    },
                    'InspireId': map {'pos': 3, 'text': $facility/InspireId},
                    'Percentage': map {'pos': 4, 'text': $percentage || '%', 'errorClass': 'td' || $err},
                    'Reported total (in kg/year)': map {'pos': 5, 'text': $reportTotal => xs:decimal()},
                    'European total (in kg/year)': map {'pos': 6,
                        'text': $europeanTotal => xs:decimal() => fn:round-half-to-even(2)
                    }
                }
                let $ok := $percentage < 90
                return
                    if(fn:not($ok))
                    (:if($reportTotal > 0):)
                    then scripts:generateResultTableRow($dataMap)
                    else ()

        (:let $docDD := fn:doc('inputs/EPRTRPollutantCodeValue.rdf')
        let $pollutantsLookup1 := $docEUROPEAN_TOTAL_PollutantRelease//PollutantCode/data() => fn:distinct-values()
        let $pollutantsLookup2:= $docEUROPEAN_TOTAL_PollutantTransfer//PollutantCode/data() => fn:distinct-values()
        let $pollutantsLookup3:= $docQUANTITY_OF_PollutantRelease//PollutantCode/data() => fn:distinct-values()
        let $pollutantsLookup4:= $docQUANTITY_OF_PollutantTransfer//PollutantCode/data() => fn:distinct-values()
        let $pollutantsLookup5:= $docNATIONAL_TOTAL_PollutantRelease//PollutantCode/data() => fn:distinct-values()
        let $pollutantsLookup6:= $docNATIONAL_TOTAL_PollutantTransfer//PollutantCode/data() => fn:distinct-values()
        let $pollutantsDD := $docDD//skos:notation/data() => fn:distinct-values()
        let $pollutantsLookup :=
            ($pollutantsLookup1, $pollutantsLookup2, $pollutantsLookup3,
            $pollutantsLookup4, $pollutantsLookup5, $pollutantsLookup6)
            => fn:distinct-values()
        let $asd := trace($pollutantsLookup=>count(), "pollutantsLookup: ")
        let $asd := trace($pollutantsDD=>count(), "pollutantsDD: ")
        for $pollutant in $pollutantsLookup
            let $dataMap := map {
                'pollutant': map {'text': $pollutant, 'errorClass': 'error'}
            }
            return
                if(not(functx:is-value-in-sequence($pollutant, $pollutantsDD)))
                then scripts:generateResultTableRow($dataMap)
                else ():)

    let $LCP_14_2 := xmlconv:RowBuilder("EPRTR-LCP 14.2",
            "Identification of ProductionFacility release/transfer outliers against European level data", $res)

    let $LCP_14 := xmlconv:RowAggregator(
            "EPRTR-LCP 14",
            "Verification of emissions against European level data",
            (
                $LCP_14_1,
                $LCP_14_2
            )
    )

    (:let $asd := trace(fn:current-time(), 'started 15 at: '):)
    (:
        As a result, countries that report high biomass consumption (e.g. Sweden) may report CO2 emissions
        that exceed the values reported under the UNFCCC/EU-MMR National Inventory and this check
        will provide a false positive.
    :)
    (:  C15.1 – Comparison of PollutantReleases and EmissionsToAir to CLRTAP/NECD
        and UNFCCC/EU-MMR National Inventories    :)
    let $res :=
        (: init lookup tables with data :)
        let $docCLRTAPdata := fn:doc($xmlconv:CLRTAP_DATA)
        let $docCLRTAPpollutantLookup := fn:doc($xmlconv:CLRTAP_POLLUTANT_LOOKUP)
        let $docUNFCCdata := fn:doc($xmlconv:UNFCC_DATA)
        let $docUNFCCpollutantLookup := fn:doc($xmlconv:UNFCC_POLLUTANT_LOOKUP)
        (: two pollutant types that we need to check :)
        let $pollutantTypes := ('pollutantRelease', 'emissionsToAir')
        for $pollutantType in $pollutantTypes
            let $elemNameTotalQuantity :=
                if($pollutantType = 'pollutantRelease')
                then 'totalPollutantQuantityKg'
                else 'totalPollutantQuantityTNE'
            let $dataDictName :=
                if($pollutantType = 'pollutantRelease')
                then 'EPRTRPollutantCodeValue'
                else 'LCPPollutantCodeValue'
            (: get distinct all the pollutants for that specific type:)
            let $seqPollutants := $docRoot//*[fn:local-name() = $pollutantType]
            let $pollutants :=
                fn:distinct-values($seqPollutants/pollutant/fn:data())

            for $pollutant in $pollutants
                (: get the skos:notation from data dictionary, if not found then substring
                after the last '/' from URI :)
                (:let $pollutant := scripts:getCodeNotation($pollutant, $dataDictName)=>functx:substring-after-last("/"):)
                let $pollutant := $pollutant =>functx:substring-after-last("/")
                (: calculate national total, summ all pollutants from the XML report file :)
                let $nationalTotal :=
                    fn:sum($seqPollutants[functx:substring-after-last(pollutant, "/") = $pollutant]
                        /*[fn:local-name() = $elemNameTotalQuantity]/fn:number(fn:data())
                    )
                (: for emissionsToAir type, the measurement is in TNE = metric tonnes per year
                multiply the value with 1000 to get equivalent in Kg :)
                let $nationalTotal :=
                    if($pollutantType = 'pollutantRelease')
                    then $nationalTotal
                    else $nationalTotal * 1000

                (: get totals from CLRTAP lookup table :)
                let $clrtapTotal := scripts:getCLRTAPtotals(
                        $docCLRTAPdata,
                        $docCLRTAPpollutantLookup,
                        $pollutant,
                        $pollutantType,
                        $country_code,
                        $look-up-year
                    )
                (: get totals from UNFCC lookup table :)
                let $unfccTotal :=
                    if($pollutantType = 'pollutantRelease')
                    then scripts:getUNFCCtotals(
                        $docUNFCCdata,
                        $docUNFCCpollutantLookup,
                        $pollutant,
                        $country_code,
                        $look-up-year
                    )
                    (: for emissionsToAir we dont check UNFCC, so we add +1 to nationalTotal
                    this way it will not be flagged for warning :)
                    else $nationalTotal + 1
                let $ok := (
                    ($nationalTotal <= $clrtapTotal or $clrtapTotal < 0)
                    and
                    ($nationalTotal <= $unfccTotal or $unfccTotal < 0)
                )
                return
                    if(fn:not($ok))
                    (:if(true()):)
                    then
                    <tr>
                        <td class='warning' title="Details">
                            Pollutant have exceeded the corresponding values reported under CLRTAP
                            {if($pollutantType = 'pollutantRelease') then 'or UNFCCC ' else ''}Conventions
                        </td>
                        <td title="Pollutant">{$pollutantType}</td>
                        <td title="Pollutant code"> {$pollutant} </td>
                        <td class="tdwarning" title="National totals (in kg/year)"> {$nationalTotal=>xs:long()} </td>
                        <td title="CRLTAP totals (in kg/year)">
                            {if($clrtapTotal >= 0) then $clrtapTotal=>xs:long() else 'Data not available'}
                        </td>
                        <td title="UNFCCC totals (in kg/year)">
                            {
                                if($pollutantType = 'pollutantRelease')
                                then if($unfccTotal >= 0) then $unfccTotal=>xs:long() else 'Data not available'
                                else 'Not comparable'
                            }
                        </td>
                    </tr>
                    else ()


    let $LCP_15_1 := xmlconv:RowBuilder("EPRTR-LCP 15.1",
            "Comparison of PollutantReleases and EmissionsToAir to CLRTAP/NECD and UNFCCC/EU-MMR National Inventories",
            $res)

    let $LCP_15 := xmlconv:RowAggregator(
        "EPRTR-LCP 15",
        "Verification of national emissions against external datasets",
        (
            $LCP_15_1
        )
    )

    (:let $asd := trace(fn:current-time(), 'started 16 at: '):)
    (:  C16.1 - Significant figure format compliance    :)

    let $getNumberOfSignificantDigits := function (
        $number as xs:string
    ) as xs:double {
        (:let $asd := trace($number, "number: "):)
        if($number = '0')
        then 0
        else
            if(fn:contains($number, '.'))
            then
                let $nr := replace($number, '\.+', '')
                let $nr := replace($nr, '^0+', '')
                return $nr => fn:string-length()
            else
                let $nr := replace($number, '^0+', '')
                let $nr := replace($nr, '0+$', '')
                return $nr => fn:string-length()
    }

    let $res :=
        let $attributes := (
            "totalWasteQuantityTNE",
            "totalPollutantQuantityKg",
            "totalPollutantQuantityTNE"
        )
        let $seq := $docRoot//*[fn:local-name() = $attributes]
        for $elem in $seq
        let $elemValue := functx:if-empty($elem/data(), 0)
        let $significantDigits :=
            $getNumberOfSignificantDigits($elemValue => fn:string())
        (:let $asd := trace($elemValue, "elemValue: "):)
        (:let $asd := trace($significantDigits, "significantDigits: "):)
        let $ok := (
            $elemValue castable as xs:double
            and
            (
                $significantDigits = 3
                or
                ($significantDigits < 3 and fn:string-length(string($elemValue)) > 2)
            )
        )
        return
            if(fn:not($ok))
            (:if(fn:true()):)
            then
                <tr>
                    <td class='warning' title="Details">Numerical format reporting requirements not met</td>
                    <td title="inspideId">
                        {$elem/ancestor-or-self::*[fn:local-name() =
                                ("ProductionInstallationPartReport", "ProductionFacilityReport")]/InspireId}
                    </td>
                    <td title="Parent feature type">{fn:node-name($elem/parent::*)}</td>
                    <td title='Additional info'>{$getAdditionalInformation($elem/parent::*)}</td>
                    <td title='Attribute name'>{fn:node-name($elem)}</td>
                    <td class="tdwarning" title="value"> {$elemValue} </td>
                    <td title="Number of significant digits"> {$significantDigits} </td>
                </tr>
            else
                ()
    let $LCP_16_1 := xmlconv:RowBuilder("EPRTR-LCP 16.1","Significant figure format compliance", $res)
    (:  C16.2 - Percentage format compliance    :)
    let $res :=
        let $attributes := (
            "proportionOfUsefulHeatProductionForDistrictHeating",
            "desulphurisationRate",
            "sulphurContent"
        )
        let $seq := $docRoot//ProductionInstallationPartReport//*[fn:local-name() = $attributes]
        for $elem in $seq
        let $elemValue := functx:if-empty($elem/data(), 0)=>fn:number()
        let $ok := (
            $elemValue castable as xs:double
            and
            $elemValue <= 1
        )
        return
            if(fn:not($ok))
            then
                <tr>
                    <td class='warning' title="Details">
                        Attribute has been populated with a value representing a percentage greater than 100%
                    </td>
                    <td title="inspireId">
                        {$elem/ancestor-or-self::*[fn:local-name() = ("ProductionInstallationPartReport")]
                                /InspireId}
                    </td>
                    <td title="Feature type">{fn:node-name($elem/parent::*)}</td>
                    <td class="tdwarning" title="Attribute name"> {fn:node-name($elem)} </td>
                    <td class="tdwarning" title="value"> {$elemValue} </td>
                </tr>

            else
                ()
    let $LCP_16_2 := xmlconv:RowBuilder("EPRTR-LCP 16.2","Percentage format compliance", $res)

    let $LCP_16 := xmlconv:RowAggregator(
            "EPRTR-LCP 16",
            "Expected pollutant identification",
            (
                $LCP_16_1,
                $LCP_16_2
            )
    )


    (: RETURN ALL ROWS IN A TABLE :)
    return
        (
            $LCP_1,
            $LCP_2,
            $LCP_3,
            $LCP_4,
            $LCP_5,
            $LCP_6,
            $LCP_7,
            $LCP_8,
            $LCP_9,
            $LCP_10,
            $LCP_11,
            $LCP_12,
            $LCP_13,
            $LCP_14,
            $LCP_15,
            $LCP_16
        )

};

declare function eworx:testDocumentBasicTypes(
        $source_url as xs:string
){

    let $res := for $attr in fn:doc($source_url)//Plant/descendant::*
        where  eworx:testBasicElementType($attr, $source_url) = "false"
        return
        <tr>
            <td class='error' title="Details"> Invalid input value on the field <b> { fn:name($attr) } </b></td>
            <td title="PlantId">{ fn:data(($attr)/ancestor::*/PlantId ) }</td>
            <td class="tderror" title="Invalid value">{ fn:data( $attr ) }</td>
            <td title="xml path">{ functx:path-to-node (($attr) ) }</td>
        </tr>

    return
        if (fn:exists($res )) then
            xmlconv:RowBuilder("LCP XML", "XML Document Validity Errors. QAs did not run", $res)
        else ()


} ;

declare function xmlconv:DoValidate(
        $source_url as xs:string
) as element(table){

    let $res :=
        if ( fn:exists(eworx:testDocumentBasicTypes($source_url))) then
            eworx:testDocumentBasicTypes($source_url)
        else
            xmlconv:RunQAs($source_url)
    return
    <table class="table table-bordered table-condensed" id="maintable">
        <colgroup>
            <col width="45px" style="text-align:center"/>
            <col width="40%" style="text-align:left"/>
            <col width="40%" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        { $res }

    </table>
};

(:~
: JavaScript
:)
declare function xmlconv:getJS() as element(script) {

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}


    function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display === "table-row") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "table-row";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}
                ]]>
        </script>
    return
        <script type="text/javascript">{fn:normalize-space($js)}</script>
};

(:~
: Legend
:)
declare function xmlconv:getLegend() as element()*{

    let $legend :=
        <fieldset style="font-size: 90%; display: inline;" id="legend">
            <legend>How to read the test results</legend>
            All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
            <ul style="list-style-type: none;">QC TESTS
                <li>
                    <div class="bullet" style="width:50px; display:inline-block;margin-left:10px">
                        <div class="error">Red</div>
                    </div> - the check issued an error. Please correct the invalid records.
                </li>
                <li>
                    <div class="bullet" style="width:50px; display:inline-block;margin-left:10px">
                        <div class="warning">Orange</div>
                    </div> - the check issued a warning. Please review the corresponding records.
                </li>
                <li>
                    <div class="bullet" style="width:50px; display:inline-block;margin-left:10px">
                        <div class="info">Blue</div>
                    </div> - the check issued info. Please review the corresponding records.
                </li>
                <li>
                    <div class="bullet" style="width:50px; display:inline-block;margin-left:10px">
                        <div class="passed">Green</div>
                    </div> - the check passed without errors or warnings.
                </li>
            </ul>
            <p>Click on the "Show records" link to see more details about the test result.</p>
        </fieldset>
    return
        (<br></br>,$legend,<br></br>, <br></br>)
};

(:~
: CSS
:)
declare function xmlconv:getCSS() as element()*{
(
 <style>
<![CDATA[

.bullet {
  width: 55px; }

.bullet div {
  font-size: 0.8em;
  color: white;
  padding-left: 5px;
  padding-right: 5px;
  margin-right: 5px;
  margin-top: 2px;
  text-align: center;
  width: 50px; }

.bullet div.error {
  background-color: #E83131; }

.bullet div.warning {
  background-color: #F5A105; }

.bullet div.info {
  background-color: #2D789C; }

.bullet div.passed {
  background-color: #409C2D; }

table {
  width: 100%; }

th, td {
  padding: 3px; }

.rulename {
  text-align: left;
  font-weight: bold; }

.message {
  text-align: right; }

#maintable {
  background-color: #FAFAFA; }

.showdatatable {
  font-size: 15px; }
  .showdatatable tr .error {
    background-color: #f2dede; }
  .showdatatable .tderror {
    border: 2px solid  #E83131;
    background-color: #FFFFFF; }
  .showdatatable .tdwarning {
    border: 2px solid  #F5A105;
    background-color: #FFFFFF;  }
  .showdatatable .tdinfo {
    border: 2px solid  #2D789C;
    background-color: #FFFFFF; ; }
h2 {
  font-weight: bold;
  padding: 0.2em 0.4em;
  background-color: rgb(240, 244, 245);
  color: #000000;
  border-top: 1px solid rgb(224, 231, 215);
}

]]>
</style>,  <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" rel="stylesheet"></link>
)

};

declare function xmlconv:main($source_url as xs:string) {

  let $ResultTable := xmlconv:DoValidate( $source_url )

  (: failedQA are the QAs that failed(at least on error :)
  let $failedQA :=  $ResultTable/tr[td/div/@class = 'error']
  let $nameofailedQA := fn:data($failedQA/td/div)

  let $errors := if ( fn:count($nameofailedQA) > 0 ) then
      <div>
          This XML file issued crucial errors in the following checks :
          <font color="#E83131"> { fn:string-join($nameofailedQA , ' , ') } </font>
      </div>
  else
      <div> This XML file issued no crucial errors       <br/>
      </div>


  let $warningQAs :=  $ResultTable/tr[td/div/@class = 'warning']
  let $nameofwarnQA := fn:data($warningQAs/td/div)

  let $warnings := if ( fn:count($warningQAs) > 0 ) then
      <div>
          This XML file issued warnings in the following checks :
          <font color="orange"> { fn:string-join($nameofwarnQA , ' , ') } </font>
      </div>
  else
      <div> This XML file issued no warnings       <br/>
      </div>

  let $infoQA :=  $ResultTable/tr[td/div/@class = 'info']
  let $infoName := fn:data($infoQA/td/div)

  let $infos := if ( fn:count($infoQA) > 0 ) then
      <div>
          This XML file issued info for the following checks :
          <font color="blue"> { fn:string-join($infoName , ' , ')  }  </font>
      </div>
  else
      ()
  let $js := xmlconv:getJS()

  let $legend := xmlconv:getLegend()

  let $css := xmlconv:getCSS()

  let $feedbackStatus := if (fn:exists ($failedQA) ) then <div>(<level>BLOCKER</level>,<msg>{ $errors }</msg>)</div>
  else if (fn:exists ($warningQAs) )  then <div> (<level>WARNING</level>,<msg>{ $warnings }</msg>)</div>
  else <div>(<level>INFO</level>,<msg>"No errors or warnings issued"</msg>)</div>

  return
      <div class="feedbacktext">
      <span id="feedbackStatus" class="{$feedbackStatus//level}" style="display:none">
          {fn:data($feedbackStatus//msg)}
      </span>
      <h2>Reporting obligation for: E-PRTR data reporting and summary of emission inventory
          for large combustion plants (LCP), Art 4.(4) and 15.(3) plants
      </h2>
            { ( $css, $js, $errors, $warnings, $infos, $legend,  $ResultTable )}
      </div>
};

xmlconv:main($source_url)

