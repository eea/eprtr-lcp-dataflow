xquery version "3.1";

(:~
: User: laszlo
: Date: 1/4/18
: Time: 12:44 PM
: To change this template use File | Settings | File Templates.
:)

module namespace scripts = "eprtr-lcp-scripts";

import module namespace functx = "http://www.functx.com" at "eprtr-lcp-functx.xq";

declare namespace act-core = 'http://inspire.ec.europa.eu/schemas/act-core/4.0';
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace EUReg = 'http://dd.eionet.europa.eu/euregistryonindustrialsites';
declare namespace GML = "http://www.opengis.net/gml";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace ogr = "http://ogr.maptools.org/";
declare namespace pf = "http://inspire.ec.europa.eu/schemas/pf/4.0";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rest = "http://basex.org/rest";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";


declare function scripts:generateResultTableRow(
    $dataMap as map(xs:string, map(*))
    (:$dataMap as map(*):)
) as element(tr) {
    <tr>
    {
        for $column in map:keys($dataMap)
        order by $dataMap?($column)?pos
        return
            <td class="{if(map:contains($dataMap?($column), 'errorClass')) then $dataMap?($column)?errorClass else ''}"
                title="{$column}">
                {$dataMap?($column)?text}
            </td>
    }
    </tr>
};

declare function scripts:getValidConcepts($value as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $vocabulary := "https://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/"
    let $url := $vocabulary || $value || "/rdf"
    return
        fn:data(fn:doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/@rdf:about)
};
declare function scripts:getValidConceptNotations($value as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $vocabulary := "https://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/"
    let $url := $vocabulary || $value || "/rdf"
    return
        fn:data(fn:doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/skos:notation)
};

declare function scripts:getCodeNotation (
    $codeUri as xs:string,
    $value as xs:string
) as xs:string {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $vocabulary := "https://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/"
    let $url := $vocabulary || $value || "/rdf"
    (:let $asd := trace($value, 'value: '):)
    (:let $asd := trace($codeUri, 'codeUri: '):)
    let $notation :=
        fn:doc($url)//skos:Concept[@rdf:about = $codeUri and adms:status/@rdf:resource = $valid]/skos:notation/text()
    (:let $asd := trace($notation, 'notation: '):)
    return
        if($notation=>fn:empty())
        then $codeUri
        else $notation

};

declare function scripts:convertToKG(
    $value as xs:double?,
    $unit as xs:string?
) as xs:double  {
    let $convertedValue :=
        if($unit=>fn:lower-case() = 'kg')
            then $value
        else if($unit=>fn:lower-case() = 'mg')
            then $value * 1000
        else if($unit=>fn:lower-case() = 'gg')
            then $value * 1000000
        else if($unit=>fn:lower-case() = 'g')
            then $value div 1000
        else
            -1
    return $convertedValue
};

declare function scripts:getGWLconvertedValue(
    $value as xs:double?,
    $GWP as xs:double?
) as xs:double {
    if($value castable as xs:double and $GWP castable as xs:double)
    then $value div $GWP
    else -1
};

declare function scripts:getCLRTAPtotals(
        $docCLRTAPdata as document-node(),
        $docCLRTAPpollutantLookup as document-node(),
        $pollutantCode as xs:string,
        $elem as xs:string,
        $country_code as xs:string,
        $look-up-year as xs:double
) as xs:double {
    let $CLRTAPpollutant_lookup :=
        let $nodeName := if($elem = 'pollutantRelease')
            then 'EPRTRequivalent'
            else 'LCPequivalent'
        return $docCLRTAPpollutantLookup//row[*[fn:local-name() = $nodeName] = $pollutantCode]
                /CLRTAP_pollutant_lookup/text()
    (:let $asd := trace($pollutantCode, 'pollutantCode: '):)
    (:let $asd := trace($elem, 'elem: '):)
    (:let $asd := trace($country_code, 'country_code: '):)
    (:let $asd := trace($CLRTAPpollutant_lookup, 'CLRTAPpollutant_lookup: '):)
    let $CLRTAPtotal := $docCLRTAPdata
            //row[Country_code = $country_code and Year = $look-up-year and Pollutant_name = $CLRTAPpollutant_lookup]
            /SumOfEmissions => fn:number()
    (:let $asd := trace($CLRTAPtotal, 'CLRTAPtotal: '):)
    let $CLRTAPunit := $docCLRTAPdata
            //row[Country_code = $country_code and Year = $look-up-year and Pollutant_name = $CLRTAPpollutant_lookup]
            /Unit/text()
    (:let $asd := trace($CLRTAPunit, 'CLRTAPunit: '):)
    (:let $asd := trace(scripts:convertToKG($CLRTAPtotal, $CLRTAPunit), 'convertToKG: '):)
    return scripts:convertToKG($CLRTAPtotal, $CLRTAPunit)
};

declare function scripts:getUNFCCtotals(
        $docUNFCCdata as document-node(),
        $docUNFCCpollutantLookup as document-node(),
        $pollutantCode as xs:string,
        $country_code as xs:string,
        $look-up-year as xs:double
) as xs:double {
    let $UNFCCpollutant_lookup :=
        $docUNFCCpollutantLookup//row[EPRTRequivalent = $pollutantCode]/UNFCCC_pollutant_lookup/text()
    let $GWPconversionfactor :=
        $docUNFCCpollutantLookup//row[EPRTRequivalent = $pollutantCode]/GWPconversionfactor/text()
    (:let $asd := trace($pollutantCode, 'pollutantCode: '):)
    (:let $asd := trace($elem, 'elem: '):)
    (:let $asd := trace($country_code, 'country_code: '):)
    (:let $asd := trace($UNFCCpollutant_lookup, 'UNFCCpollutant_lookup: '):)
    (:let $asd := trace($GWPconversionfactor, 'GWPconversionfactor: '):)
    let $UNFCCtotal := $docUNFCCdata
        //row[Country_code = $country_code and Year = $look-up-year and Pollutant_name = $UNFCCpollutant_lookup]
        /SumOfemissions
    (:let $asd := trace($UNFCCtotal, 'UNFCCtotal: '):)
    (:let $asd := trace(scripts:getGWLconvertedValue($UNFCCtotal, $GWPconversionfactor), 'getGWLconvertedValue: '):)
    return scripts:getGWLconvertedValue($UNFCCtotal, $GWPconversionfactor) => scripts:convertToKG('Gg')

};

declare function scripts:getreportCountOfPollutantWasteTransfer(
    $code1 as xs:string,
    $code2 as xs:string,
    $doc as document-node(),
    $pollutant as xs:string
) as xs:double{
    if($code2 = 'CONFIDENTIAL')
    then
        if($code1 = 'NON-HW')
        then $doc//*[fn:local-name() = $pollutant and functx:substring-after-last(wasteClassification, "/") = 'NONHW'
                and fn:string-length(confidentialityReason) > 0] => fn:count()
        else if($code1 = 'HWIC')
        then $doc//*[fn:local-name() = $pollutant and wasteClassification=>functx:substring-after-last("/") = 'HW'
                and confidentialityReason => fn:string-length() > 0
                and transboundaryTransfer/fn:data() => fn:string-length() = 0] => fn:count()
        else if($code1 = 'HWOC')
        then $doc//*[fn:local-name() = $pollutant and wasteClassification=>functx:substring-after-last("/") = 'HW'
                and confidentialityReason => fn:string-length() > 0
                and transboundaryTransfer/fn:data() => fn:string-length() > 0] => fn:count()
        else -1
    else
        if($code1 = 'NON-HW')
        then $doc//*[fn:local-name() = $pollutant and wasteClassification=>functx:substring-after-last("/") = 'NONHW'
                (:and confidentialityReason => fn:string-length() = 0:)
                and wasteTreatment => functx:substring-after-last("/") = $code2] => fn:count()
        else if($code1 = 'HWIC')
        then $doc//*[fn:local-name() = $pollutant and wasteClassification=>functx:substring-after-last("/") = 'HW'
                and wasteTreatment => functx:substring-after-last("/") = $code2
                (:and confidentialityReason => fn:string-length() = 0:)
                and transboundaryTransfer/fn:data() => fn:string-length() = 0] => fn:count()
        else if($code1 = 'HWOC')
        then $doc//*[fn:local-name() = $pollutant and wasteClassification=>functx:substring-after-last("/") = 'HW'
                and wasteTreatment => functx:substring-after-last("/") = $code2
                (:and confidentialityReason => fn:string-length() = 0:)
                and transboundaryTransfer/fn:data() => fn:string-length() > 0] => fn:count()
        else -1
};
declare function scripts:getCountOfPollutant(
    $code1 as xs:string,
    $code2 as xs:string,
    $map as map(*),
    $country_code as xs:string,
    $pollutant as xs:string,
    $look-up-year as xs:double
) as xs:double {
    if($pollutant = 'offsitePollutantTransfer' or ($pollutant = 'offsiteWasteTransfer' and $code1 = ''))
    then $map?doc//row[CountryCode = $country_code and ReportingYear = $look-up-year]
            /*[fn:local-name() = $map?countNodeName] => functx:if-empty(0) => fn:number()
    else if($pollutant = 'pollutantRelease')
        then $map?doc//row[CountryCode = $country_code and ReportingYear = $look-up-year and ReleaseMediumCode = $code1]
                /*[fn:local-name() = $map?countNodeName] => functx:if-empty(0) => fn:number()
    else
        $map?doc//row[CountryCode = $country_code and ReportingYear = $look-up-year
                and WasteTypeCode = $code1 and WasteTreatmentCode = $code2]
            /*[fn:local-name() = $map?countNodeName] => functx:if-empty(0) => fn:number()
};
declare function scripts:getreportCountOfPollutantDistinct(
    $code1 as xs:string,
    $code2 as xs:string,
    $doc as document-node(),
    $pollutant as xs:string
) as xs:double {
    if($pollutant = 'offsitePollutantTransfer')
    then $doc//*[fn:local-name() = $pollutant]/pollutant => fn:distinct-values() => fn:count()
    else if($pollutant = 'pollutantRelease')
        then $doc//*[fn:local-name() = $pollutant and mediumCode=>functx:substring-after-last("/") = $code1]
                /pollutant => fn:distinct-values() => fn:count()
    else
        -1
};
declare function scripts:getreportCountOfPollutant(
    $code1 as xs:string,
    $code2 as xs:string,
    $doc as document-node(),
    $pollutant as xs:string
) as xs:double {
    if($pollutant = 'offsitePollutantTransfer')
    then $doc//*[fn:local-name() = $pollutant]/pollutant => fn:count()
    else if($pollutant = 'pollutantRelease')
        then $doc//*[fn:local-name() = $pollutant and mediumCode=>functx:substring-after-last("/") = $code1]
                /pollutant => fn:count()
    else
        scripts:getreportCountOfPollutantWasteTransfer($code1, $code2, $doc, $pollutant)
};
declare function scripts:getreportCountOfFacilities(
    $code1 as xs:string,
    $code2 as xs:string,
    $doc as document-node(),
    $pollutant as xs:string
) as xs:double {
    if($pollutant = 'offsitePollutantTransfer')
    then $doc//ProductionFacilityReport[*[fn:local-name() = $pollutant]/pollutant]/InspireId/fn:data()
        => fn:distinct-values() => fn:count()
    else if($pollutant = 'pollutantRelease')
        then $doc//ProductionFacilityReport[*[fn:local-name() = $pollutant]
                /functx:substring-after-last(mediumCode, "/") = $code1]/InspireId/fn:data()
        => fn:distinct-values() => fn:count()
    else
        $doc//ProductionFacilityReport[*[fn:local-name() = $pollutant]/wasteClassification]/InspireId/fn:data()
        => fn:distinct-values() => fn:count()
};

declare function scripts:compareNumberOfPollutants(
    $map1 as map(xs:string, map(*)),
    $country_code as xs:string,
    $docRoot as document-node()
) as element()* {
    let $look-up-year := $docRoot//reportingYear => number() - 2
    (:let $asd := trace(map:keys($map1),'keys: '):)
    (:let $asd := trace(map:keys($map1?('pollutantRelease')?filters),'keys: '):)
    for $pollutant in map:keys($map1)
        let $keys := map:keys($map1?($pollutant)?filters)
        (:for $filter in map:keys($map1?($pollutant)?filters):)
        (:let $asd := trace($keys[1],'keysSEQ1: '):)
        (:let $asd := trace($keys[2],'keysSEQ2: '):)
        (:let $asd := trace(map:keys($map1?($pollutant)?filters),'keys: '):)
        (:let $asd := trace($map1?($pollutant)?filters?1,'keys: '):)
        for $code1 in $map1?($pollutant)?filters?code1,
            $code2 in $map1?($pollutant)?filters?code2
            (:let $asd := trace($pollutant, 'pollutant: '):)
            (:let $asd := trace($code1, 'code1: '):)
            (:let $asd := trace($code2, 'code2: '):)
            let $result :=
                let $CountOfPollutantCode := $map1?($pollutant)?countFunction(
                        $code1,
                        $code2,
                        $map1?($pollutant),
                        $country_code,
                        $pollutant,
                        $look-up-year
                    )
                let $reportCountOfPollutantCode := $map1?($pollutant)?reportCountFunction(
                        $code1,
                        $code2,
                        $docRoot,
                        $pollutant
                    )
                (:let $asd := trace($CountOfPollutantCode, 'CountOfPollutantCode: '):)
                (:let $asd := trace($reportCountOfPollutantCode, 'reportCountOfPollutantCode: '):)
                let $changePercentage :=
                    (100-(($reportCountOfPollutantCode * 100) div $CountOfPollutantCode)) => fn:abs()
                (:let $asd := trace($changePercentage, 'changePercentage: '):)
                let $ok := (
                    $changePercentage <= 50
                    or
                    $CountOfPollutantCode = 0
                )
                let $errorType :=
                    if($changePercentage > 100)
                    then 'warning'
                    else 'info'
                return
                    if(fn:not($ok))
                    (:if(true()):)
                    then
                    <tr>
                        <td class='{$errorType}' title="Details">
                            Number of reported pollutants changes by more than {
                            if($errorType = 'warning')
                            then '100%' else '50%'
                        }
                        </td>
                        <td title="Polutant">
                            {$pollutant} {if($code1 = '') then '' else ' - '||$code1}
                            {if($code2 = '') then '' else ' / '|| $code2}
                        </td>
                        <td class="td{$errorType}" title="Change percentage">
                            {$changePercentage =>fn:round-half-to-even(2)}%
                        </td>
                        <td title="National level count">{$reportCountOfPollutantCode}</td>
                        <td title="Previous year count">{$CountOfPollutantCode}</td>
                    </tr>
                    else
                        ()
            return
                $result

};

declare function scripts:getreportFacilityTotalsWasteTransfer(
    $code1 as xs:string,
    $code2 as xs:string,
    $facility as element()
) as xs:double{
    if($code1 = 'NON-HW')
    then $facility//offsiteWasteTransfer[wasteClassification=>functx:substring-after-last("/") = 'NONHW'
            and wasteTreatment => functx:substring-after-last("/") = $code2]/totalWasteQuantityTNE => fn:sum()
    else if($code1 = 'HWIC')
    then $facility//offsiteWasteTransfer[wasteClassification=>functx:substring-after-last("/") = 'HW'
            and wasteTreatment => functx:substring-after-last("/") = $code2
            and transboundaryTransfer/fn:data() => fn:string-length() = 0]/totalWasteQuantityTNE => fn:sum()
    else if($code1 = 'HWOC')
    then $facility//offsiteWasteTransfer[wasteClassification=>functx:substring-after-last("/") = 'HW'
            and wasteTreatment => functx:substring-after-last("/") = $code2
            and transboundaryTransfer/fn:data() => fn:string-length() > 0]/totalWasteQuantityTNE => fn:sum()
    else -1
};
declare function scripts:getEuropeanTotals(
    $map1 as map(*),
    $code1 as xs:string,
    $code2 as xs:string,
    $look-up-year as xs:double,
    $pollutant as xs:string
) as xs:double {
    if($pollutant = 'pollutantRelease')
    then $map1?doc//row[Year = $look-up-year and PollutantCode = $code1 and ReleaseMediumCode = $code2]
        /*[fn:local-name() = $map1?countNodeName] => functx:if-empty(0) => fn:number()
    else if($pollutant = 'offsitePollutantTransfer')
    then $map1?doc//row[Year = $look-up-year and PollutantCode = $code1]
        /*[fn:local-name() = $map1?countNodeName] => functx:if-empty(0) => fn:number()
    else if($pollutant = 'offsiteWasteTransfer')
    then $map1?doc//row[Year = $look-up-year and WasteTypeCode = $code1 and WasteTreatmentCode = $code2]
        /*[fn:local-name() = $map1?countNodeName] => functx:if-empty(0) => fn:number()
    else -1
};
declare function scripts:getreportFacilityTotals (
    $code1 as xs:string,
    $code2 as xs:string,
    $facility as element(),
    $pollutant as xs:string
) as xs:double {
    if($pollutant = 'offsitePollutantTransfer')
    then $facility//offsitePollutantTransfer[pollutant=>scripts:getCodeNotation('EPRTRPollutantCodeValue') = $code1]
            /totalPollutantQuantityKg => fn:sum()
    else if($pollutant = 'pollutantRelease')
        then $facility//pollutantRelease[mediumCode=>functx:substring-after-last("/") = $code2
                and pollutant=>scripts:getCodeNotation('EPRTRPollutantCodeValue')  = $code1]
                /totalPollutantQuantityKg => fn:sum()
    else
        scripts:getreportFacilityTotalsWasteTransfer($code1, $code2, $facility)
};
