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

(:
\(\: (let \$asd \:\= trace\(fn\:current\-time\(\)\, \'started\s*[\d\.]+\sat\: \'\)) \:\)
:)

declare function xmlconv:getLookupTable(
    $fileName as xs:string
) as element() {
    let $obligation := '720'
    (:let $location := 'http://10.50.4.41:5000/remote.php/dav/files/':)
    let $location := 'https://databridge.eionet.europa.eu/remote.php/dav/files/'
    let $userEnv := 'XQueryUser'
    let $passwordEnv := 'XQueryPassword'

    let $user := environment-variable($userEnv)
    let $password := environment-variable($passwordEnv)
    let $url := concat($location, $user, '/', $obligation, '/', $fileName)

    (:let $asd:= trace($url, 'Getting file: '):)
    let $response := http:send-request(
            <http:request method='get'
                auth-method='Basic'
                send-authorization='true'
                username='{$user}'
                password='{$password}'
                override-media-type='text/xml'/>,
            $url
    )
    let $status_code := $response/@status
    (:let $asd:= trace($url, 'Finished: '):)
    (:let $asd:= trace($status_code, ''):)

    return if($status_code = 200)
        then $response[2]/dataroot
        else <dataroot></dataroot>
};

declare function xmlconv:getLookupTableCountry(
    $countryCode as xs:string,
    $fileName as xs:string
) as element() {
    let $obligation := '720'
    let $location := 'https://databridge.eionet.europa.eu/remote.php/dav/files/'
    let $userEnv := 'XQueryUser'
    let $passwordEnv := 'XQueryPassword'

    let $user := environment-variable($userEnv)
    let $password := environment-variable($passwordEnv)
    let $fileName := concat($countryCode, '_', $fileName)
    let $url := concat($location, $user, '/', $obligation, '/', $fileName)

    let $response := http:send-request(
            <http:request method='get'
                auth-method='Basic'
                send-authorization='true'
                username='{$user}'
                password='{$password}'
                override-media-type='text/xml'/>,
            $url
    )

    let $status_code := $response/@status

    return if($status_code = 200)
        then $response[2]/data
        else <data></data>
};

declare function xmlconv:getLookupTableSVN(
    $fileName as xs:string
) as element() {
    let $location := '../lookup-tables/'
    (:let $location := 'https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/E-PRTR_and_LCP_integration/lookup-tables/':)
    let $url := concat($location, $fileName)

    return fn:doc($url)/dataroot
};

declare function xmlconv:getLookupTableSVNCountry(
    $countryCode as xs:string,
    $fileName as xs:string
) as element()? {
    let $fileName := concat($countryCode, '_', $fileName)

    let $location := '../lookup-tables/'
    (:let $location := 'https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/E-PRTR_and_LCP_integration/lookup-tables/':)
    let $url := concat($location, $fileName)

    return fn:doc($url)/data
};

declare variable $xmlconv:REPOSITORY_URL as xs:string := "";
declare variable $xmlconv:PRODUCTION_FACILITY_LOOKUP as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR_LCP_ProductionFacility.xml");
declare variable $xmlconv:PRODUCTION_INSTALLATIONPART_LOOKUP as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR_LCP_ProductionInstallationPart.xml");
declare variable $xmlconv:POLLUTANT_LOOKUP as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_PollutantLookup.xml");
declare variable $xmlconv:CrossPollutants as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C10.3_CrossPollutants.xml");
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C12.1_OffsiteWasteTransfer.xml");
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C12.1_PollutantTransfer.xml");
declare variable $xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantRelease as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C12.1_PollutantRelease.xml");
declare variable $xmlconv:ANNEX_II_THRESHOLD as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C12.2_ThreshholdLookup.xml");
declare variable $xmlconv:QUANTITY_OF_PollutantRelease as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.4_PollutantRelease.xml");
declare variable $xmlconv:QUANTITY_OF_PollutantTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.4_PollutantTransfer.xml");
declare variable $xmlconv:QUANTITY_OF_OffsiteWasteTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.4_OffsiteWasteTransfer.xml");
declare variable $xmlconv:EUROPEAN_TOTAL_PollutantRelease as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C14.2_PollutantRelease.xml");
declare variable $xmlconv:EUROPEAN_TOTAL_PollutantTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C14.2_PollutantTransfer.xml");
declare variable $xmlconv:EUROPEAN_TOTAL_OffsiteWasteTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C14.2_OffsiteWasteTransfer.xml");
declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C10.1-C10.2_EFLookup.xml");
declare variable $xmlconv:COUNT_OF_PROD_FACILITY_WASTE_TRANSFER as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.1_OffsiteWasteTransfer.xml");
declare variable $xmlconv:AVERAGE_3_YEARS as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C12.6.xml");
declare variable $xmlconv:CLRTAP_DATA as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C15.1_CLRTAP_data.xml");
declare variable $xmlconv:CLRTAP_POLLUTANT_LOOKUP as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C15.1_CLRTAP_pollutant_lookup.xml");
declare variable $xmlconv:UNFCC_DATA as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C15.1_UNFCCC_data.xml");
declare variable $xmlconv:UNFCC_POLLUTANT_LOOKUP as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C15.1_UNFCCC_pollutant_lookup.xml");
declare variable $xmlconv:COUNT_OF_PollutantRelease as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.1-C13.2-C13.3_PollutantRelease.xml");
declare variable $xmlconv:COUNT_OF_PollutantTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.1-C13.2-C13.3_PollutantTransfer.xml");
declare variable $xmlconv:COUNT_OF_OffsiteWasteTransfer as xs:string :=
    fn:concat($xmlconv:REPOSITORY_URL,"EPRTR-LCP_C13.2_OffsiteWasteTransfer.xml");

declare variable $xmlconv:resultsLimit as xs:integer := 1000;

(:declare variable $eworx:SchemaModel := eworx:getSchemaModel($source_url);:)

declare function xmlconv:RowBuilder (
        $RuleCode as xs:string,
        $RuleName as xs:string,
        $ResDetails as element()*
) as element( ) *{
    let $RuleCode := fn:substring-after($RuleCode, ' ')
    let $asd:= trace($RuleCode, '')
    let $ResDetails := fn:subsequence($ResDetails, 1, $xmlconv:resultsLimit)

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
    for $elem in $seq/InspireId
    return
        if(fn:count(fn:index-of($allInspireIds, fn:data($elem))) > 1)
        (:if(fn:true()):)
        then
            <tr>
                <td class='error' title="Details">InspireId is not unique</td>
                <td class="tderror" title="Inspire Id"> {scripts:prettyFormatInspireId($elem)}</td>
            </tr>
        else
            ()
};

declare function xmlconv:isInVocabulary(
        $seq as element()*,
        $concept as xs:string,
        $flagBlanks as xs:string
) as element()*{
    let $valid := scripts:getValidConcepts($concept)
        for $elem in $seq
        let $ok := (
            $valid = fn:data($elem)
            or
            (
            if($flagBlanks = 'true')
            then false()
            else fn:string-length(fn:data($elem)) = 0
            )
        )
        return
            if (fn:not($ok))
            then
                <tr>
                    <td class='error' title="Details"> {$concept} has not been recognised</td>
                    <td title='Inspire Id'>{$elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)}</td>
                    <td title='Feature type'>{$elem/parent::*/local-name()}</td>
                    <td class="tderror" title="{fn:node-name($elem)}">
                        {fn:data($elem) => functx:substring-after-last("/")}
                    </td>
                </tr>
            else
                ()
};

declare function xmlconv:checkBlankValues(
        $seq as element()*,
        $elementName as xs:string
) as element()*{
    let $errorType := 'error'
    let $text := 'Blank value reported'

    for $elem in $seq
    let $elementValue := $elem/*[local-name() = $elementName] => functx:if-empty('')
    let $ok := not($elementValue = '')

    return
        if (fn:not($ok))
        then
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'Inspire Id': map {'pos': 2, 'text': $elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)},
                'Additional info': map {'pos': 3, 'text': scripts:getAdditionalInformation($elem)},
                'Field name': map {
                    'pos': 4,
                    'text': concat($elem/local-name(), '/', $elementName),
                    'errorClass': 'td' || $errorType
                }
            }
            return scripts:generateResultTableRow($dataMap)
        else
            ()
};

declare function xmlconv:checkAllBlankValues(
        $seq as element()*
) as element()*{
    let $errorType := 'warning'
    let $text := 'Blank value reported'
    let $regex := '[0-9a-zA-Z]'

    for $elem in $seq
    let $value := $elem/functx:if-empty(data(), '')

    let $ok := fn:matches($value, $regex)

    return
        if (fn:not($ok))
        then
            let $dataMap := map {
                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                'Inspire Id': map {'pos': 2, 'text': $elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)},
                'path': map {'pos': 3, 'text': functx:path-to-node($elem)},
                'Element name': map {'pos': 4, 'text': $elem/local-name()},
                'Value': map {'pos': 5, 'text': $value, 'errorClass': 'td' || $errorType}
            }
            return scripts:generateResultTableRow($dataMap)
        else
            ()
};

declare function xmlconv:RunQAs(
        $source_url
) as element()* {
    let $skip_countries := ('SE')
    let $docRoot := fn:doc($source_url)
    let $country_code := $docRoot//countryId/fn:data() => functx:substring-after-last("/")
        => functx:if-empty(' ')

    let $docPollutantLookup := xmlconv:getLookupTable($xmlconv:POLLUTANT_LOOKUP)
    let $docAverage := xmlconv:getLookupTable($xmlconv:AVERAGE_3_YEARS)
    let $docEmissions := xmlconv:getLookupTable($xmlconv:AVG_EMISSIONS_PATH)
    let $docCrossPollutants := xmlconv:getLookupTable($xmlconv:CrossPollutants)
    let $docANNEXII := xmlconv:getLookupTable($xmlconv:ANNEX_II_THRESHOLD)
    let $docEUROPEAN_TOTAL_PollutantRelease := xmlconv:getLookupTable($xmlconv:EUROPEAN_TOTAL_PollutantRelease)
    let $docEUROPEAN_TOTAL_PollutantTransfer := xmlconv:getLookupTable($xmlconv:EUROPEAN_TOTAL_PollutantTransfer)
    let $docEUROPEAN_TOTAL_OffsiteWasteTransfer := xmlconv:getLookupTable($xmlconv:EUROPEAN_TOTAL_OffsiteWasteTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer := xmlconv:getLookupTable($xmlconv:NATIONAL_TOTAL_ANNEXI_OffsiteWasteTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_PollutantTransfer := xmlconv:getLookupTable($xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantTransfer)
    let $docNATIONAL_TOTAL_ANNEXI_PollutantRelease := xmlconv:getLookupTable($xmlconv:NATIONAL_TOTAL_ANNEXI_PollutantRelease)
    let $docQUANTITY_OF_OffsiteWasteTransfer := xmlconv:getLookupTable($xmlconv:QUANTITY_OF_OffsiteWasteTransfer)
    let $docQUANTITY_OF_PollutantRelease := xmlconv:getLookupTable($xmlconv:QUANTITY_OF_PollutantRelease)
    let $docQUANTITY_OF_PollutantTransfer := xmlconv:getLookupTable($xmlconv:QUANTITY_OF_PollutantTransfer)
    let $docRootCOUNT_OF_PollutantRelease := xmlconv:getLookupTable($xmlconv:COUNT_OF_PollutantRelease)
    let $docRootCOUNT_OF_PollutantTransfer := xmlconv:getLookupTable($xmlconv:COUNT_OF_PollutantTransfer)
    let $docRootCOUNT_OF_ProdFacilityOffsiteWasteTransfer := xmlconv:getLookupTable($xmlconv:COUNT_OF_PROD_FACILITY_WASTE_TRANSFER)
    let $docRootCOUNT_OF_OffsiteWasteTransfer := xmlconv:getLookupTable($xmlconv:COUNT_OF_OffsiteWasteTransfer)

    let $docCLRTAPdata := xmlconv:getLookupTable($xmlconv:CLRTAP_DATA)
    let $docCLRTAPpollutantLookup := xmlconv:getLookupTable($xmlconv:CLRTAP_POLLUTANT_LOOKUP)
    let $docUNFCCdata := xmlconv:getLookupTable($xmlconv:UNFCC_DATA)
    let $docUNFCCpollutantLookup := xmlconv:getLookupTable($xmlconv:UNFCC_POLLUTANT_LOOKUP)

    let $docProductionFacilities := xmlconv:getLookupTableCountry($country_code, $xmlconv:PRODUCTION_FACILITY_LOOKUP)
    let $docProductionInstallationParts := xmlconv:getLookupTableCountry($country_code, $xmlconv:PRODUCTION_INSTALLATIONPART_LOOKUP)

    let $look-up-year := $docRoot//reportingYear => fn:number() - 2
    let $previous-year := $docRoot//reportingYear => fn:number() - 1
    let $reporting-year := $docRoot//reportingYear => fn:number()
    let $pollutantCodes := $docPollutantLookup//row/PollutantCode/text() => fn:distinct-values()

    (: Variables containing valid codes :)
    let $validPollutants := scripts:getValidConcepts('EPRTRPollutantCodeValue')
    let $validMediumCodes := scripts:getValidConcepts('MediumCodeValue')
    let $validWasteClassifications := scripts:getValidConcepts('WasteClassificationValue')
    let $validWasteTreatments := scripts:getValidConcepts('WasteTreatmentValue')

    let $isFeatureTypeValid := function (
        $node as element()
    ) as xs:boolean {
        let $pollutantType := $node/local-name()
        return
            (
                $pollutantType = 'pollutantRelease'
                and $node/pollutant = $validPollutants
                and $node/mediumCode = $validMediumCodes
            )
            or
            (
                $pollutantType = 'offsitePollutantTransfer'
                and $node/pollutant = $validPollutants
            )
            or
            (
                $pollutantType = 'offsiteWasteTransfer'
                and $node/wasteClassification = $validWasteClassifications
                and $node/wasteTreatment = $validWasteTreatments
            )
    }

    (:  C1.1 – combustionPlantCategory consistency  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/combustionPlantCategory/combustionPlantCategory
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "CombustionPlantCategoryValue", $flagBlanks)
    let $LCP_1_1 := xmlconv:RowBuilder("EPRTR-LCP 1.1","combustionPlantCategory consistency", $res )

    (:  C1.2 – CountryCode consistency  :)
    let $resA :=
        let $seq := $docRoot//*[fn:local-name() = ("countryId")]
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "CountryCodeValue", $flagBlanks)
    let $resB :=
        let $seq := $docRoot//*[fn:local-name() = ("countryCode")]
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "CountryCodeValue", $flagBlanks)
    let $LCP_1_2 := xmlconv:RowBuilder("EPRTR-LCP 1.2","CountryCode consistency", ($resA, $resB) )

    (:  C1.3 – EPRTRPollutant consistency   :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport
                /*[fn:local-name() = ("offsitePollutantTransfer", "pollutantRelease")]//pollutant
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "EPRTRPollutantCodeValue", $flagBlanks)
    let $LCP_1_3 := xmlconv:RowBuilder("EPRTR-LCP 1.3","EPRTRPollutantCodeValue consistency", $res )

    (:  C1.4 – fuelInput consistency    :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport//fuelInput/fuelInput
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "FuelInputValue", $flagBlanks)
    let $LCP_1_4 := xmlconv:RowBuilder("EPRTR-LCP 1.4","FuelInputValue consistency", $res )

    (:  C1.5 – LCPPollutant consistency :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "LCPPollutantCodeValue", $flagBlanks)
    let $LCP_1_5 := xmlconv:RowBuilder("EPRTR-LCP 1.5","LCPPollutantCodeValue consistency", $res )

    (:  C1.6 – mediumCode consistency   :)
    let $res :=
        let $seq := $docRoot//pollutantRelease/mediumCode
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "MediumCodeValue", $flagBlanks)
    let $LCP_1_6 := xmlconv:RowBuilder("EPRTR-LCP 1.6","MediumCodeValue consistency", $res )

    (:  C1.7 - methodClassification consistency :)
    let $res :=
        let $seq := $docRoot//methodClassification
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "MethodClassificationValue", $flagBlanks)
    let $LCP_1_7 := xmlconv:RowBuilder("EPRTR-LCP 1.7","MethodClassificationValue consistency", $res )

    (:  C1.8 - methodCode consistency   :)
    let $res :=
        let $seq := $docRoot//methodCode
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "MethodCodeValue", $flagBlanks)
    let $LCP_1_8 := xmlconv:RowBuilder("EPRTR-LCP 1.8","MethodCodeValue consistency", $res )

    (:  C1.9 – Month Consistency    :)
    let $res :=
        let $seq := $docRoot//desulphurisationInformation[fn:string-length(desulphurisationRate) != 0]/month
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "MonthValue", $flagBlanks)
    let $LCP_1_9 := xmlconv:RowBuilder("EPRTR-LCP 1.9","MonthValue consistency", $res )

    (:  C1.10 – OtherGaseousFuel consistency    :)
    let $res :=
        let $otherGases := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherGases"
        let $seq :=
            $docRoot//ProductionInstallationPartReport/energyInput
                    /fuelInput[fuelInput = $otherGases and ancestor::energyInput/energyinputTJ > 0]/otherGaseousFuel
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "OtherGaseousFuelValue", $flagBlanks)
    let $LCP_1_10 := xmlconv:RowBuilder("EPRTR-LCP 1.10","OtherGaseousFuelValue consistency", $res )

    (:  C1.11 – OtherSolidFuel consistency  :)
    let $res :=
        let $otherSolidFuel := "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/FuelInputValue/OtherSolidFuels"
        let $seq :=
            $docRoot//ProductionInstallationPartReport/energyInput
                    /fuelInput[fuelInput = $otherSolidFuel and ancestor::energyInput/energyinputTJ > 0]/otherSolidFuel
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "OtherSolidFuelValue", $flagBlanks)
    let $LCP_1_11 := xmlconv:RowBuilder("EPRTR-LCP 1.11","OtherSolidFuelValue consistency", $res )

    (:  C1.12 - ReasonValue consistency :)
    let $res :=
        let $seq := $docRoot//confidentialityReason[text() => fn:string-length() > 0]
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "ReasonValue", $flagBlanks)
    let $LCP_1_12 := xmlconv:RowBuilder("EPRTR-LCP 1.12","ReasonValue consistency", $res )

    (:  C1.13 – UnitCode consistency    :)
    let $res :=
        let $seq := $docRoot//productionVolumeUnits
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "UnitCodeValue", $flagBlanks)
    let $LCP_1_13 := xmlconv:RowBuilder("EPRTR-LCP 1.13","UnitCodeValue consistency", $res )

    (:  C1.14 – wasteClassification consistency :)
    let $res :=
        let $seq := $docRoot//wasteClassification
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "WasteClassificationValue", $flagBlanks)
    let $LCP_1_14 := xmlconv:RowBuilder("EPRTR-LCP 1.14","WasteClassificationValue consistency", $res )

    (:  C1.15 – wasteTreatment consistency  :)
    let $res :=
        let $seq := $docRoot//wasteTreatment
        let $flagBlanks := 'true'
        return xmlconv:isInVocabulary($seq, "WasteTreatmentValue", $flagBlanks)
    let $LCP_1_15 := xmlconv:RowBuilder("EPRTR-LCP 1.15","WasteTreatmentValue consistency", $res )

    (:  C1.16 – stackHeightClass consistency  :)
    let $res :=
        let $seq := $docRoot//stackHeightClass
        let $flagBlanks := 'false'
        return xmlconv:isInVocabulary($seq, "StackHeightClassValue", $flagBlanks)
    let $LCP_1_16 := xmlconv:RowBuilder("EPRTR-LCP 1.16","StackHeightClassValue consistency", $res )

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
                $LCP_1_15,
                $LCP_1_16
            )
    )

    let $decommissioned := ('decommissioned', 'disused')
    let $facilityInspireIds :=
        $docProductionFacilities/ProductionFacility[year = $reporting-year
            and countryCode = $country_code]/concat(localId, namespace)
    let $installationPartInspireIds :=
        $docProductionInstallationParts//ProductionInstallationPart[not(StatusType = $decommissioned)
            and year = $reporting-year and countryCode = $country_code]
                /concat(localId, namespace)
    let $disusedInstallationPartInspireIds :=
        $docProductionInstallationParts//ProductionInstallationPart[StatusType = $decommissioned
            and year = $reporting-year and countryCode = $country_code]
                /concat(localId, namespace)
    let $installationPartInspireIdsLCP :=
        $docProductionInstallationParts//ProductionInstallationPart[not(StatusType = $decommissioned)
            and year = $reporting-year and countryCode = $country_code
            and PlantType = 'LCP']/concat(namespace, '/', localId)

    (:  C2.1 – inspireId consistency    :)
    let $res :=
        let $errorType := 'error'
        let $map := map {
            'ProductionInstallationPartReport': $installationPartInspireIds,
            'ProductionFacilityReport': $facilityInspireIds
        }
        for $featureType in $docRoot//*[local-name() = map:keys($map)]
            let $inspireId := $featureType/InspireId/data()
            let $errorNumber :=
                if($inspireId = $disusedInstallationPartInspireIds)
                then 3
                else if(not($inspireId = $map?($featureType/local-name())))
                then 2
                else 1
            (:let $ok := $featureType/InspireId/data() = $map?($featureType/local-name()):)
            return
                if($errorNumber = (2, 3))
                (:if(not($ok)):)
                (:if(false()):)
                (:if(true()):)
                then
                    let $text :=
                        if ($errorNumber = 2)
                        then 'InspireId could not be found within the EU Registry'
                        else 'Status is disused or decommissioned in the EU Registry'
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Feature type': map {'pos': 2, 'text': $featureType/local-name()},
                        'Inspire Id':
                            map {'pos': 3, 'text': $featureType/scripts:prettyFormatInspireId(InspireId), 'errorClass': 'td' || $errorType}
                    }
                    return scripts:generateResultTableRow($dataMap)
                else ()
    let $LCP_2_1 := xmlconv:RowBuilder("EPRTR-LCP 2.1","inspireId consistency", $res)

    (:  C2.2 – Comprehensive LCP reporting    :)
    let $res :=
        let $errorType := 'error'
        let $text := 'InspireId could not be found within the E-PRTR and LCP integrated reporting XML'
        let $map := map {
            'ProductionInstallationPartReport': $installationPartInspireIdsLCP
            (:'ProductionFacilityReport': $facilityInspireIds:)
        }
        for $featureType in map:keys($map)
            let $reportInspireIds := $docRoot//*[local-name() = $featureType]
                    /scripts:prettyFormatInspireId(InspireId)
            (:let $asd:= trace($reportInspireIds[1], 'reportInspireIds:'):)
            for $inspideId in $map?($featureType)
            let $ok := $inspideId = $reportInspireIds
            return
                if(not($ok))
                (:if(false()):)
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Feature type': map {'pos': 2, 'text': $featureType},
                        'Inspire ID': map {'pos': 3, 'text': $inspideId, 'errorClass': 'td' || $errorType}
                    }
                    return scripts:generateResultTableRow($dataMap)
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

    (:  C3.1 – Pollutant reporting completeness     :)
    let $res :=
        let $pollutants := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOX",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/DUST"
        )
        (:let $pollutants :=:)
            (:$docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant => fn:distinct-values():)

        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        let $inspireId := $elem/scripts:prettyFormatInspireId(InspireId)
        for $pollutant in $pollutants
        return
            if (fn:count(fn:index-of($elem/emissionsToAir/pollutant, $pollutant)) = 0
                and not(scripts:isNotRegulatedInstallPart($docProductionInstallationParts, $inspireId)))
            then
                <tr>
                    <td class='error' title="Details"> Pollutant has not been reported</td>
                    <td title="Inspire Id">{$inspireId}</td>
                    <td title="Feature type">emissionsToAir</td>
                    <td class="tderror" title="Pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
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
        let $inspireId := $elem/scripts:prettyFormatInspireId(InspireId)
        for $fuel in $fuelInputs
        return
            if (fn:count(fn:index-of($elem/energyInput/fuelInput/fuelInput, $fuel)) = 0
                and not(scripts:isNotRegulatedInstallPart($docProductionInstallationParts, $inspireId)))
            then
                <tr>
                    <td class='error' title="Details"> FuelInput has not been reported</td>
                    <td title="Inspire Id">{$inspireId}</td>
                    <td class="tderror" title="FuelInput"> {functx:substring-after-last($fuel, "/")} </td>
                </tr>
            else
                ()
    let $LCP_3_2 := xmlconv:RowBuilder("EPRTR-LCP 3.2","EnergyInput reporting completeness", $res)

    (:  C3.3 – ‘other’ fuel reporting completeness  :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport
        for $elem in $seq
        let $inspireId := $elem/scripts:prettyFormatInspireId(InspireId)
        for $fuel in $elem/energyInput/fuelInput
        let $ok :=
            if (functx:substring-after-last($fuel/otherGaseousFuel, "/") = "Other"
                and not(scripts:isNotRegulatedInstallPart($docProductionInstallationParts, $inspireId)))
            then
                functx:if-empty($fuel/furtherDetails, "") != ""
            else
                if (functx:substring-after-last($fuel/otherSolidFuel, "/") = "Other"
                    and not(scripts:isNotRegulatedInstallPart($docProductionInstallationParts, $inspireId)))
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
                    <td title="Inspire Id">{$elem/scripts:prettyFormatInspireId(InspireId)}</td>
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
                    <td class="tdwarning" title="Further details">{$fuel/furtherDetails}</td>
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
            where functx:substring-after-last($elem/methodCode, "/") = ("M", "C")
            let $methodClasses := if(count($elem/methodClassification) gt 0)
                then $elem/methodClassification
                else <methodClassification></methodClassification>

            for $methodClass in $methodClasses
            let $ok := ($valid = fn:data($methodClass))
                and not(functx:if-empty($methodClass, '') = '')
            where fn:not($ok)
            return
                <tr>
                    <td class='warning' title="Details"> {$concept} has not been recognised</td>
                    <td title="Inspire Id">{$elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId) => fn:replace("/", "/ ")}</td>
                    <td title="Feature type">{$elem/parent::*/local-name()}</td>
                    <td title="Method Code">{functx:substring-after-last($elem/methodCode, "/")}</td>
                    <td title="Additional info">{scripts:getAdditionalInformation($elem/parent::*)}</td>
                    <td class="tdwarning" title="Method classification">
                        {$methodClass/text() => functx:substring-after-last("/")}
                    </td>
                </tr>
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
            let $reportMethodClass := $elem/methodClassification/text()
            where count(functx:value-intersect($reportMethodClass, $methodClassifications)) > 0
                and count($elem/furtherDetails[functx:if-empty(text(), "") = ""])
                (:and functx:if-empty(string-join($elem/furtherDetails, ""), "") = "":)

            let $mClass :=
                for $m in $reportMethodClass
                    return <p>{$m => functx:substring-after-last("/")}</p>
            return
                <tr>
                    <td class='warning' title="Details">
                        Further details should be provided on the method classification
                    </td>
                    <td title="Inspire Id">{$elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId) => fn:replace("/", "/ ")}</td>
                    <td title="Feature type">{$elem/parent::*/local-name()}</td>
                    <td title="Method classifications">{$mClass}</td>
                    <td title="Additional info">{scripts:getAdditionalInformation($elem/parent::*)}</td>
                    <td class="tdwarning" title="Further details"> </td>
                </tr>

    let $LCP_3_5 := xmlconv:RowBuilder("EPRTR-LCP 3.5",
            "Provision of additional details for reporting of method classification", $res)

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
                    <td class='error' title="Details"> Attribute should contain a character string</td>
                    <td title="Inspire Id">{
                        $el/ancestor::*[fn:local-name()="ProductionFacilityReport"]/scripts:prettyFormatInspireId(InspireId)
                            => fn:replace("/", "/ ")
                    }
                    </td>
                    <td title="Parent feature type"> {$el/parent::*/local-name()} </td>
                    <td title="attribute"> {$attr} </td>
                    <td title="Waste classification">
                        {$el/ancestor::offsiteWasteTransfer/wasteClassification/data() => functx:substring-after-last("/")}
                    </td>
                    <td title="Waste treatment">
                        {$el/ancestor::offsiteWasteTransfer/wasteTreatment/data() => functx:substring-after-last("/")}
                    </td>
                    <td class="tderror" title="Value"> {fn:data($el)} </td>
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
                if(fn:contains($envelope-url, 'converters'))
                then
                <tr>
                    <td class="info" title="Details">
                        Could not verify envelope year because envelope XML is not available.
                    </td>
                </tr>
                else
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
            (:if(fn:true()):)
            then
                <tr>
                    <td class='warning' title="Details">accidentalPollutantQuantityKg attribute value is not valid</td>
                    <td title="Inspire Id">
                        {$elem/ancestor::*[fn:local-name()="ProductionFacilityReport"]/scripts:prettyFormatInspireId(InspireId)}
                    </td>
                    <td title="Total pollutant quantityKg"> {$totalPollutantQuantityKg} </td>
                    <td class="tdwarning" title="Accidental pollutant quantityKg"> {$accidentalPollutantQuantityKg} </td>
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
                functx:if-empty($elem//pollutantRelease[pollutant = $co2][1]
                        /totalPollutantQuantityKg/data(), 0) => fn:number()
            let $co2exclBiomass_amount :=
                functx:if-empty($elem//pollutantRelease[pollutant = $co2exclBiomass][1]
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
            (:if(fn:true()):)
                then
                <tr>
                    <td class='warning' title="Details">
                        Reported CO2 excluding biomass exceeds reported CO2 emissions
                    </td>
                    <td title="Inspire Id">{$elem/scripts:prettyFormatInspireId(InspireId)}</td>
                    <td title="CO2"> {fn:data($co2_amount)} </td>
                    <td class="tdwarning" title="CO2 excluding biomass"> {fn:data($co2exclBiomass_amount)} </td>
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
    (: let $asd := trace(fn:current-time(), 'started 5 at: ') :)
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
                    <td title="Inspire Id">{$elem/descendant-or-self::*/scripts:prettyFormatInspireId(InspireId)}</td>
                    <td class="tderror" title="fuelInput"> {functx:substring-after-last($fuel, "/")} </td>
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
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/DUST",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOX",
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
                        <td title="Inspire Id">{$elem/descendant-or-self::*/scripts:prettyFormatInspireId(InspireId)}</td>
                        <td class="tderror" title="pollutant"> {functx:substring-after-last($pollutant, "/")} </td>
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
                        <td title="Inspire Id">
                            {$elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/scripts:prettyFormatInspireId(InspireId)}
                        </td>
                        <td class="tderror" title="mediumCode / pollutant">
                            {$el}
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
                            <td title="Inspire Id">{$elem/descendant-or-self::*/scripts:prettyFormatInspireId(InspireId)}</td>
                            <td class="tderror" title="pollutant"> {functx:substring-after-last($el, "/")} </td>
                        </tr>
                    else
                        ()

    let $LCP_5_6 := xmlconv:RowBuilder("EPRTR-LCP 5.6","Identification of OffsitePollutantTransfer duplicates", $res)

    (:  C.5.7 – Identification of month duplicates  :)
    let $res :=
    if ($country_code = $skip_countries)
    then ()
    else
        let $seq := $docRoot//ProductionInstallationPartReport
        let $months := scripts:getValidConcepts('MonthValue')
        let $errorMessages := map {
            1: 'Month is duplicated within the DesulphurisationInformationType feature type',
            2: 'Month is missing from the DesulphurisationInformationType feature type'
        }
        for $elem in $seq
            let $derogation := scripts:getDerogation(
                $docProductionInstallationParts, $reporting-year, $elem/InspireId/data())

            where $derogation = 'Article31'

            let $allMonths := $elem/desulphurisationInformation/month/data()
            for $month in $months
                let $error := if(fn:count(index-of($allMonths, $month)) > 1)
                    then 1
                    else if(fn:count(index-of($allMonths, $month)) < 1)
                    then 2
                    else ()
                return
                    if($error)
                        then
                            <tr>
                                <td class='warning' title="Details">
                                    {$errorMessages?($error)}
                                </td>
                                <td title="Inspire Id">{$elem/descendant-or-self::*/scripts:prettyFormatInspireId(InspireId)}</td>
                                <td class="tdwarning" title="Month"> {functx:substring-after-last($month, "/")} </td>
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

    (: let $asd := trace(fn:current-time(), 'started 6.1 at: ') :)
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
                    and pollutant=>fn:lower-case()=>functx:substring-after-last("/") = $pollutant][1]
                        /totalPollutantQuantityKg=> functx:if-empty(0) => fn:number()
        }

        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'warning'
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $text := 'Reported EmissionsToAir is inconsistent with the PollutantRelease
            reported to air for the parent ProductionFacility'
        for $part in $seq
            let $parentFacility := $docProductionInstallationParts//ProductionInstallationPart
                [year = $reporting-year and concat(localId, namespace) = $part/InspireId/data()]
            let $namespace := $parentFacility/parentFacility_namespace => functx:if-empty('Not found')
            let $localId := $parentFacility/parentFacility_localId => functx:if-empty('Not found')

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

                let $ok :=
                    if($pol = 'DUST')
                    then $pollutantQuantityKg <= $parentFacilityQuantityKg div 2
                    else $pollutantQuantityKg <= $parentFacilityQuantityKg
                return
                    (:if(false()):)
                    if(not($ok))
                    (:if(true()):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                            'Pollutant': map {'pos': 3, 'text': $pol},
                            'Pollutant quantity (in Kg)':
                                map {'pos': 4, 'text': $pollutantQuantityKg => xs:decimal()=> fn:round-half-to-even(1)
                                    , 'errorClass': 'td' || $errorType},
                            'Parent facility pollutant quantity (in Kg)':
                                map {'pos': 5, 'text': $parentFacilityQuantityKg => xs:decimal() => fn:round-half-to-even(1)}
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else ()
    let $LCP_6_1 := xmlconv:RowBuilder("EPRTR-LCP 6.1","Individual EmissionsToAir feasibility", $res)

    (: let $asd := trace(fn:current-time(), 'started 6.2 at: ') :)
    (: C6.2 – Cumulative EmissionsToAir feasibility :)
    let $res :=
        let $getTotalPartsQuantity := function (
            $partsInspireIds as xs:string*,
            $pollutant as xs:string?
        ) as xs:double{
            $docRoot//ProductionInstallationPartReport[InspireId = $partsInspireIds]
                    /emissionsToAir[functx:substring-after-last(pollutant, "/") = $pollutant]
                        /functx:if-empty(totalPollutantQuantityTNE, 0) => sum()
        }

        let $seq := $docRoot//ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Cumulative EmissionsToAir for all ProductionInstallationParts under the parent ProductionFacility
            exceed the PollutantRelease value for the specified pollutant.'
        let $emissions := ('SO2', 'NOX', 'DUST')
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $pollutantsNeeded := (
            'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/PM10',
            'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/SOX',
            'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/EPRTRPollutantCodeValue/NOX'
        )

        let $map := map {
            'pm10': 'DUST',
            'sox': 'SO2',
            'nox': 'NOX'
        }

        for $facility in $seq
            let $partsInspireIds := $docProductionInstallationParts//ProductionInstallationPart
                [concat(parentFacility_localId, parentFacility_namespace) = $facility/InspireId/data()]/concat(localId, namespace) => distinct-values()

            for $pollutantRelease in $facility/pollutantRelease[pollutant = $pollutantsNeeded]
                let $pol := $map?($pollutantRelease/pollutant => functx:substring-after-last("/") => lower-case())
                let $facilityQuantityKg := $pollutantRelease
                        /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()

                let $totalPartsQuantityKg :=
                    $getTotalPartsQuantity($partsInspireIds, $pol) * 1000

                (:let $asd:= trace($facility/InspireId/localId/data(), 'localid:'):)
                (:let $asd:= trace($partsInspireIds, 'partsInspireIds:'):)
                (:let $asd:= trace($pol, 'pol:'):)
                (:let $asd:= trace($totalPartsQuantityKg, 'totalPartsQuantityKg:'):)
                (:let $asd:= trace($facilityQuantityKg, 'facilityQuantityKg:'):)

                let $ok :=
                    if($pol = 'DUST')
                    then $totalPartsQuantityKg <= $facilityQuantityKg * 2
                    else $totalPartsQuantityKg <= $facilityQuantityKg

                return
                    (:if(true()):)
                    (:if(false()):)
                    if(not($ok))
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                            'Pollutant': map {'pos': 3, 'text': $pol},
                            'Parts pollutant quantity (in Kg)':
                                map {'pos': 4, 'text': $totalPartsQuantityKg => xs:decimal()=> fn:round-half-to-even(1)},
                            'Facility pollutant quantity (in Kg)':
                                map {'pos': 5, 'text': $facilityQuantityKg => xs:decimal() => fn:round-half-to-even(1),
                                        'errorClass': 'td' || $errorType}
                        }
                        return scripts:generateResultTableRow($dataMap)
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

    (: let $asd := trace(fn:current-time(), 'started 7 at: ') :)
    (:  C7.1 – EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility     :)
    let $res :=
        let $getTotalRatedThermalInput := function(
            $inspireId as xs:string
        ) as xs:double {
            $docProductionInstallationParts//ProductionInstallationPart[year = $reporting-year
                and concat(localId, namespace) = $inspireId]/totalRatedThermalInput => functx:if-empty(0) => fn:number()
        }
        let $getParentFacilityNrOfOperatingHours := function(
            $partInspireId as xs:string
        ) as xs:double {
            let $parentInspireId := $docProductionInstallationParts//ProductionInstallationPart
                [year = $reporting-year and concat(localId, namespace) = $partInspireId]
                    /concat(parentFacility_localId, parentFacility_namespace)
            let $numberOfOperatingHours := $docRoot//ProductionFacilityReport[InspireId = $parentInspireId][1]
                //numberOfOperatingHours => functx:if-empty(0) => fn:number()
            return $numberOfOperatingHours
        }

        let $seq := $docRoot//ProductionInstallationPartReport
        let $errorType := 'warning'
        let $text := map {
            1: 'Calculated operating hours are above the reported numberOfOperatingHours by more than 10%',
            2: 'Calculated operating operating hours exceed 8784 hours',
            3: 'Calculated operating operating hours exceed the reported numberOfOperatingHours for the associated parent ProductionFacility'
        }
        for $part in $seq
            let $aggregatedEnergyInputMW
                := $part/energyInput/energyinputTJ/functx:if-empty(text(), 0) => sum() * 0.0317
            let $totalRatedThermalInput := $getTotalRatedThermalInput($part/InspireId/data())
            let $proportionOfFuelCapacityBurned := $aggregatedEnergyInputMW div $totalRatedThermalInput
            let $calculatedOperatingHours := $proportionOfFuelCapacityBurned * 8784
            let $nrOfOperatingHours := $part/numberOfOperatingHours => functx:if-empty(0) => fn:number()
            let $parentFacilityNrOfOperatingHours :=
                $getParentFacilityNrOfOperatingHours($part/InspireId/data())

            let $errors :=
                if($calculatedOperatingHours gt ($nrOfOperatingHours * 110) div 100)
                then 1
                else if($calculatedOperatingHours > 8784)
                then 2
                else if($calculatedOperatingHours > $parentFacilityNrOfOperatingHours
                    and $parentFacilityNrOfOperatingHours >= 0)
                then 3
                else 0

            return
                if($errors > 0)
                (:if(false()):)
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details':
                            map {'pos': 1, 'text': $text?($errors), 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                        'Calculated operating hours':
                            map {'pos': 3, 'text': $calculatedOperatingHours => round-half-to-even(1), 'errorClass': 'td' || $errorType},
                        'Reported operating hours': map {'pos': 4, 'text': $nrOfOperatingHours},
                        'Parent facility number of operating hours':
                            map {'pos': 5, 'text': $parentFacilityNrOfOperatingHours}
                    }
                    return scripts:generateResultTableRow($dataMap)
                else ()

    let $LCP_7_1 := xmlconv:RowBuilder("EPRTR-LCP 7.1",
            "EnergyInput, totalRatedThermalInput and numberOfOperatingHours plausibility", $res)

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
                        <td title="Inspire Id">{
                            $elem/ancestor-or-self::*[local-name() = 'ProductionFacilityReport']/scripts:prettyFormatInspireId(InspireId)}
                        </td>
                        <td class="tdinfo" title="Feature type"> {fn:node-name($elem/../..)} </td>
                        <td class="tdinfo" title="Method Classification"> {$elem => functx:substring-after-last("/")} </td>
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

    let $inspireIdsNeeded := $docProductionInstallationParts//ProductionInstallationPart
        [year = $reporting-year and derogations => functx:substring-after-last("/") = 'Article31'
            and countryCode = $country_code]/concat(localId, namespace)

    (: let $asd := trace(fn:current-time(), 'started 8 at: ') :)
    (:   C8.1 – Article 31 derogation compliance   :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport[InspireId = $inspireIdsNeeded]
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
            (:let $derogation := $getDerogation($part/InspireId/data()):)
            let $fuelInputs := $part/energyInput[energyinputTJ > 0]/fuelInput/fuelInput/text()
            let $error1 :=
                if(functx:value-intersect($solidFuelTypes, $fuelInputs)=>fn:count() = 0)
                then 1
                else 0
            let $error2 :=
                if($part/desulphurisationInformation/data()=>fn:string-join()=>fn:string-length() = 0)
                then 2
                else 0

            let $result1 :=
                if($error1 > 0)
                (:if(false()):)
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                        'Additional info': map {'pos': 3, 'text': $errorMap?($error1), 'errorClass': 'td' || $errorType}
                    }
                    return scripts:generateResultTableRow($dataMap)
                else ()
            let $result2 :=
                if($error2 > 0)
                (:if(false()):)
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                        'Additional info': map {'pos': 3, 'text': $errorMap?($error2), 'errorClass': 'td' || $errorType}
                    }
                    return scripts:generateResultTableRow($dataMap)
                else ()
            return
                ($result1, $result2)


    let $LCP_8_1 := xmlconv:RowBuilder("EPRTR-LCP 8.1","Article 31 derogation compliance", $res)

    (:  C8.2 – Article 31 derogation justification  :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else
            let $isDerogationFirstYear := function (
                $inspireId as xs:string
            ) as xs:boolean {
                let $historicSubmissionsCount := $docProductionInstallationParts//ProductionInstallationPart
                    [year != $reporting-year and derogations=>functx:substring-after-last("/") = 'Article31'
                    and concat(localId, namespace) = $inspireId]
                        => fn:count()
                return
                    if($historicSubmissionsCount > 0)
                    then false()
                    else true()
            }

            let $seq := $docRoot//ProductionInstallationPartReport[InspireId = $inspireIdsNeeded]
            let $errorType := 'warning'
            let $text := 'Technical justification has been omitted for the Installation part'
            for $part in $seq
                let $result :=
                    if($isDerogationFirstYear($part/InspireId/data()))
                    then
                        for $desulphurisation in $part/desulphurisationInformation
                        let $ok := $desulphurisation/technicalJustification => fn:string-length() > 0

                        return
                            if(not($ok))
                            (:if(true()):)
                            then
                                let $dataMap := map {
                                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                                    'Inspire Id': map {
                                        'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)
                                    },
                                    'desulphurisationInformation/Month' : map {
                                        'pos': 3, 'text': $desulphurisation/month =>functx:substring-after-last("/")
                                    }
                                }
                                return scripts:generateResultTableRow($dataMap)
                            else ()
                    else ()
                return $result


    let $LCP_8_2 := xmlconv:RowBuilder("EPRTR-LCP 8.2","Article 31 derogation justification", $res)

    (:  C8.3 – Article 35 derogation and proportionOfUsefulHeatProductionForDistrictHeating comparison  :)
    let $res :=
        let $inspireIdsNedded := $docProductionInstallationParts//ProductionInstallationPart
            [year = $reporting-year and derogations=>functx:substring-after-last("/") = 'Article35'
                and countryCode = $country_code]/concat(localId, namespace)
        let $seq := $docRoot//ProductionInstallationPartReport[InspireId = $inspireIdsNedded]
        let $errorType := 'info'
        let $text := 'Proportion of useful heat production for district heating has been omitted or reported below 50%'
        for $part in $seq
            let $proportion :=
                $part/proportionOfUsefulHeatProductionForDistrictHeating => functx:if-empty(0) => fn:number()
            let $ok := $proportion ge 50

            return
                if(not($ok))
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                        'Proportion of useful heat production for district heating':
                            map {'pos': 3, 'text': $proportion || '%', 'errorClass': 'td' || $errorType}
                    }
                    return scripts:generateResultTableRow($dataMap)
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
            (:if(fn:true()):)
            then
                for $confidentialityReason in $docRoot//confidentialityReason[fn:string-length() > 0]
                let $dataMap := map {
                    'Details': map {'pos': 1,'text': $errorMessage, 'errorClass': $errorType},
                    'Inspire Id': map {'pos': 2,
                        'text': $confidentialityReason/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)
                    },
                    'Path': map {'pos': 3, 'text': $confidentialityReason => functx:path-to-node()},
                    'confidentialityReason': map {
                        'pos': 4, 'text': $confidentialityReason => functx:substring-after-last('/'),
                        'errorClass': 'td' || $errorType
                    }
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

    (: let $asd := trace(fn:current-time(), 'started 10.1 at: ') :)
    (:  C10.1 – EmissionsToAir outlier identification   :)
    let $res :=
        let $seq:= $docRoot//ProductionInstallationPartReport
        (:let $emissions := fn:distinct-values($seq/emissionsToAir/pollutant):)
        let $emissions := (
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/NOX",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/SO2",
            "http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/LCPPollutantCodeValue/DUST"
        )

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
                    return $pollutant/functx:if-empty(energyinputTJ, 0) * $emissionFactor
                )
                let $emissionConstant := if($emission = "NOX") then 1 div 10 else 1 div 100
                where $expected > 0
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
                            <td title="Inspire Id">{$elem/scripts:prettyFormatInspireId(InspireId)}</td>
                            <td title="fuelInput">{$emission => functx:substring-after-last("/")}</td>
                            <td title="Expected">{$expected}</td>
                            <td class="tdinfo" title="Total reported">{$emissionTotal}</td>
                        </tr>
                    else
                        ()
    let $LCP_10_1 := xmlconv:RowBuilder("EPRTR-LCP 10.1","EmissionsToAir outlier identification", $res)

    (: let $asd := trace(fn:current-time(), 'started 10.2 at: ') :)
    (:  C10.2 – Energy input and CO2 emissions feasibility  :)
    let $res :=
        let $getAggregatedPartsCO2 := function (
            $inspireId as element()
        ) as xs:double {
            (: 000000003.PART
            2465 * 56.1
            138286.5
            :)
            let $partsInspireIds := $docProductionInstallationParts//ProductionInstallationPart
                    [concat(parentFacility_localId, parentFacility_namespace) = $inspireId/data()]
                        /concat(localId, namespace) => distinct-values()
            (:let $asd := trace($inspireId/data(), "inspireId: "):)
            (:let $asd := trace($partsInspireIds, "partsInspireIds: "):)
            let $result :=
            for $emission in $docRoot//ProductionInstallationPartReport[InspireId = $partsInspireIds]
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
                (:let $asd := trace($energyinput, "energyinput: "):)
                (:let $asd := trace($fuelInput, "fuelInput: "):)

                let $emissionFactor :=
                    $docEmissions//row[EF_LOOKUP = $fuelInput]/CO2 => functx:if-empty(0) => fn:number()
                (:let $asd := trace($emissionFactor, "emissionFactor: "):)
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
            let $reportedCO2 := $facility/pollutantRelease[pollutant = $pollutant and mediumCode = $mediumCode][1]
                /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            let $aggregatedPartsCO2 := $getAggregatedPartsCO2($facility/InspireId)

            let $thresholdValue := $docANNEXII/row[Codelistvalue
                = $pollutant => scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                    /toAir

            (:let $asd := trace($reportedCO2, "reportedCO2: "):)
            (:let $asd := trace($aggregatedPartsCO2, "aggregatedPartsCO2: "):)
            (:let $asd:= trace($thresholdValue, 'thresholdValue: '):)

            where $aggregatedPartsCO2 > $thresholdValue

            let $percentage := if($reportedCO2 = 0 or $aggregatedPartsCO2 = 0)
                then 100
                else (100 - (($reportedCO2 * 100) div $aggregatedPartsCO2)) => abs()

            let $ok := if($reportedCO2 + $aggregatedPartsCO2 = 0)
                then true()
                else if($reportedCO2 > $aggregatedPartsCO2)
                then $percentage < 100
                else $percentage < 20
                (:then ($reportedCO2 div $aggregatedPartsCO2) * 100 - 100 < 100:)
                (:else ($aggregatedPartsCO2 div $reportedCO2) * 100 - 100 < 30:)
            return
                if(fn:not($ok))
                (:if(fn:true()):)
                (:if($reportedCO2 > 0):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                        'Facility reported CO2 amount': map {
                            'pos': 3,
                            'text': $reportedCO2 => xs:decimal() => fn:round-half-to-even(1)
                        },
                        'Calculated CO2 from associated installation part fuel input':
                            map {'pos': 4, 'text': $aggregatedPartsCO2 => xs:decimal() => fn:round-half-to-even(1)},
                        'Deviation percentage': map {
                            'pos': 5,
                            'text': $percentage => xs:decimal() => fn:round-half-to-even(1) || '%',
                            'errorClass': 'td' || $errorType
                        }
                    }
                    return scripts:generateResultTableRow($dataMap)
                else()
    let $LCP_10_2 := xmlconv:RowBuilder("EPRTR-LCP 10.2",
            "Energy input and CO2 emissions feasibility", $res)

    (: let $asd := trace(fn:current-time(), 'started 10.3 at: ') :)
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
        (:let $text := map {
            1: 'Resultant pollutant emissions to air is missing',
            2: 'Resultant pollutant is low/high based on comparison with expected ranges'
        }:)
        let $text := 'Resultant pollutant is low/high based on comparison with expected ranges'

        for $facility in $seq
            let $EPRTRAnnexIActivity := scripts:getEPRTRAnnexIActivity(
                    $facility/InspireId/data(),
                    $reporting-year,
                    $docProductionFacilities
            )
            (:let $asd := trace($EPRTRAnnexIActivity, 'EPRTRAnnexIActivity: '):)
            for $row in $docCrossPollutants//row[AnnexIActivityCode => replace('\.', '') = $EPRTRAnnexIActivity]
                let $conditionPollutant := $row/ConditionPollutant/data()
                let $conditionValue := $row/ConditionValue => functx:if-empty(0) => fn:number()
                let $conditionSourcePollutant := $row/ConditionSourcePollutant/data()

                let $reportingThreshold := $row/ReportingThreshold => fn:number()
                let $sourcePollutantValue := $getPollutantValue($facility, $row/SourcePollutant)
                let $resultingPollutantValue := $getPollutantValue($facility, $row/ResultingPollutant)
                let $conditionPollutantValue := $getPollutantValue($facility, $conditionPollutant)
                let $conditionSourcePollutantValue := $getPollutantValue($facility, $conditionSourcePollutant)

                let $cond := if($conditionValue gt 0)
                    then $conditionPollutantValue gt ($conditionSourcePollutantValue * $conditionValue) div 100
                    else fn:true()

                where $cond

                (:let $asd := trace($facility/InspireId/localId/text(), "LocalID: "):)
                (:let $asd := trace($row/SourcePollutant/text(), "Source pollutant: "):)
                (:let $asd := trace($sourcePollutantValue => xs:decimal() => fn:round-half-to-even(1), "Source pollutant amount: "):)
                (:let $asd := trace($row/ResultingPollutant/text(), "Resulting pollutant: "):)
                (:let $asd := trace($resultingPollutantValue => xs:decimal() => fn:round-half-to-even(1), "Resulting pollutant amount: "):)
                (:let $asd := trace((($conditionSourcePollutantValue * $conditionValue) div 100),:)
                        (:'Calc cond val: '):)
                (:let $asd := trace($conditionPollutantValue => xs:decimal(), 'Condition pollutant value: '):)
                (:let $asd := trace($conditionPollutant, 'conditionPollutant: '):)
                (:let $asd := trace($conditionValue, 'conditionValue(percent): '):)
                (:let $asd := trace('-------------------'):)

                let $minExpectedEmission :=
                    ($sourcePollutantValue * $row/MinFactor => functx:if-empty(0)) => fn:number()
                let $maxExpectedEmission :=
                    ($sourcePollutantValue * $row/MaxFactor => functx:if-empty(0)) => fn:number()

                let $distance := if($resultingPollutantValue <= $minExpectedEmission)
                    then $minExpectedEmission - $resultingPollutantValue
                    else $resultingPollutantValue - $maxExpectedEmission

                let $expectedEmissionFactor := $distance div $reportingThreshold

                (:let $asd := trace($reportingThreshold, 'reportingThreshold: '):)
                (:let $asd := trace($maxExpectedEmission, 'maxExpectedEmission: '):)
(:
                let $tracer :=
                if($resultingPollutantValue > 0)
                then
                    let $asd := trace($row/SourcePollutant/text(), "Source pollutant: ")
                    let $asd := trace($sourcePollutantValue => xs:decimal() => fn:round-half-to-even(1), "Source pollutant amount: ")
                    let $asd := trace($row/ResultingPollutant/text(), "Resulting pollutant: ")
                    let $asd := trace($resultingPollutantValue => xs:decimal() => fn:round-half-to-even(1), "Resulting pollutant amount: ")
                    let $asd := trace($minExpectedEmission => xs:decimal() => fn:round-half-to-even(1), "minExpectedEmission: ")
                    let $asd := trace($maxExpectedEmission => xs:decimal() => fn:round-half-to-even(1), "maxExpectedEmission: ")
                    let $asd := trace($distanceMin => xs:decimal() => fn:round-half-to-even(1), "distanceMin: ")
                    let $asd := trace($distanceMax => xs:decimal() => fn:round-half-to-even(1), "distanceMax: ")
                    let $asd := trace($expectedEmissionFactorMin => xs:decimal() => fn:round-half-to-even(1), "expectedEmissionFactorMin: ")
                    let $asd := trace($expectedEmissionFactorMax => xs:decimal() => fn:round-half-to-even(1), "expectedEmissionFactorMax: ")
                    return 0
                else 0
:)
                let $priorityIndex := map{
                    'LOW': 3,
                    'MEDIUM': 2,
                    'HIGH': 1
                }

                let $priority :=
                    if($expectedEmissionFactor <= 2)
                    then 'LOW'
                    else if($expectedEmissionFactor > 2 and $expectedEmissionFactor < 10)
                    then 'MEDIUM'
                    else 'HIGH'
                let $additionalComment :=
                    'The priority of the failure of this check has been
                    classified as '|| $priority ||' based on the expected emissions factor.'

                (:let $errorNR := if($resultingPollutantValue = 0)
                    then 1
                    else 2:)

                let $ok := (
                    $sourcePollutantValue = 0
                    or
                    (
                        $resultingPollutantValue >= $minExpectedEmission
                        and
                        $resultingPollutantValue <= $maxExpectedEmission
                    )
                    or
                    $minExpectedEmission < $reportingThreshold
                )

                (:let $notOK := (
                    ($resultingPollutantValue = 0 and $minExpectedEmission gt $reportingThreshold)
                    or
                    $resultingPollutantValue < $minExpectedEmission
                    or
                    $resultingPollutantValue > $maxExpectedEmission
                ):)
                (:let $asd:= trace($ok, 'OK: '):)
                (:let $asd:= trace(' '):)

                return
                    if(fn:not($ok))
                    (:if($notOK):)
                    (:if(fn:true()):)
                    (:if($resultingPollutantValue > 0):)
                    (:if($sourcePollutantValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {
                                'pos': 1,
                                'text': $text,
                                'errorClass': $errorType,
                                'sortValue': $priorityIndex?($priority)
                            },
                            'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId) => fn:replace("/", "/ ")},
                            'Source pollutant': map {'pos': 3, 'text': $row/SourcePollutant/text()},
                            'Source pollutant amount': map {
                                'pos': 4,
                                'text': $sourcePollutantValue => xs:decimal() => fn:round-half-to-even(1)
                            },
                            'Resulting pollutant': map {'pos': 5, 'text': $row/ResultingPollutant/text()},
                            'Resulting pollutant amount': map {
                                'pos': 6,
                                'text': $resultingPollutantValue => xs:decimal() => fn:round-half-to-even(1),
                                'errorClass': 'td' || $errorType
                            },
                            (:'Minimum expected emission'::)
                                (:map {'pos': 7, 'text': $minExpectedEmission => fn:number() :)(:=> fn:round-half-to-even(1):)(:},:)
                            (:'Maximum expected emission'::)
                                (:map {'pos': 8, 'text': $maxExpectedEmission => fn:number() :)(:=> fn:round-half-to-even(1):)(:},:)
                            'Priority': map {'pos': 9, 'text': $additionalComment}
                            (:'expectedEmissionFactorMax': map {'pos': 10, 'text': $expectedEmissionFactor},:)
                            (:'Annex II reporting threshold': map {'pos': 11, 'text': $reportingThreshold}:)
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()
    let $res_sorted :=
        for $tr in $res
            let $sort_val := $tr/@sort/number()
            order by $sort_val
            return $tr

    let $LCP_10_3 := xmlconv:RowBuilder("EPRTR-LCP 10.3",
            "ProductionFacility cross pollutant identification", $res_sorted)

    let $LCP_10 := xmlconv:RowAggregator(
            "EPRTR-LCP 10",
            "Expected pollutant identification",
            (
                $LCP_10_1,
                $LCP_10_2,
                $LCP_10_3
            )
    )

    (: let $asd := trace(fn:current-time(), 'started 11.1 at: ') :)
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
            (:if(fn:true()):)
            then
                <tr>
                    <td class='info' title="Details">
                        No releases/transfers of pollutants nor transfers of waste have been reported
                    </td>
                    <td class="tdinfo" title="Inspire Id">
                        {$elem/ancestor-or-self::*[fn:local-name() = ("ProductionFacilityReport")]/scripts:prettyFormatInspireId(InspireId)}
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
        let $threshold := $docANNEXII/row[Codelistvalue
                = $pollutantNode/pollutant=>scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                    /*[local-name() = $mediumMap?($mediumCode)]
        return if($threshold = 'NA')
            then -1
            else $threshold => functx:if-empty(0) => fn:number()
    }

    let $getThresholdOffsitePollutantTransfer := function (
        $pollutantNode as element()
    ) as xs:double {
        let $threshold := $docANNEXII/row[Codelistvalue
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
    (: let $asd := trace(fn:current-time(), 'started 11.2 at: ') :)
    (: TODO long running time :)
    (:  C11.2 - ProductionFacility releases and transfers reported below the thresholds :)

    (: result for pollutantRelease and offsitePollutantTransfer types:)
    let $res :=
        let $BTEXthreshold := 200
        let $map := map {
            "pollutantRelease": map {
                'getFunction': $getThresholdPollutantRelease,
                'nodeNameQuantity': 'totalPollutantQuantityKg'
                } ,
            "offsitePollutantTransfer": map {
                'getFunction': $getThresholdOffsitePollutantTransfer,
                'nodeNameQuantity': 'totalPollutantQuantityKg'
            }
        }

        let $seq := $docRoot/ReportData/ProductionFacilityReport/*[local-name() = map:keys($map)]
        let $errorType := 'info'
        let $text := 'Amount reported is below the threshold value'

        for $pollutantNode in $seq
            let $pollutantType := $pollutantNode/local-name()
            let $reportedAmount := $pollutantNode/*[local-name() = $map?($pollutantType)?nodeNameQuantity]
                /functx:if-empty(data(), 0) => fn:number()
            let $thresholdValue := $map?($pollutantType)?getFunction($pollutantNode)

            let $ok := (
                $reportedAmount ge $thresholdValue
                or $thresholdValue = -1
            )
            where not($ok)
            let $facility := $pollutantNode/ancestor::ProductionFacilityReport

            (: Only flag benzene, toluene, ethyl benzene, xylenes
                if the sum of these is below threshold :)
            where scripts:isBTEXbelowThreshold($pollutantNode, $facility, $BTEXthreshold, $map)

            let $dataMap := map {
                'Details' : map {'pos' : 1, 'text' : $text, 'errorClass' : $errorType},
                'Inspire Id' : map {'pos' : 2, 'text' : $pollutantNode/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)},
                'Type' : map {'pos' : 3, 'text' : $pollutantType || $getCodes($pollutantNode)},
                'Reported amount':
                    map {'pos' : 4, 'text' : $reportedAmount, 'errorClass': 'td' || $errorType},
                'Threshold value': map {'pos' : 5, 'text' : $thresholdValue}
            }
            return scripts:generateResultTableRow($dataMap)

    (: result for offsiteWasteTransfer type:)
    let $res2 :=
        let $seq := $docRoot/ReportData/ProductionFacilityReport
        let $errorType := 'info'
        let $text := 'Amount reported is below the threshold value'
        let $wasteClassifications := ('http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/WasteClassificationValue/NONHW',
            'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/WasteClassificationValue/HW')

        for $facility in $seq
            for $waste in $wasteClassifications
                let $wasteClass := $waste => functx:substring-after-last("/")
                let $threshold :=
                    if($wasteClass = 'HW')
                    then 2
                    else 2000

                let $reportedAmount := $facility//offsiteWasteTransfer[wasteClassification = $waste]
                        /fn:number(totalWasteQuantityTNE) => fn:sum()

                where $reportedAmount > 0 and $reportedAmount < $threshold

                let $dataMap := map {
                    'Details' : map {'pos' : 1, 'text' : $text, 'errorClass' : $errorType},
                    'Inspire Id' : map {'pos' : 2, 'text' : $facility/scripts:prettyFormatInspireId(InspireId)},
                    'Type' : map {'pos' : 3, 'text' : 'offsiteWasteTransfer - ' || $wasteClass},
                    'Reported amount':
                        map {'pos' : 4, 'text' : $reportedAmount => xs:decimal(), 'errorClass': 'td' || $errorType},
                    'Threshold value': map {'pos' : 5, 'text' : $threshold => xs:decimal()}
                    }

                return scripts:generateResultTableRow($dataMap)


    let $LCP_11_2 := xmlconv:RowBuilder("EPRTR-LCP 11.2",
            "ProductionFacility releases and transfers reported below the thresholds",
            ($res, $res2))

    let $LCP_11 := xmlconv:RowAggregator(
            "EPRTR-LCP 11",
            "ProductionFacility voluntary reporting checks",
            (
                $LCP_11_1,
                $LCP_11_2
            )
    )

    (: let $asd := trace(fn:current-time(), 'started 12.1 at: ') :)
    (: TODO long running time :)
    (: C12.1 - Identification of ProductionFacility release/transfer outliers
        against previous year data at the national level :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else

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
                    $pollutantNode/*[local-name() = $nodeName]/text()
                    (:scripts:getPollutantCode($pollutantNode/*[local-name() = $nodeName]/text(), $docPollutantLookup):)
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
                then $map?doc/row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity
                        and Codelistvalue  = $code1
                        and fn:upper-case(ReleaseMediumName) = $code2]
                            /SumOfTotalQuantity
                else if($pollutant = 'offsitePollutantTransfer')
                then $map?doc/row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity
                        and Codelistvalue = $code1]
                        /SumOfQuantity
                else $map?doc/row[ReportingYear = $look-up-year and CountryCode = $country_code
                    and MainIAActivityCode => replace('\.', '') = $activity and WasteTypeCode = $code1
                        and WasteTreatmentCode = $code2]
                            /TotalQuantity
            return $value => functx:if-empty(0) => fn:number() * 4
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
                'lookupNodeName': 'TotalQuantity',
                'reportNodeName': 'totalWasteQuantityTNE'
            }
        }
        let $seq := $docRoot/ReportData/ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Reported value exceeded parameter value'
        for $facility in $seq
            let $EPRTRAnnexIActivity := scripts:getEPRTRAnnexIActivity(
                    $facility/InspireId/data(),
                    $reporting-year,
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

                let $ok := (
                    $reportValue < $lookupHighestValue
                    or
                    $lookupHighestValue = 0
                )
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if($reportValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                            'Annex I activity': map {'pos': 3, 'text': $EPRTRAnnexIActivity},
                            'Type': map {'pos': 4,
                                'text': $pollutant || ' - ' || $code1 || (if($code2 = '') then '' else ' / ' || $code2)
                            },
                            'Reported value': map {'pos': 5,
                                'text': $reportValue => xs:decimal(),
                                'errorClass': 'td' || $errorType
                            },
                            'Parameter value': map {'pos': 6,
                                'text': $lookupHighestValue => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()

    let $LCP_12_1 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.1",
            "Identification of ProductionFacility release/transfer outliers
            against previous year data at the national level",
            $res
    )
    (: let $asd := trace(fn:current-time(), 'started 12.2 at: ') :)
    (: TODO SUPER long running time :)
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
            for $pollutantNode in $docRoot/ReportData/ProductionFacilityReport/*[local-name() = $pollutantTypes]
            return
            <row>
                <InspireId>{$pollutantNode/ancestor::ProductionFacilityReport/InspireId/*}</InspireId>
                <type>{$pollutantNode/local-name()}</type>
                <EPRTRAnnexIActivity>
                    {scripts:getEPRTRAnnexIActivity(
                            $pollutantNode/ancestor::ProductionFacilityReport/InspireId/data(),
                            $reporting-year,
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
        (:let $nationalnationalValuesXML := doc($nationalValuesXML):)
        (:let $trace := trace($nationalValuesXML/row => functx:path-to-node(), "nationalTotal: "):)
        (:let $asd := trace(fn:current-time(), 'finished national values xml generation 12.2 at: '):)

        let $nationalTotalPollutantRelease :=
        <data>
        {
            let $seqActivities := $nationalValuesXML/row[type = 'pollutantRelease']
                    /EPRTRAnnexIActivity => distinct-values()
            let $seqPollutants := $nationalValuesXML/row[type = 'pollutantRelease'
                    and pollutant = $validPollutants]
                    /pollutant => distinct-values()
            let $seqMediumCodes := $nationalValuesXML/row[type = 'pollutantRelease'
                    and mediumCode = $validMediumCodes]
                    /mediumCode => distinct-values()
            for $annexIActivity in $seqActivities,
                $pollutant in $seqPollutants,
                $mediumCode in $seqMediumCodes
            return
            <row>
                <EPRTRAnnexIActivity>{$annexIActivity}</EPRTRAnnexIActivity>
                <pollutant>{$pollutant}</pollutant>
                <mediumCode>{$mediumCode}</mediumCode>
                <quantity>{
                    $nationalValuesXML/row[type = 'pollutantRelease' and pollutant = $pollutant
                    and EPRTRAnnexIActivity = $annexIActivity and mediumCode = $mediumCode]
                        /totalPollutantQuantityKg => fn:sum()
                }
                </quantity>
            </row>
        }
        </data>
        (:let $asd := trace(fn:current-time(), 'finished pollutantRelease xml generation 12.2 at: '):)

        let $nationalTotalOffsitePollutantTransfer :=
        <data>
        {
            for $annexIActivity in $nationalValuesXML/row[type = 'offsitePollutantTransfer']
                    /EPRTRAnnexIActivity => distinct-values(),
                $pollutant in $nationalValuesXML/row[type = 'offsitePollutantTransfer'
                    and pollutant = $validPollutants]
                    /pollutant => distinct-values()
            return
            <row>
                <EPRTRAnnexIActivity>{$annexIActivity}</EPRTRAnnexIActivity>
                <pollutant>{$pollutant}</pollutant>
                <quantity>{
                    $nationalValuesXML/row[type = 'offsitePollutantTransfer' and pollutant = $pollutant
                    and EPRTRAnnexIActivity = $annexIActivity]
                        /totalPollutantQuantityKg => fn:sum()
                }
                </quantity>
            </row>
        }
        </data>
        (:let $asd := trace(fn:current-time(), 'finished offsitePollutantTransfer xml generation 12.2 at: '):)

        let $nationalTotalOffsiteWasteTransfer :=
        <data>
        {
            for $annexIActivity in $nationalValuesXML/row[type = 'offsiteWasteTransfer']
                    /EPRTRAnnexIActivity => distinct-values(),
                $wasteClassification in $nationalValuesXML/row[type = 'offsiteWasteTransfer'
                    and wasteClassification = $validWasteClassifications]
                    /wasteClassification => distinct-values()
            return
            <row>
                <EPRTRAnnexIActivity>{$annexIActivity}</EPRTRAnnexIActivity>
                <wasteClassification>{$wasteClassification}</wasteClassification>
                <quantity>{
                    $nationalValuesXML/row[type = 'offsiteWasteTransfer'
                    and EPRTRAnnexIActivity = $annexIActivity
                        and wasteClassification = $wasteClassification]
                        /totalWasteQuantityTNE => fn:sum()
                }
                </quantity>
            </row>
        }
        </data>
        (:let $asd := trace(fn:current-time(), 'finished offsiteWasteTransfer xml generation 12.2 at: '):)

        (:let $asd := trace(fn:current-time(), 'finished national totals xmls generation 12.2 at: '):)
        let $getNationalTotal := function (
            $pollutantNode as element(),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            let $type := $pollutantNode/local-name()
            return
            if($type = 'offsiteWasteTransfer')
            then
                $nationalTotalOffsiteWasteTransfer/row[EPRTRAnnexIActivity = $EPRTRAnnexIActivity
                        and wasteClassification = $pollutantNode/wasteClassification]
                        /quantity => functx:if-empty(0) => fn:number()
            else if($type = 'pollutantRelease')
            then
                $nationalTotalPollutantRelease/row[pollutant = $pollutantNode/pollutant
                    and EPRTRAnnexIActivity = $EPRTRAnnexIActivity and mediumCode = $pollutantNode/mediumCode]
                        /quantity => functx:if-empty(0) => fn:number()
            else
                $nationalTotalOffsitePollutantTransfer/row[pollutant = $pollutantNode/pollutant
                    and EPRTRAnnexIActivity = $EPRTRAnnexIActivity]
                        /quantity => functx:if-empty(0) => fn:number()
        }

        let $seq := $docRoot/ReportData/ProductionFacilityReport
        let $errorType := 'warning'
        let $text := 'Reported value exceeds the threshold conditions'

        for $facility in $seq
            (:let $asd := trace($pos, "facitlity nr: "):)
            let $InspireId := $facility/InspireId
            let $EPRTRAnnexIActivity :=
                scripts:getEPRTRAnnexIActivity(
                            $facility/InspireId/data(),
                            $reporting-year,
                            $docProductionFacilities)
                (:$nationalValuesXML/row[InspireId/data() = $InspireId/data()][1]
                    /EPRTRAnnexIActivity/text() => functx:if-empty('Activity not found'):)
            (: ('pollutantRelease', 'offsitePollutantTransfer', 'offsiteWasteTransfer') :)
            for $pollutantNode in $facility/*[local-name() = $pollutantTypes]
            let $pollutantType := $pollutantNode/local-name()
            return
            if($isFeatureTypeValid($pollutantNode) = true())
            then
                let $nationalTotal := $getNationalTotal($pollutantNode, $EPRTRAnnexIActivity)
                let $reportedValue :=
                    $pollutantNode/totalPollutantQuantityKg => functx:if-empty($pollutantNode/totalWasteQuantityTNE)
                        => functx:if-empty(0) => fn:number()
                let $thresholdValue := $getThresholdValue($pollutantNode)

                (:let $asd:= trace($pollutantType, 'pollutantType: '):)
                (:let $asd:= trace($thresholdValue, 'thresholdValue: '):)
                (:let $asd:= trace($reportedValue, 'reportedValue: '):)
                (:let $asd:= trace($nationalTotal, 'nationalTotal: '):)

                let $notOk := (
                    $reportedValue gt $thresholdValue * 10000
                    and
                    $reportedValue gt $nationalTotal div 10
                )
                (:let $asd:= trace($notOk, 'notOk: '):)
                return
                    if($notOk)
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                            'Type': map {'pos': 3, 'text': $pollutantType || $getCodes($pollutantNode)
                            },
                            'Reported value': map {'pos': 4,
                                'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                            },
                            'National total': map {'pos': 5,
                                'text': $nationalTotal => xs:decimal() => fn:round-half-to-even(1)
                            },
                            'Threshold value': map {'pos': 6,
                                'text': $thresholdValue => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()
            else ()

    let $LCP_12_2 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.2",
            "Identification of ProductionFacility release/transfer outliers
            against national total and pollutant threshold",
            $res
    )
    (: let $asd := trace(fn:current-time(), 'started 12.3 at: ') :)
    (: C12.3 - Identification of ProductionFacility release/transfer outliers against previous year data :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else

        let $getLastYearValue := function (
            $pollutantNode as element(),
            $inspireId as xs:string
        ) as xs:double {
            if($pollutantNode/local-name() = 'pollutantRelease')
            then $docProductionFacilities/ProductionFacility[year = $previous-year
                and concat(localId, namespace) = $inspireId]/pollutantRelease[mediumCode = $pollutantNode/mediumCode
                    and pollutant = $pollutantNode/pollutant]
                        /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            else if($pollutantNode/local-name() = 'offsitePollutantTransfer')
            then $docProductionFacilities/ProductionFacility[year = $previous-year
                and concat(localId, namespace) = $inspireId]/offsitePollutantTransfer[pollutant = $pollutantNode/pollutant]
                    /totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
            else -1
        }
        let $getLastYearValueOffsiteWasteTransfer := function (
            $wasteClassification as xs:string,
            $inspireId as xs:string
        ) as xs:double {
            $docProductionFacilities/ProductionFacility[year = $previous-year
                and concat(localId, namespace) = $inspireId]/offsiteWasteTransfer
                    [wasteClassification => functx:substring-after-last("/") = $wasteClassification]
                        /totalWasteQuantityTNE => fn:sum()

        }
        let $facilityInspireIdsNeeded :=
            $docProductionFacilities/ProductionFacility[year != $reporting-year
                and countryCode = $country_code]/concat(localId, namespace) => distinct-values()
        let $pollutantTypes := ('pollutantRelease', 'offsitePollutantTransfer', 'offsiteWasteTransfer')
        let $seq := $docRoot//ProductionFacilityReport[InspireId = $facilityInspireIdsNeeded]
        let $errorType := 'warning'
        let $text := 'Reported data exceeds threshold of deviation from previous year data'
        for $facility in $seq
            for $pollutantType in $pollutantTypes
            (:let $trace := trace($pollutantType, "pollutantType: "):)
            let $result :=
            if($pollutantType != 'offsiteWasteTransfer')
            then
                for $pollutantNode in $facility/*[local-name() = $pollutantType]
                let $reportedValue := $pollutantNode/totalPollutantQuantityKg => functx:if-empty(0) => fn:number()
                let $lastYearValue := $getLastYearValue($pollutantNode, $facility/InspireId/data())
                (:let $trace := trace($reportedValue, "reportedValue: "):)
                (:let $trace := trace($lastYearValue, "lastYearValue: "):)
                let $ok := (
                    $reportedValue + $lastYearValue = 0
                    or
                    ($reportedValue < $lastYearValue * 2
                    and
                    $reportedValue * 10 > $lastYearValue)
                )

                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                            'Type': map {'pos': 3, 'text': $pollutantType || $getCodes($pollutantNode)
                            },
                            'Reported value': map {'pos': 4,
                                'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                            },
                            'Last year value': map {'pos': 5,
                                'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()

            else
                for $wasteClassification in ('HW', 'NONHW')
                let $reportedValue := $facility/offsiteWasteTransfer
                    [wasteClassification => functx:substring-after-last("/") = $wasteClassification]
                        /functx:if-empty(totalWasteQuantityTNE, 0) => fn:sum()
                let $lastYearValue := $getLastYearValueOffsiteWasteTransfer(
                        $wasteClassification,
                        $facility/InspireId/data()
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
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if(fn:true()):)
                    (:if($reportedValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                            'Type': map {'pos': 3, 'text': $pollutantType || ' - ' || $wasteClassification
                            },
                            'Reported value': map {'pos': 4,
                                'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                            },
                            'Last year value': map {'pos': 5,
                                'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()
            return $result

    let $LCP_12_3 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.3",
            "Identification of ProductionFacility release/transfer outliers
            against previous year data at the ProductionFacility level",
            $res
    )

    (: let $asd := trace(fn:current-time(), 'started 12.4 at: ') :)
    (: C12.4 - Identification of ProductionInstallationPart emission outliers
        against previous year data at the ProductionInstallationPart level. :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else

        let $getLastYearValue := function (
            $emissionNode as element(),
            $inspireId as xs:string
        ) as xs:double {
            $docProductionInstallationParts//ProductionInstallationPart[year = $previous-year
                and concat(localId, namespace) = $inspireId]/emissionsToAir
                    [pollutant = $emissionNode/pollutant]
                        /totalPollutantQuantityTNE => functx:if-empty(0) => fn:number()

        }
        let $installationPartInspireIdsNeeded :=
            $docProductionInstallationParts//ProductionInstallationPart[year != $reporting-year
                and countryCode = $country_code]/concat(localId, namespace) => distinct-values()
        let $seq := $docRoot//ProductionInstallationPartReport[InspireId = $installationPartInspireIdsNeeded]
        let $errorType := 'warning'
        let $text := 'Reported data exceeds threshold of deviation from previous year data'
        for $part in $seq
            for $emissionNode in $part/emissionsToAir
                let $reportedValue := $emissionNode/totalPollutantQuantityTNE => functx:if-empty(0) => fn:number()
                let $lastYearValue := $getLastYearValue($emissionNode, $part/InspireId/data())
                (:let $trace := trace($reportedValue, "reportedValue: "):)
                (:let $trace := trace($lastYearValue, "lastYearValue: "):)
                let $ok := (
                    $reportedValue < $lastYearValue * 2
                    and
                    $reportedValue * 10 > $lastYearValue
                )
                return
                    if(fn:not($ok))
                    (:if(fn:false()):)
                    (:if($reportedValue > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                            'Inspire Id': map {'pos': 2, 'text': $part/scripts:prettyFormatInspireId(InspireId)},
                            'Type': map {'pos': 3, 'text': $emissionNode/pollutant => functx:substring-after-last("/")},
                            'Reported value': map {'pos': 4,
                                'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType
                            },
                            'Last year value': map {'pos': 5,
                                'text': $lastYearValue => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }
                        return scripts:generateResultTableRow($dataMap)
                    else()

    let $LCP_12_4 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.4",
            "Identification of ProductionInstallationPart emission outliers against
            previous year data at the ProductionInstallationPart level"
            , $res
    )
    (: let $asd := trace(fn:current-time(), 'started 12.5 at: ') :)
    (: C12.5 – Time series consistency for ProductionInstallationPart emissions :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else

        let $disused := (
            'http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/disused',
            'http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/decommissioned'
        )
        let $mediumCode := 'http://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/MediumCodeValue/AIR'
        let $errorType := 'warning'
        let $text := 'Pollutant release ratio threshold has been exceeded'
        let $facilitiesNeeded := $docProductionFacilities/ProductionFacility[countryCode = $country_code]
                /concat(localId, namespace)
        (:let $asd := trace($facilitiesNeeded, 'facilitiesNeeded: '):)
        let $disusedFacilities := $docProductionFacilities/ProductionFacility[year = $reporting-year
            and StatusType = $disused and countryCode = $country_code]
                /concat(localId, namespace)

(:
        let $pollutantsFromReportXML := $docRoot//ProductionFacilityReport/pollutantRelease
            [mediumCode = $mediumCode and pollutant = $validPollutants]/pollutant => distinct-values()

        let $eligibleFacilities :=(
            for $pollutant in $pollutantsFromReportXML
                let $thresholdValue := $docANNEXII/row[Codelistvalue
                    = $pollutant=>scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                        /toAir => functx:if-empty(0) => xs:decimal()
                let $asd := trace($pollutant, 'pollutant: ')
                let $asd := trace($thresholdValue, 'thresholdValue: ')
                for $pollutantRelease in $docRoot//ProductionFacilityReport[InspireId = $facilitiesNeeded]
                        /pollutantRelease[pollutant = $pollutant and mediumCode = $mediumCode]
                let $currentValue := $pollutantRelease/functx:if-empty(totalPollutantQuantityKg, 0)
                        => fn:number()
                let $inspireId := $pollutantRelease/ancestor::ProductionFacilityReport/InspireId/data()
                let $lowestValue := $docProductionFacilities/ProductionFacility[InspireId = $inspireId]
                    /pollutantRelease[mediumCode = $mediumCode and pollutant = $pollutant]
                        /totalPollutantQuantityKg => fn:min() => functx:if-empty(0) => xs:decimal()

                let $lowestFinal := fn:min(($currentValue, $lowestValue))
                let $asd := trace($inspireId, 'inspireId: ')
                let $asd := trace($lowestFinal, 'lowestValue: ')
                let $asd:= trace($lowestFinal > $thresholdValue * 20, 'eligible: ')
                return
                    if($lowestFinal > $thresholdValue * 20)
                    then $inspireId
                    else ()
        ) => distinct-values()
:)
        (:let $asd := trace($eligibleFacilities, 'eligibleFacilities: '):)

(:
        let $notEligibleFacilities := (
            for $pollutant in $pollutantsFromReportXML
                (:let $asd := trace($pollutant, 'pollutant: '):)
                (:let $asd := trace($thresholdValue, 'thresholdValue: '):)
                for $pollutantRelease in $docRoot//ProductionFacilityReport[InspireId = $eligibleFacilities
                    and InspireId = $disusedFacilities]
                        /pollutantRelease[pollutant = $pollutant]
                let $inspireId := $pollutantRelease/ancestor::ProductionFacilityReport/InspireId/data()
                let $lowestValue := $docProductionFacilities/ProductionFacility[InspireId = $inspireId
                    and year = $previous-year]
                    /pollutantRelease[mediumCode = $mediumCode and pollutant = $pollutant]
                        /totalPollutantQuantityKg => fn:min() => functx:if-empty(-1) => xs:decimal()

                (:let $asd := trace($inspireId, 'inspireId: '):)
                (:let $asd := trace($lowestValue, 'lowestValue: '):)
                return
                    if($lowestValue = 0)
                    then $inspireId
                    else ()
        ) => distinct-values()
:)
        (:let $asd := trace($notEligibleFacilities, 'notEligibleFacilities: '):)

        (:let $eligibleFacilitiesFinal := functx:value-except($eligibleFacilities, $notEligibleFacilities):)
        (:let $asd := trace($eligibleFacilitiesFinal, 'eligibleFacilitiesFinal: '):)

        for $pollutantRelease in $docRoot//ProductionFacilityReport (:[InspireId = $eligibleFacilitiesFinal]:)
                /pollutantRelease[mediumCode = $mediumCode]
            let $thresholdValue := $docANNEXII/row[Codelistvalue
                    = $pollutantRelease/pollutant => scripts:getCodelistvalueForOldCode($docPollutantLookup)]
                        /toAir => functx:if-empty(0) => xs:decimal()
            let $inspireId := $pollutantRelease/ancestor::ProductionFacilityReport/InspireId
            let $minimumValuePrev := $docProductionFacilities/ProductionFacility[concat(localId, namespace) = $inspireId/data()]
                    /pollutantRelease[mediumCode = $mediumCode and pollutant = $pollutantRelease/pollutant]
                        /totalPollutantQuantityKg => fn:min() => functx:if-empty(0) => xs:decimal()
            let $currentYearValue :=
                $pollutantRelease/totalPollutantQuantityKg => functx:if-empty(0) => xs:decimal()
            let $minimumValue := ($minimumValuePrev, $currentYearValue) => fn:min()

            let $disusedFaciliy := if($minimumValue = 0 and $inspireId = $disusedFacilities)
                then true()
                else false()

            where not($disusedFaciliy)
            where $minimumValue > $thresholdValue * 20

            let $maximumValuePrev := $docProductionFacilities/ProductionFacility[/concat(localId, namespace) = $inspireId/data()]
                    /pollutantRelease[mediumCode = $mediumCode and pollutant = $pollutantRelease/pollutant]
                        /totalPollutantQuantityKg => fn:max() => functx:if-empty(0) => xs:decimal()
            let $maximumValue := ($maximumValuePrev, $currentYearValue) => fn:max()
            let $ok := (
                $maximumValue + $minimumValue = 0
                or
                (if($minimumValue = 0 and $maximumValue > 0)
                then false()
                else $maximumValue div $minimumValue <= 10)
            )
            return
                if(not($ok))
                (:if(true()):)
                then
                    let $dataMap := map {
                        'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                        'Inspire Id': map {'pos': 2, 'text': scripts:prettyFormatInspireId($inspireId)},
                        'PollutantRelease': map {'pos': 3,
                            'text': scripts:getPollutantCode($pollutantRelease/pollutant, $docPollutantLookup),
                            'errorClass': 'td' || $errorType
                        },
                        'Current year value': map {'pos': 4, 'text': $currentYearValue},
                        'Minimum value': map {'pos': 5, 'text': $minimumValue},
                        'Maximum value': map {'pos': 6, 'text': $maximumValue}
                    }
                    return
                        scripts:generateResultTableRow($dataMap)
                else
                    ()

    let $LCP_12_5 := xmlconv:RowBuilder(
            "EPRTR-LCP 12.5",
            "Time series consistency for ProductionFacility emissions",
            $res
    )
    (: let $asd := trace(fn:current-time(), 'started 12.6 at: ') :)
    (: C12.6 - Time series consistency for ProductionInstallationPart emissions :)
    let $res :=
        if($reporting-year le 2018)
        then ()
        else

        let $pollutants := ('SO2', 'NOX', 'DUST')
        for $pollutant in $pollutants
            let $total := fn:sum(
                $docRoot//emissionsToAir[pollutant => functx:substring-after-last("/") = $pollutant]
                        /totalPollutantQuantityTNE/fn:number()
            )
            let $average3Year :=
                $docAverage//row[MemberState = $country_code and ReferenceYear = $look-up-year][1]
                    /*[fn:local-name() = 'Avg_3yr_' || $pollutant]/fn:data() => functx:if-empty(0) => fn:number()
                        => fn:round-half-to-even(1)
            (:let $asd := trace($pollutant, "pollutant: "):)
            (:let $asd := trace($total, "total: "):)
            (:let $asd := trace($average3Year, "average3Year: "):)
            let $percentage :=
                if($total > $average3Year)
                then (($total * 100) div $average3Year) - 100 => xs:decimal() => fn:round-half-to-even(1)
                else if($total < $average3Year)
                then (100 - ($total * 100) div $average3Year) => xs:decimal() => fn:round-half-to-even(1)
                else 100

            let $errorType :=
                if($total > $average3Year and $percentage > 30)
                then 'warning'
                else if($total > $average3Year and $percentage <= 30 and $percentage >= 10)
                then 'info'
                else if($total < $average3Year and $percentage > 30)
                then 'info'
                else 'ok'
            return
                if($errorType != 'ok')
                (:if(fn:true()):)
                then
                    let $dataMap := map {
                        'Details': map {
                            'pos': 1,
                            'text': 'Reported data exceeds threshold of deviation from three year average',
                            'errorClass': $errorType
                        },
                        'Pollutant': map {'pos': 2, 'text': $pollutant},
                        'Percentage': map {'pos': 3, 'text': $percentage || '%', 'errorClass': 'td' || $errorType},
                        'Total value': map {'pos': 4, 'text': $total=>xs:long()},
                        'Average 3 year': map {'pos': 5, 'text': $average3Year}
                    }
                    return scripts:generateResultTableRow($dataMap)
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
    (: let $asd := trace(fn:current-time(), 'started 13.1 at: ') :)
    (: TODO long running time :)
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

    (: let $asd := trace(fn:current-time(), 'started 13.2 at: ') :)
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

    (: let $asd := trace(fn:current-time(), 'started 13.3 at: ') :)
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
                    else $map1?($pollutant)?doc//row[CountryCode = $country_code and ReleaseMediumName = $mediumCode]
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
                            {$changePercentage=>fn:round-half-to-even(1)}%
                        </td>
                        <td title="National level count">{$reportCountOfPollutantCode}</td>
                        <td title="Previous year count">{$CountOfPollutantCode}</td>
                    </tr>
                    else
                        ()
            return
                $result:)
    let $LCP_13_3 := xmlconv:RowBuilder("EPRTR-LCP 13.3","Reported number of pollutants per medium consistency", $res)

    (: let $asd := trace(fn:current-time(), 'started 13.4 at: ') :)
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
                'countNodeName': 'TotalQuantity',
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

    (: let $asd := trace(fn:current-time(), 'started 14.1 at: ') :)
    (: C14.1 – Identification of top 10 ProductionFacility releases/transfers across Europe :)
    (:   let $res :=
        let $seqActivities := $docProductionFacilities/ProductionFacility[year = $previous-year]
                /EPRTRAnnexIActivity => distinct-values()
        let $seqPollutants := $docProductionFacilities/ProductionFacility[year = $previous-year]
                //pollutant => distinct-values()

        let $xmlPollutantRelease :=
        <data>
        {
            let $seqMediumCodes := $docProductionFacilities/ProductionFacility[year = $previous-year]
                /pollutantRelease/mediumCode => distinct-values()
            for $activity in $seqActivities,
                $pollutant in $seqPollutants,
                $mediumCode in $seqMediumCodes
                let $values :=
                    for $pol in $docProductionFacilities/ProductionFacility
                        [year = $previous-year and EPRTRAnnexIActivity = $activity]
                        /pollutantRelease[mediumCode = $mediumCode and pollutant = $pollutant]
                    order by $pol/totalPollutantQuantityKg/data() descending
                    return $pol/totalPollutantQuantityKg/data()
                let $value10th := $values[10] => functx:if-empty(0) => xs:decimal()
                return if($value10th > 0)
                then
                    <row>
                        <EPRTRAnnexIActivity>{$activity}</EPRTRAnnexIActivity>
                        <pollutant>{$pollutant}</pollutant>
                        <mediumCode>{$mediumCode}</mediumCode>
                        <value10th>{$value10th}</value10th>
                    </row>
                else ()
        }
        </data>
        (:let $asd := trace($xmlPollutantRelease, "xmlPollutantRelease: "):)

        let $xmlOffsiteWasteTransfer :=
        <data>
        {
            let $seqWasteClassification := $docProductionFacilities/ProductionFacility[year = $previous-year]
                /offsiteWasteTransfer/wasteClassification => distinct-values()
            let $seqWasteTreatment := $docProductionFacilities/ProductionFacility[year = $previous-year]
                /offsiteWasteTransfer/wasteTreatment => distinct-values()
            for $activity in $seqActivities,
                $wasteClassification in $seqWasteClassification,
                $wasteTreatment in $seqWasteTreatment
                let $values :=
                    for $pol in $docProductionFacilities/ProductionFacility
                        [year = $previous-year and EPRTRAnnexIActivity = $activity]
                        /offsiteWasteTransfer[wasteClassification = $wasteClassification
                                    and wasteTreatment = $wasteTreatment]
                    order by $pol/totalWasteQuantityTNE/data() descending
                    return $pol/totalWasteQuantityTNE/data()
                let $value10th := $values[10] => functx:if-empty(0) => xs:decimal()
                return if($value10th > 0)
                then
                    <row>
                        <EPRTRAnnexIActivity>{$activity}</EPRTRAnnexIActivity>
                        <wasteClassification>{$wasteClassification}</wasteClassification>
                        <wasteTreatment>{$wasteTreatment}</wasteTreatment>
                        <value10th>{$value10th}</value10th>
                    </row>
                else
                    ()
        }
        </data>
        (:let $asd := trace($xmlOffsiteWasteTransfer, "xmlOffsiteWasteTransfer: "):)

        let $xmlOffsitePollutantTransfer :=
        <data>
        {
            for $activity in $seqActivities,
                $pollutant in $seqPollutants
                let $values :=
                    for $pol in $docProductionFacilities/ProductionFacility
                        [year = $previous-year and EPRTRAnnexIActivity = $activity]
                        /offsitePollutantTransfer[pollutant = $pollutant]
                    order by $pol/totalPollutantQuantityKg/data() descending
                    return $pol/totalPollutantQuantityKg/data()
                let $value10th := $values[10] => functx:if-empty(0) => xs:decimal()
                return if($value10th > 0)
                then
                    <row>
                        <EPRTRAnnexIActivity>{$activity}</EPRTRAnnexIActivity>
                        <pollutant>{$pollutant}</pollutant>
                        <value10th>{$value10th}</value10th>
                    </row>
                else
                    ()
        }
        </data>
        (:let $asd := trace($xmlOffsitePollutantTransfer, "xmlOffsitePollutantTransfer: "):)

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
            let $value := $xmlPollutantRelease//row
                [EPRTRAnnexIActivity => functx:substring-after-last("/") = $EPRTRAnnexIActivity
                and pollutant => scripts:getPollutantCode($docPollutantLookup) = $pollutantTypeDataMap?pollutant
                and mediumCode => functx:substring-after-last("/") = $pollutantTypeDataMap?mediumCode]
                /value10th => functx:if-empty(0) => xs:decimal()
            return $value
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
            let $value := $xmlOffsitePollutantTransfer//row
                [EPRTRAnnexIActivity => functx:substring-after-last("/") = $EPRTRAnnexIActivity
                and pollutant => scripts:getPollutantCode($docPollutantLookup) = $pollutantTypeDataMap?pollutant]
                /value10th => functx:if-empty(0) => xs:decimal()
            return $value

        }
        let $getOffsiteWasteTransferValue := function (
            $pollutantNode as element()
        ) as map(*){
            map {
                'value': $pollutantNode/totalWasteQuantityTNE => functx:if-empty(0) => fn:number(),
                'wasteClassification':
                    let $code := $pollutantNode/wasteClassification/data() => functx:substring-after-last("/")
                    let $transboundaryTransfer := $pollutantNode/transboundaryTransfer/data()
                    return
                        if($code = 'NONHW')
                        then 'NONHW'
                        (:else if (fn:string-length($transboundaryTransfer) > 0)
                            then $code || 'OC'
                            else $code || 'IC':)
                        else 'HW',
                'wasteTreatment': $pollutantNode/wasteTreatment/text() => functx:substring-after-last("/")
            }
        }
        let $getOffsiteWasteTransferLookupValue := function (
            $pollutantTypeDataMap as map(*),
            $EPRTRAnnexIActivity as xs:string
        ) as xs:double {
            let $value := $xmlOffsiteWasteTransfer/row
                [EPRTRAnnexIActivity => functx:substring-after-last("/") = $EPRTRAnnexIActivity
                and wasteClassification => functx:substring-after-last("/") = $pollutantTypeDataMap?wasteClassification
                and wasteTreatment => functx:substring-after-last("/") = $pollutantTypeDataMap?wasteTreatment]
                /value10th => functx:if-empty(0) => xs:decimal()
            return $value

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
                    $facility/InspireId/data(),
                    $reporting-year,
                    $docProductionFacilities
            )
                for $pollutantType in $facility/*[local-name() = map:keys($map1)]
                    let $pollutantName := $pollutantType/local-name()
                    let $pollutantTypeDataMap := $map1?($pollutantName)?report($pollutantType)
                    let $reportedValue := $pollutantTypeDataMap?value
                    let $lookupTableValue := $map1?($pollutantName)?lookup($pollutantTypeDataMap, $EPRTRAnnexIActivity)
                    let $ok := $reportedValue < $lookupTableValue
                    return
                        if(not($ok))
                        (:if(false()):)
                        (:if(true()):)
                        then
                            let $dataMap := map {
                                'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                                'InspireId': map {'pos': 2, 'text': $facility/InspireId},
                                'Type': map {'pos': 3, 'text': $pollutantName || ' - ' || $getCodes($pollutantTypeDataMap)},
                                'Reported amount':
                                    map {'pos': 4, 'text': $reportedValue => xs:decimal(), 'errorClass': 'td' || $errorType},
                                'European 10th value': map {'pos': 5, 'text': $lookupTableValue => xs:decimal()}
                            }
                            return scripts:generateResultTableRow($dataMap)
                        else ()
:)
    let $res := ()
    let $LCP_14_1 := xmlconv:RowBuilder("EPRTR-LCP 14.1",
            "Identification of top 10 ProductionFacility releases/transfers across Europe",
            $res)

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
                'countNodeName': 'TotalQuantity',
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
                    else (($reportTotal * 100) div $europeanTotal) => xs:decimal() => fn:round-half-to-even(1)

                let $ok := $percentage < 90
                return
                    if(fn:not($ok))
                    (:if($reportTotal > 0):)
                    then
                        let $dataMap := map {
                            'Details': map {'pos': 1, 'text': $text, 'errorClass': $err},
                            'Type': map {'pos': 2,
                                'text': $pollutant || ' - ' || $code1 || (if($code2 = '') then '' else ' / ' || $code2)
                            },
                            'Inspire Id': map {'pos': 3, 'text': $facility/scripts:prettyFormatInspireId(InspireId)},
                            'Percentage': map {'pos': 4, 'text': $percentage || '%', 'errorClass': 'td' || $err},
                            'Reported total (in kg/year)': map {'pos': 5, 'text': $reportTotal => xs:decimal()},
                            'European total (in kg/year)': map {'pos': 6,
                                'text': $europeanTotal => xs:decimal() => fn:round-half-to-even(1)
                            }
                        }

                        return scripts:generateResultTableRow($dataMap)
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

    (: let $asd := trace(fn:current-time(), 'started 15 at: ') :)
    (:
        As a result, countries that report high biomass consumption (e.g. Sweden) may report CO2 emissions
        that exceed the values reported under the UNFCCC/EU-MMR National Inventory and this check
        will provide a false positive.
    :)
    (:  C15.1 – Comparison of PollutantReleases and EmissionsToAir to CLRTAP/NECD
        and UNFCCC/EU-MMR National Inventories    :)
    let $res :=
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
                        /*[fn:local-name() = $elemNameTotalQuantity]/functx:if-empty(fn:data(), 0)
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

    (: let $asd := trace(fn:current-time(), 'started 16 at: ') :)
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
                    <td title="Inspire Id">
                        {$elem/ancestor-or-self::*[fn:local-name() =
                                ("ProductionInstallationPartReport", "ProductionFacilityReport")]/scripts:prettyFormatInspireId(InspireId)}
                    </td>
                    <td title="Parent feature type">{fn:node-name($elem/parent::*)}</td>
                    <td title='Additional info'>{scripts:getAdditionalInformation($elem/parent::*)}</td>
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
                    <td title="Inspire Id">
                        {$elem/ancestor-or-self::*[fn:local-name() = ("ProductionInstallationPartReport")]
                                /scripts:prettyFormatInspireId(InspireId)}
                    </td>
                    <td title="Feature type">{fn:node-name($elem/parent::*)}</td>
                    <td class="tdwarning" title="Attribute name"> {fn:node-name($elem)} </td>
                    <td class="tdwarning" title="value"> {$elemValue} </td>
                </tr>

            else
                ()
    let $LCP_16_2 := xmlconv:RowBuilder("EPRTR-LCP 16.2","Percentage format compliance", $res)

    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/emissionsToAir
        let $elementName := 'totalPollutantQuantityTNE'
        return xmlconv:checkBlankValues($seq, $elementName)
    let $LCP_16_3 := xmlconv:RowBuilder("EPRTR-LCP 16.3","totalPollutantQuantityTNE blank check", $res)

    let $resA :=
        let $seq := $docRoot//ProductionFacilityReport/offsiteWasteTransfer
        let $elementName := 'totalWasteQuantityTNE'
        return xmlconv:checkBlankValues($seq, $elementName)
    let $resB :=
        let $seq := $docRoot//ProductionFacilityReport/pollutantRelease
        let $elementName := 'totalPollutantQuantityKg'
        return xmlconv:checkBlankValues($seq, $elementName)
    let $resC :=
        let $seq := $docRoot//ProductionFacilityReport/offsitePollutantTransfer
        let $elementName := 'totalPollutantQuantityKg'
        return xmlconv:checkBlankValues($seq, $elementName)
    let $LCP_16_4 := xmlconv:RowBuilder("EPRTR-LCP 16.4","totalWasteQuantityTNE, totalPollutantQuantityKg blank check", ($resA, $resB, $resC))

    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/numberOfOperatingHours
        let $errorType := 'warning'
        let $text := 'Blank or non numeric value reported'

        for $elem in $seq
        let $value := $elem/functx:if-empty(data(), '')

        let $ok := not($value = '')
            and $value castable as xs:double

        return
            if (fn:not($ok))
            then
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'Inspire Id': map {'pos': 2, 'text': $elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)},
                    'Value': map {'pos': 3, 'text': $value, 'errorClass': 'td' || $errorType}
                }
                return scripts:generateResultTableRow($dataMap)
            else
                ()
    let $LCP_16_5 := xmlconv:RowBuilder("EPRTR-LCP 16.5","numberOfOperatingHours blank check", $res)

    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/energyInput
        let $errorType := 'error'
        let $text := 'Blank value reported'

        for $elem in $seq
        let $value := $elem/energyinputTJ/functx:if-empty(data(), '')

        let $ok := not($value = '')
            (:and $value castable as xs:double:)

        return
            if (fn:not($ok))
            then
                let $dataMap := map {
                    'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
                    'Inspire Id': map {'pos': 2, 'text': $elem/ancestor::*[InspireId]/scripts:prettyFormatInspireId(InspireId)},
                    'Fuel input': map {'pos': 3, 'text': $elem/fuelInput/fuelInput => functx:substring-after-last("/")},
                    'Value': map {'pos': 4, 'text': $value, 'errorClass': 'td' || $errorType}
                }
                return scripts:generateResultTableRow($dataMap)
            else
                ()
    let $LCP_16_6 := xmlconv:RowBuilder("EPRTR-LCP 16.6","energyInput blank check", $res)

    let $res :=
        let $exclude := ('totalPollutantQuantityTNE', 'totalWasteQuantityTNE',
            'totalPollutantQuantityKg', 'numberOfOperatingHours', 'energyInput')
        let $seq := $docRoot//*[not(local-name() = $exclude) and not(*)]
        return xmlconv:checkAllBlankValues($seq)

    let $LCP_16_7 := xmlconv:RowBuilder("EPRTR-LCP 16.7", "All fields blank check", $res)

    let $res :=
        let $namespaces := $docRoot//InspireId/namespace
        let $errorType := 'info'
        let $text := 'Namespace and number of uses'

        for $namespace in fn:distinct-values($namespaces)
        let $countNamespace := count($namespaces[. = $namespace])
        let $dataMap := map {
            'Details': map {'pos': 1, 'text': $text, 'errorClass': $errorType},
            'Namespace': map {'pos': 2, 'text': $namespace},
            'Number of uses': map {
                'pos': 3,
                'text': $countNamespace,
                'errorClass': 'td' || $errorType
            }
        }
        order by $countNamespace descending

        return scripts:generateResultTableRow($dataMap)

    let $LCP_16_8 := xmlconv:RowBuilder("EPRTR-LCP 16.8", "Namespaces check", $res)

    let $LCP_16 := xmlconv:RowAggregator(
            "EPRTR-LCP 16",
            "Miscellaneous checks",
            (
                $LCP_16_1,
                $LCP_16_2,
                $LCP_16_3,
                $LCP_16_4,
                $LCP_16_5,
                $LCP_16_6,
                $LCP_16_7,
                $LCP_16_8
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

