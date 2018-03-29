xquery version "3.0";

(:~
: User: laszlo
: Date: 1/4/18
: Time: 12:44 PM
: To change this template use File | Settings | File Templates.
:)

module namespace scripts = "eprtr-lcp-scripts";

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

declare function scripts:getValidConcepts($value as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $vocabulary := "https://dd.eionet.europa.eu/vocabulary/EPRTRandLCP/"
    let $url := $vocabulary || $value || "/rdf"
    return
        data(doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/@rdf:about)
};

declare function scripts:getCodeNotation (
    $value as xs:string,
    $codeUri as xs:string
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
        $country_code as xs:string
) as xs:double {
    let $CLRTAPpollutant_lookup :=
        let $nodeName := if($elem = 'pollutantRelease')
            then 'EPRTRequivalent'
            else 'LCPequivalent'
        return $docCLRTAPpollutantLookup//row[*[local-name() = $nodeName] = $pollutantCode]
                /CLRTAP_pollutant_lookup/text()
    (:let $asd := trace($pollutantCode, 'pollutantCode: '):)
    (:let $asd := trace($elem, 'elem: '):)
    (:let $asd := trace($country_code, 'country_code: '):)
    (:let $asd := trace($CLRTAPpollutant_lookup, 'CLRTAPpollutant_lookup: '):)
    let $CLRTAPtotal :=
        $docCLRTAPdata//row[Country_code = $country_code and Pollutant_name = $CLRTAPpollutant_lookup]
                /SumOfEmissions=>number()
    (:let $asd := trace($CLRTAPtotal, 'CLRTAPtotal: '):)
    let $CLRTAPunit :=
        $docCLRTAPdata//row[Country_code = $country_code and Pollutant_name = $CLRTAPpollutant_lookup]/Unit/text()
    (:let $asd := trace($CLRTAPunit, 'CLRTAPunit: '):)
    (:let $asd := trace(scripts:convertToKG($CLRTAPtotal, $CLRTAPunit), 'convertToKG: '):)
    return scripts:convertToKG($CLRTAPtotal, $CLRTAPunit)
};

declare function scripts:getUNFCCtotals(
        $docUNFCCdata as document-node(),
        $docUNFCCpollutantLookup as document-node(),
        $pollutantCode as xs:string,
        $elem as xs:string,
        $country_code as xs:string
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
    let $UNFCCtotal :=
        $docUNFCCdata//row[Country_code = $country_code and Pollutant_name = $UNFCCpollutant_lookup]/SumOfemissions
    (:let $asd := trace($UNFCCtotal, 'UNFCCtotal: '):)
    (:let $asd := trace(scripts:getGWLconvertedValue($UNFCCtotal, $GWPconversionfactor), 'getGWLconvertedValue: '):)
    return scripts:getGWLconvertedValue($UNFCCtotal, $GWPconversionfactor)

};