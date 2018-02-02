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

declare variable $source_url as xs:string external;
(: xml files paths:)

declare variable $xmlconv:BASIC_DATA_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_basicdata.xml");
declare variable $xmlconv:OLD_PLANTS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_v2_plantsdb.xml");
declare variable $xmlconv:CLRTAP_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_clrtap.xml");
declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string := ("average_emissions.xml");
declare variable $xmlconv:FINDINGS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_Findings_Step1.xml");

declare variable $xmlconv:VALID_OTHER_SECTOR as xs:string* := ("iron_steel","esi","district_heating","chp","other");
(:declare variable $eworx:SchemaModel := eworx:getSchemaModel($source_url);:)

declare function xmlconv:RowBuilder (
        $RuleCode as xs:string,
        $RuleName as xs:string,
        $ResDetails as element()*
) as element( ) *{

  let $RuleCode := substring-after($RuleCode, ' ')

    let $errors := $ResDetails/td[@class = 'error']
    let $warnings := $ResDetails/td[@class = 'warning']
    let $info := $ResDetails/td[@class = 'info']

    let $ResCode := if ( count($errors) > 0) then 'error'
    else if   ( count($warnings) > 0 ) then 'warning'
    else if   ( count($info) > 0 ) then 'info'
    else 'passed'

    (: $ResCode the result of the QA :)

    (: TESTING :)
    let $ResMessage := <p> { count($errors) } Errors, { count($warnings) } Warnings { if (count($info) > 0) then concat(' , ' ,xs:string(count($info)), ' Info' ) else () } </p>

    let $step1 :=
        (: Row Result :)
        <tr class="mainviewrow">
            <td class="bullet">
                <div class="{$ResCode}">{ $RuleCode }</div>
            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (count($ResDetails) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")' class="feedback">Show records</a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
                }
            </tr>

    let $step2 := if (count($ResDetails) > 0 ) then
        <tr style="display:none;" id="feedbackRow-{$RuleCode}">
            <td colspan="4">
                <table class="showdatatable table table-bordered" >
                    <tr>{
                        for $th in $ResDetails[1]//td return <th>{ data($th/@title) }</th>
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

  let $RuleCode := substring-after($RuleCode, ' ')

    let $errors := $ResRows/td/div[@class = 'error']
    let $warnings := $ResRows/td/div[@class = 'warning']
    let $info := $ResRows/td/div[@class = 'info']

    let $ResCode := if ( count($errors) > 0) then 'error'
    else if   ( count($warnings) > 0 ) then 'warning'
        else if   ( count($info) > 0 ) then 'info'
            else 'passed'


    (: TESTING :)
    let $ResMessage := <p> { count($errors) } Subchecks issued Errors, { count($warnings) } Subchecks issued Warnings { if (count($info) > 0) then concat(' , ' ,xs:string(count($info)), ' Info' ) else () } </p>

    let $step1 :=
        (: Row Result :)
        <tr class="detailsrow">
            <td class="bullet">

                <div class="{$ResCode}">{ $RuleCode }</div>

            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (count($ResRows) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")'>Show records</a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
            }
        </tr>

    let $step2 := if (count($ResRows) > 0 ) then
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
    let $seq := $docRoot//*[local-name() = $featureType]
    let $allInspireIds := data($seq/InspireId)
    for $elem in distinct-values($seq/InspireId)
    return
        if(count(index-of($allInspireIds, data($elem))) > 1)
        then
            <tr>
                <td class='error' title="Details">InspireId is not unique</td>
                <td class="tderror" title="InspireId"> {data($elem)} </td>
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
        let $ok := $valid = data($elem)
        return
            if (not($ok))
            then
                <tr>
                    <td class='error' title="Details"> {$concept} has not been recognised</td>
                    <td class="tderror" title="{node-name($elem)}"> {data($elem)} </td>
                    <td title="path">{functx:path-to-node($elem)}</td>
                </tr>
            else
                ()
};

declare function xmlconv:RunQAs(
        $source_url
) as element()* {

    let $docRoot := doc($source_url)

    (:  C1.1 – combustionPlantCategory consistency  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/combustionPlantCategory/combustionPlantCategory
        return xmlconv:isInVocabulary($seq, "CombustionPlantCategoryValue")
    let $LCP_1_1 := xmlconv:RowBuilder("EPRTR-LCP 1.1","combustionPlantCategory consistency", $res )

    (:  C1.2 – CountryCode consistency  :)
    let $res :=
        let $seq := $docRoot//*[local-name() = ("countryCode", "countryId")]
        return xmlconv:isInVocabulary($seq, "CountryCodeValue")
    let $LCP_1_2 := xmlconv:RowBuilder("EPRTR-LCP 1.2","CountryCode consistency", $res )

    (:  C1.3 – EPRTRPollutant consistency   :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport/*[local-name() = ("offsitePoluantTransfer", "pollutantRelease")]//pollutant
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
        let $seq := $docRoot//ProductionInstallationPartReport/energyInput/fuelInput[fuelInput = $otherGases]/otherGaseousFuel
        return xmlconv:isInVocabulary($seq, "OtherGaseousFuelValue")
    let $LCP_1_10 := xmlconv:RowBuilder("EPRTR-LCP 1.10","OtherGaseousFuelValue consistency", $res )

    (:  C1.11 – OtherSolidFuel consistency  :)
    let $res :=
        let $otherSolidFuel := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels"
        let $seq := $docRoot//ProductionInstallationPartReport/energyInput/fuelInput[fuelInput = $otherSolidFuel]/otherSolidFuel
        return xmlconv:isInVocabulary($seq, "OtherSolidFuelValue")
    let $LCP_1_11 := xmlconv:RowBuilder("EPRTR-LCP 1.11","OtherSolidFuelValue consistency", $res )

    (:  C1.12 - ReasonValue consistency :)
    let $res :=
        let $seq := $docRoot//confidentialityReason
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

    let $res := ()
    (: TODO implement this :)
    (:  C2.1 – inspireId consistency    :)
    let $LCP_2_1 := xmlconv:RowBuilder("EPRTR-LCP 2.1","inspireId consistency (NOT IMPLEMENTED)", $res)

    (: TODO implement this :)
    (:  C2.2 – Comprehensive LCP reporting    :)
    let $LCP_2_2 := xmlconv:RowBuilder("EPRTR-LCP 2.2","Comprehensive LCP reporting (NOT IMPLEMENTED)", $res)

    (:  C2.3 – ProductionFacility inspireId uniqueness    :)
    let $res := xmlconv:InspireIdUniqueness($docRoot, "ProductionFacilityReport")
    let $LCP_2_3 := xmlconv:RowBuilder("EPRTR-LCP 2.3","ProductionFacility inspireId uniqueness", $res)

    (:  C2.4 – ProductionInstallationPart inspireId uniqueness    :)
    let $res := xmlconv:InspireIdUniqueness($docRoot, "ProductionInstallationPartReport")
    let $LCP_2_4 := xmlconv:RowBuilder("EPRTR-LCP 2.4","ProductionInstallationPart inspireId uniqueness", $res)

    let $LCP_2 := xmlconv:RowAggregator(
            "EPRTR-LCP 2",
            "inspireId checks (NOT IMPLEMENTED)",
            (
                $LCP_2_1,
                $LCP_2_2,
                $LCP_2_3,
                $LCP_2_4
            )
    )

    (:  C3.1 – Pollutant reporting completeness     :)
    let $res :=
        let $pollutants := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOx",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/TSP"
        )
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        for $pollutant in $pollutants
        return
            if (count(index-of($elem/emissionsToAir/pollutant, $pollutant)) = 0)
            then
                <tr>
                    <td class='warning' title="Details"> Pollutant has not been reported</td>
                    <td class="tdwarning" title="Pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
                    <td title="localId">{$elem/descendant::*/localId}</td>
                    <td title="namespace">{$elem/descendant::*/namespace}</td>
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
            if (count(index-of($elem/energyInput/fuelInput/fuelInput, $fuel)) = 0)
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
                    true()
        return
            if(not($ok))
            then
                <tr>
                    <td class='warning' title="Details"> Other fuel has not been expanded upon under the furtherDetails attribute</td>
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
        let $ok := ($valid = data($elem/methodClassification))
        return
            if (
                not($ok)
                and
                functx:substring-after-last($elem/methodCode, "/") = ("M", "C")
            )
            then
                <tr>
                    <td class='warning' title="Details"> {$concept} has not been recognised</td>
                    <td class="tdwarning" title="{node-name($elem/methodClassification)}"> {data($elem/methodClassification)} </td>
                    <td title="methodCode">{functx:substring-after-last($elem/methodCode, "/")}</td>
                    <td title="path">{functx:path-to-node($elem/methodClassification)}</td>
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
                    <td class='warning' title="Details"> Not met reporting requirements for the method classification</td>
                    <td class="tdwarning" title="furtherDetails"> {data($elem/furtherDetails)} </td>
                    <td title="methodClassifications">{$elem/methodClassification}</td>
                    <td title="path">{functx:path-to-node($elem/methodClassification)}</td>
                </tr>
            else
                ()
    let $LCP_3_5 := xmlconv:RowBuilder("EPRTR-LCP 3.5","Required furtherDetails for reporting methodClassification", $res)

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
        let $seq := $docRoot//offsiteWasteTransfer
        for $elem in $seq
        for $attr in $attributesToVerify
        for $el in $elem//*[local-name() = $attr]
        return
            if(functx:if-empty($el, "") = "")
            then
                <tr>
                    <td class='warning' title="Details"> Attribute should contain a character string</td>
                    <td title="attribute"> {$attr} </td>
                    <td class="tdwarning" title="Value"> {data($el)} </td>
                    <td title="localId">{$el/ancestor::*/ProductionFacilityReport/InspireId/localId}</td>
                    <td title="namespace">{$el/ancestor::*/ProductionFacilityReport/InspireId/namespace}</td>
                    <td title="path">{functx:path-to-node($el)}</td>
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

    (: TODO implement this :)
    (:  C4.1 – ReportingYear plausibility   :)
    let $res := ()
    let $LCP_4_1 := xmlconv:RowBuilder("EPRTR-LCP 4.1","ReportingYear plausibility (NOT IMPLEMENTED)", $res)

    (:  C4.2 – accidentalPollutantQuantityKg plausibility   :)
    let $res :=
        let $seq := $docRoot//pollutantRelease
        for $elem in $seq
        let $ok := (
            $elem/totalPollutantQuantityKg >= $elem/accidentalPollutantQuantityKg
            and
            $elem/totalPollutantQuantityKg castable as xs:double
            and
            $elem/accidentalPollutantQuantityKg castable as xs:double
        )
        return
            if(not($ok))
            then
                <tr>
                    <td class='warning' title="Details"> accidentalPollutantQuantityKg attribute value is not valid</td>
                    <td class="tdwarning" title="accidentalPollutantQuantityKg"> {data($elem/accidentalPollutantQuantityKg)} </td>
                    <td title="totalPollutantQuantityKg"> {data($elem/totalPollutantQuantityKg)} </td>
                    <td title="localId">{$elem/ancestor::*/ProductionFacilityReport/InspireId/localId}</td>
                    <td title="namespace">{$elem/ancestor::*/ProductionFacilityReport/InspireId/namespace}</td>
                </tr>
            else
                ()

    let $LCP_4_2 := xmlconv:RowBuilder("EPRTR-LCP 4.2","accidentalPollutantQuantityKg plausibility", $res)

    (: C4.3 – CO2 reporting plausibility :)
    let $res :=
        let $co2 := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CO2"
        let $co2exclBiomass := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/CO2%20EXCL%20BIOMASS"
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $co2_amount := functx:if-empty($elem//pollutantRelease[pollutant = $co2]/totalPollutantQuantityKg, 0)
            let $co2exclBiomass_amount := functx:if-empty($elem//pollutantRelease[pollutant = $co2exclBiomass]/totalPollutantQuantityKg, 0)
            let $ok := (
                $co2_amount >= $co2exclBiomass_amount
                and
                $co2_amount castable as xs:double
                and
                $co2exclBiomass_amount castable as xs:double
            )
        return
            if(not($ok))
                then
                <tr>
                    <td class='warning' title="Details">Reported CO2 excluding biomass exceeds reported CO2 emissions</td>
                    <td class="tdwarning" title="CO2 excluding biomass"> {data($co2exclBiomass_amount)} </td>
                    <td title="CO2"> {data($co2_amount)} </td>
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
            if(count(index-of($fuels, $fuel)) > 1)
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

    (: TODO implement this :)
    (:  C.5.2 – Identification of otherSolidFuel duplicates   :)
    let $res := ()
    let $LCP_5_2 := xmlconv:RowBuilder("EPRTR-LCP 5.2","Identification of otherSolidFuel duplicates (NOT IMPLEMENTED)", $res)

    (: TODO implement this :)
    (:  C.5.3 – Identification of otherGaseousFuel duplicates   :)
    let $res := ()
    let $LCP_5_3 := xmlconv:RowBuilder("EPRTR-LCP 5.3","Identification of otherGaseousFuel duplicates (NOT IMPLEMENTED)", $res)

    (:  C5.4 - Identification of EmissionsToAir duplicates  :)
    let $res :=
        let $pollutantValues := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/TSP",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOx",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2"
        )
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
            let $pollutants := $elem/emissionsToAir/pollutant
            for $pollutant in $pollutantValues
                return
                if(count(index-of($pollutants, $pollutant)) > 1)
                then
                    <tr>
                        <td class='error' title="Details">Pollutant is duplicated within the EmissionsToAir feature type</td>
                        <td class="tderror" title="pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
                        <td title="localId">{$elem/descendant-or-self::*/InspireId/localId}</td>
                        <td title="namespace">{$elem/descendant-or-self::*/InspireId/namespace}</td>
                    </tr>
                else
                    ()
    let $LCP_5_4 := xmlconv:RowBuilder("EPRTR-LCP 5.4","Identification of EmissionsToAir duplicates", $res)

    (: TODO remove duplicates from output :)
    (:  C.5.5 – Identification of PollutantRelease duplicates  :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $values :=
                for $el in $elem/pollutantRelease
                return
                    $el/mediumCode || $el/pollutant
            for $el in $elem/pollutantRelease
            let $value := $el/mediumCode || $el/pollutant
            return
                if(
                    count(index-of($values, $value)) > 1
                )
                then
                    <tr>
                        <td class='error' title="Details">Pollutant and medium pair is duplicated within the PollutantRelease feature type</td>
                        <td class="tderror" title="mediumCode"> {functx:substring-after-last($el/mediumCode, "/")} </td>
                        <td class="tderror" title="pollutant"> {functx:substring-after-last($el/pollutant, "/")} </td>
                        <td title="localId">{$el/ancestor-or-self::*/ProductionFacilityReport/InspireId/localId}</td>
                        <td title="namespace">{$el/ancestor-or-self::*/ProductionFacilityReport/InspireId/namespace}</td>
                    </tr>
                else
                    ()
    let $LCP_5_5 := xmlconv:RowBuilder("EPRTR-LCP 5.5","Identification of PollutantRelease duplicates", $res)

    (:  C.5.6 – Identification of OffsitePollutantTransfer duplicates  :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
            let $allPollutants := $elem/offsitePoluantTransfer/pollutant
            for $el in distinct-values($elem/offsitePoluantTransfer/pollutant)
            let $ok := count(index-of($allPollutants, $el)) = 1
            return
                if(not($ok))
                    then
                        <tr>
                            <td class='warning' title="Details">Pollutant is duplicated within the OffsitePollutantTransfer feature type</td>
                            <td class="tdwarning" title="pollutant"> {functx:substring-after-last($el, "/")} </td>
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
            for $el in distinct-values($elem/desulphurisationInformation/month)
            let $ok := count(index-of($allMonths, $el)) = 1
            return
                if(not($ok))
                    then
                        <tr>
                            <td class='warning' title="Details">Month is duplicated within the DesulphurisationInformationType feature type</td>
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

    let $res := ()
    (: TODO implement this :)
    (:  C6.1 – Individual EmissionsToAir feasibility    :)
    let $LCP_6_1 := xmlconv:RowBuilder("EPRTR-LCP 6.1","Individual EmissionsToAir feasibility (NOT IMPLEMENTED)", $res)

    (: TODO implement this :)
    (: C6.2 – Cumulative EmissionsToAir feasibility :)
    let $LCP_6_2 := xmlconv:RowBuilder("EPRTR-LCP 6.2","Cumulative EmissionsToAir feasibility (NOT IMPLEMENTED)", $res)

    let $LCP_6 := xmlconv:RowAggregator(
            "EPRTR-LCP 6",
            "LCP and E-PRTR facility interrelation checks (NOT IMPLEMENTED)",
            (
                $LCP_6_1,
                $LCP_6_2
            )
    )

    let $res := ()
    (: TODO implement this :)
    (:  C7.1 – EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility     :)
    let $LCP_7_1 := xmlconv:RowBuilder("EPRTR-LCP 7.1","EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility (NOT IMPLEMENTED)", $res)

    (: C7.2 – MethodClassification validity  :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport/*[local-name() = ("offsitePoluantTransfer", "pollutantRelease")]/method/methodClassification
        for $elem in $seq
            return
                if($elem = "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MethodClassificationValue/WEIGH")
                then
                    <tr>
                        <td class='info' title="Details">Attribute is incorrectly populated with WEIGH</td>
                        <td class="tdinfo" title="feature type"> {node-name($elem/../..)} </td>
                        <td class="tdinfo" title="methodClassification"> {$elem} </td>
                        <td title="localId">{$elem/ancestor-or-self::*/ProductionFacilityReport/InspireId/localId}</td>
                        <td title="namespace">{$elem/ancestor-or-self::*/ProductionFacilityReport/InspireId/namespace}</td>
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
    let $res := ()
    (: TODO implement this :)
    (:   C8.1 – Article 31 derogation compliance   :)
    let $LCP_8_1 := xmlconv:RowBuilder("EPRTR-LCP 8.1","Article 31 derogation compliance (NOT IMPLEMENTED)", $res)
    (: TODO implement this :)
    (:  C8.2 – Article 31 derogation justification  :)
    let $LCP_8_2 := xmlconv:RowBuilder("EPRTR-LCP 8.2","Article 31 derogation justification (NOT IMPLEMENTED)", $res)
    (: TODO implement this :)
    (:  C8.3 – Article 35 derogation and proportionOfUsefulHeatProductionForDistrictHeating comparison  :)
    let $LCP_8_3 := xmlconv:RowBuilder("EPRTR-LCP 8.3","Article 35 derogation and proportionOfUsefulHeatProductionForDistrictHeating comparison (NOT IMPLEMENTED)", $res)

    let $LCP_8 := xmlconv:RowAggregator(
            "EPRTR-LCP 8",
            "Derogation checks (NOT IMPLEMENTED)",
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
            "offsitePoluantTransfer",
            "pollutantRelease"
        )
        let $seq := $docRoot/descendant::*[local-name() = $featureTypes]
        let $countCondifentialityReasons :=
            for $elem in $seq/child::*[local-name() = "confidentialityReason"]
            return $elem
        let $ratio := count($countCondifentialityReasons) div count($seq)
        let $errorType :=
            if($ratio > 0.01)
            then
                "error"
            else if($ratio > 0.005)
                then
                "warning"
            else
                "info"
        let $errorMessage :=
            if($ratio > 0.01)
            then
                "confidentialityReason attribute exceeded the 1% threshold"
            else if($ratio > 0.005)
                then
                "confidentialityReason attribute exceeded the 0.5% threshold, but the value is less than 1%"
            else "all good"
        return
            if($ratio > 0.005)
            then
                <tr>
                    <td class='{$errorType}' title="Details">{$errorMessage}</td>
                    <td class="td{$errorType}" title="threshold"> {round-half-to-even($ratio * 100, 1) || '%'} </td>
                </tr>
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

    (:  C10.1 – EmissionsToAir outlier identification   :)
    let $res :=
        let $seq:= $docRoot//ProductionInstallationPartReport
        let $docEmissions := doc($xmlconv:AVG_EMISSIONS_PATH)
        let $emissions := distinct-values($seq/emissionsToAir/functx:substring-after-last(pollutant, "/"))
        for $elem in $seq
            for $emission in $emissions
                let $emissionTotal := functx:if-empty($elem/emissionsToAir[functx:substring-after-last(pollutant, "/") = $emission]/totalPollutantQuantityTNE, 0)
                let $expected := sum(
                    for $pollutant in $elem/energyInput
                    let $emissionFactor := $docEmissions//emission[functx:substring-after-last($pollutant/fuelInput/fuelInput, "/") = fuelInput]/*[local-name() = $emission]
                    return $pollutant/energyinputTJ * $emissionFactor
                )
                let $emissionConstant := if($emission = "NOx") then 1 div 10 else 1 div 100
                where $expected > 0
                return
                    if(
                        $emissionTotal div $expected > 20
                        or
                        $emissionTotal div $expected < $emissionConstant
                    )
                    then
                        <tr>
                            <td class="info" title="Details">Reported emissions deviate from expected quantities</td>
                            <td title="inspireId">{data($elem/InspireId)}</td>
                            <td title="fuelInput">{$emission}</td>
                            <td title="total reported">{$emissionTotal}</td>
                            <td class="tdinfo" title="expected">{$expected}</td>
                        </tr>
                    else
                        ()
    let $LCP_10_1 := xmlconv:RowBuilder("EPRTR-LCP 10.1","EmissionsToAir outlier identification", $res)
    (: TODO not implemented :)
    (:  C10.2 – Energy input and CO2 emissions feasibility  :)
    let $res := ()
    let $LCP_10_2 := xmlconv:RowBuilder("EPRTR-LCP 10.2","Energy input and CO2 emissions feasibility (NOT IMPLEMENTED)", $res)
    (: TODO not implemented :)
    (:  C10.3 – ProductionFacility cross pollutant identification   :)
    let $LCP_10_3 := xmlconv:RowBuilder("EPRTR-LCP 10.3","ProductionFacility cross pollutant identification (NOT IMPLEMENTED)", $res)

    let $LCP_10 := xmlconv:RowAggregator(
            "EPRTR-LCP 10",
            "Expected pollutant identification",
            (
                $LCP_10_1,
                $LCP_10_2,
                $LCP_10_3
            )
    )

    (:  C11.1 - ProductionFacilityReports without transfers or releases :)
    let $res :=
        let $attributes := (
            "offsiteWasteTransfer",
            "offsitePoluantTransfer",
            "pollutantRelease"
        )
        let $seq := $docRoot//ProductionFacilityReport
        for $elem in $seq
        let $elems := $elem/*[local-name() = $attributes]
        return
            if(empty($elems))
            then
                <tr>
                    <td class='info' title="Details">No releases/transfers of pollutants nor transfers of waste have been reported</td>
                    <td class="tdinfo" title="localId">{$elem/ancestor-or-self::*[local-name() = ("ProductionFacilityReport")]/InspireId/localId}</td>
                    <td class="tdinfo" title="namespace">{$elem/ancestor-or-self::*[local-name() = ("ProductionFacilityReport")]/InspireId/namespace}</td>
                </tr>
            else
                ()
    let $LCP_11_1 := xmlconv:RowBuilder("EPRTR-LCP 11.1","ProductionFacilityReports without transfers or releases", $res)

    let $res := ()
    (: TODO not implemented :)
    (:  C11.2 - ProductionFacility releases and transfers reported below the thresholds :)
    let $LCP_11_2 := xmlconv:RowBuilder("EPRTR-LCP 11.2","ProductionFacility releases and transfers reported below the thresholds (NOT IMPLEMENTED)", $res)

    let $LCP_11 := xmlconv:RowAggregator(
            "EPRTR-LCP 11",
            "ProductionFacility voluntary reporting checks",
            (
                $LCP_11_1,
                $LCP_11_2
            )
    )

    let $res := ()
    (: TODO not implemented :)
    (: C12.1 - Identification of ProductionFacility release/transfer outliers against previous year data at the national level :)
    let $LCP_12_1 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.1",
            "Identification of ProductionFacility release/transfer outliers against previous year data at the national level",
            $res
    )
    (: TODO not implemented :)
    (: C12.2 - Identification of ProductionFacility release/transfer outliers against national total and pollutant threshold :)
    let $LCP_12_2 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.2",
            "Identification of ProductionFacility release/transfer outliers against national total and pollutant threshold",
            $res
    )
    (: TODO not implemented :)
    (: C12.3 - Identification of ProductionFacility release/transfer outliers against previous year data :)
    let $LCP_12_3 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.3",
            "Identification of ProductionFacility release/transfer outliers against previous year data at the ProductionFacility level",
            $res
    )
    (: TODO not implemented :)
    (: C12.4 - Time series consistency for ProductionFacility emissions :)
    let $LCP_12_4 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.4",
            "Identification of ProductionInstallationPart emission outliers against
            previous year data at the ProductionInstallationPart level"
            , $res
    )
    (: TODO not implemented :)
    (: C12.5 – Time series consistency for ProductionInstallationPart emissions :)
    let $LCP_12_5 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.5",
            "Time series consistency for ProductionFacility emissions",
            $res
    )
    (: TODO not implemented :)
    (: C12.6 - Time series consistency for ProductionInstallationPart emissions :)
    let $LCP_12_6 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.6",
            "Time series consistency for ProductionInstallationPart emissions",
            $res
    )

    let $LCP_12 := xmlconv:RowAggregator(
            "EPRTR-LCP 12",
            "Identification of release and transfer outliers (NOT IMPLEMENTED)",
            (
                $LCP_12_1,
                $LCP_12_2,
                $LCP_12_3,
                $LCP_12_4,
                $LCP_12_5,
                $LCP_12_6
            )
    )

    let $res := ()
    (: TODO not implemented :)
    (: C13.1 - C13.1 - Number of ProductionFacilities reporting releases and transfers consistency :)
    let $LCP_13_1 := xmlconv:RowBuilder("EPRTR-LCP 13.1","Number of ProductionFacilities reporting releases and transfers consistency", $res)

    (: TODO not implemented :)
    (: C13.2 - Reported number of releases and transfers per medium consistency :)
    let $LCP_13_2 := xmlconv:RowBuilder("EPRTR-LCP 13.2","Reported number of releases and transfers per medium consistency", $res)

    (: TODO not implemented :)
    (: C13.3 - Reported number of pollutants per medium consistency :)
    let $LCP_13_3 := xmlconv:RowBuilder("EPRTR-LCP 13.3","Reported number of pollutants per medium consistency", $res)

    (: TODO not implemented :)
    (: C13.4 - Quantity of releases and transfers consistency :)
    let $LCP_13_4 := xmlconv:RowBuilder("EPRTR-LCP 13.4","Quantity of releases and transfers consistency", $res)

    let $LCP_13 := xmlconv:RowAggregator(
            "EPRTR-LCP 13",
            "Overview on inter-annual reporting consistency (NOT IMPLEMENTED)",
            (
                $LCP_13_1,
                $LCP_13_2,
                $LCP_13_3,
                $LCP_13_4
            )
    )

    let $res := ()
    (: TODO not implemented :)
    (: C14.1 – Identification of top 10 ProductionFacility releases/transfers across Europe :)
    let $LCP_14_1 := xmlconv:RowBuilder("EPRTR-LCP 14.1","Identification of top 10 ProductionFacility releases/transfers across Europe", $res)

    (: TODO not implemented :)
    (: C14.2 – Identification of ProductionFacility release/transfer outliers against European level data :)
    let $LCP_14_2 := xmlconv:RowBuilder("EPRTR-LCP 14.2","Identification of ProductionFacility release/transfer outliers against European level data", $res)

    let $LCP_14 := xmlconv:RowAggregator(
            "EPRTR-LCP 14",
            "Verification of emissions against European level data (NOT IMPLEMENTED)",
            (
                $LCP_14_1,
                $LCP_14_2
            )
    )

    (: TODO not implemented :)
    (:  C15.1 – Comparison of PollutantReleases and EmissionsToAir to CLRTAP/NECD and UNFCCC/EU-MMR National Inventories    :)
    let $res := ()
    let $LCP_15_1 := xmlconv:RowBuilder("EPRTR-LCP 15.1","Comparison of PollutantReleases and EmissionsToAir to CLRTAP/NECD and UNFCCC/EU-MMR National Inventories", $res)

    let $LCP_15 := xmlconv:RowAggregator(
        "EPRTR-LCP 15",
        "Verification of national emissions against external datasets (NOT IMPLEMENTED)",
        (
            $LCP_15_1
        )
    )
    (:  C16.1 - Significant figure format compliance    :)
    let $res :=
        let $attributes := (
            "totalWasteQuantityTNE",
            "totalPollutantQuantityKg",
            "totalPollutantQuantityTNE"
        )
        let $seq := $docRoot//*[local-name() = $attributes]
        for $elem in $seq
        let $ok := (
            $elem castable as xs:double
            and
            string-length(substring-after($elem, '.') ) <= 3
        )
        return
            if(not($ok))
            then
                <tr>
                    <td class='warning' title="Details">Numerical format reporting requirements not met</td>
                    <td class="tdwarning" title="attribute name"> {node-name($elem)} </td>
                    <td class="tdwarning" title="value"> {data($elem)} </td>
                    <td title="localId">{$elem/ancestor-or-self::*[local-name() = ("ProductionInstallationPartReport", "ProductionFacilityReport")]/InspireId/localId}</td>
                    <td title="namespace">{$elem/ancestor-or-self::*[local-name() = ("ProductionInstallationPartReport", "ProductionFacilityReport")]/InspireId/namespace}</td>
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
        let $seq := $docRoot//ProductionInstallationPartReport//*[local-name() = $attributes]
        for $elem in $seq
        let $ok := (
            $elem castable as xs:double
            and
            $elem <= 1
        )
        return
            if(not($ok))
            then
                <tr>
                    <td class='warning' title="Details">Attribute has been populated with a value representing a percentage greater than 100%</td>
                    <td class="tdwarning" title="attribute name"> {node-name($elem)} </td>
                    <td class="tdwarning" title="value"> {data($elem)} </td>
                    <td title="localId">{$elem/ancestor-or-self::*[local-name() = ("ProductionInstallationPartReport")]/InspireId/localId}</td>
                    <td title="namespace">{$elem/ancestor-or-self::*[local-name() = ("ProductionInstallationPartReport")]/InspireId/namespace}</td>
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

    let $res := for $attr in doc($source_url)//Plant/descendant::*
    where  eworx:testBasicElementType($attr, $source_url) = "false"
    return <tr>
        <td class='error' title="Details"> Invalid input value on the field <b> { name($attr) } </b></td>
        <td title="PlantId">{ data   (($attr)/ancestor::*/PlantId ) }</td>
        <td class="tderror" title="Invalid value">{ data ( $attr ) }</td>
        <td title="xml path">{ functx:path-to-node (($attr) ) }</td>

    </tr>

    return
        if (exists($res )) then
            xmlconv:RowBuilder("LCP XML", "XML Document Validity Errors. QAs did not run", $res)
        else ()


} ;

declare function xmlconv:DoValidate(
        $source_url as xs:string
) as element(table){

    let $res :=
    if ( exists(eworx:testDocumentBasicTypes($source_url))) then
        eworx:testDocumentBasicTypes($source_url)
    else
        xmlconv:RunQAs($source_url)

    return   <table class="table table-bordered table-condensed" id="maintable">
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
        <script type="text/javascript">{normalize-space($js)}</script>
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
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="error">Red</div></div> - the check issued an error. Please correct the invalid records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="warning">Orange</div></div> - the check issued a warning. Please review the corresponding records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="info">Blue</div></div> - the check issued info. Please review the corresponding records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="passed">Green</div></div> - the check passed without errors or warnings.</li>
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
  let $nameofailedQA := data($failedQA/td/div)

  let $errors := if ( count($nameofailedQA) > 0 ) then
      <div> This XML file issued crucial errors in the following checks : <font color="#E83131"> { fn:string-join($nameofailedQA , ' , ') } </font>

      </div>
  else
      <div> This XML file issued no crucial errors       <br/>
      </div>


  let $warningQAs :=  $ResultTable/tr[td/div/@class = 'warning']
  let $nameofwarnQA := data($warningQAs/td/div)

  let $warnings := if ( count($warningQAs) > 0 ) then
      <div> This XML file issued warnings in the following checks : <font color="orange"> { fn:string-join($nameofwarnQA , ' , ') } </font>

      </div>
  else
      <div> This XML file issued no warnings       <br/>
      </div>

  let $infoQA :=  $ResultTable/tr[td/div/@class = 'info']
  let $infoName := data($infoQA/td/div)

  let $infos := if ( count($infoQA) > 0 ) then
      <div> This XML file issued info for the following checks : <font color="blue"> { fn:string-join($infoName , ' , ')  }  </font>

      </div>
  else
      ()
  let $js := xmlconv:getJS()

  let $legend := xmlconv:getLegend()

  let $css := xmlconv:getCSS()

  let $feedbackStatus := if (exists ($failedQA) ) then <div>(<level>BLOCKER</level>,<msg>{ $errors }</msg>)</div>
  else if (exists ($warningQAs) )  then <div> (<level>WARNING</level>,<msg>{ $warnings }</msg>)</div>
  else <div>(<level>INFO</level>,<msg>"No errors or warnings issued"</msg>)</div>



  (::)
  return
      <div class="feedbacktext">
      <span id="feedbackStatus" class="{$feedbackStatus//level}" style="display:none">{data($feedbackStatus//msg)}</span>
          <h2>Reporting obligation for: Summary of emission inventory for large combustion plants (LCP), Art 4.(4) and 15.(3) plants
      </h2>

            { ( $css, $js, $errors, $warnings, $infos, $legend,  $ResultTable )}

      </div>



};

xmlconv:main($source_url)
