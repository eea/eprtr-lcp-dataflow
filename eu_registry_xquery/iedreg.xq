xquery version "3.1" encoding "utf-8";

(:~

 : -------------------------------------------
 : EU Registry on Industrial Sites QA/QC rules
 : -------------------------------------------

 : Copyright 2017 European Environment Agency (https://www.eea.europa.eu/)
 :
 : Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
 :
 : THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

 : Author: Spyros Ligouras <spyros@ligouras.com>
 : Date: October - December 2017

 :)

module namespace iedreg = "http://cdrtest.eionet.europa.eu/help/ied_registry";

declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";

(:~
 : --------------
 : Util functions
 : --------------
 :)

declare function iedreg:getNoDetails(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not implemented yet</span>
            <br/>
            <span class="iedreg">This check is still under development</span>
        </div>
    </div>
};

declare function iedreg:getErrorDetails(
        $code as xs:QName,
        $description as xs:string?
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg red merror">
            <span class="iedreg nowrap header">Error <a href="https://www.w3.org/2005/xqt-errors/">{$code}</a></span>
            <br/>
            <span class="iedreg">{$description}</span>
        </div>
    </div>
};

declare function iedreg:renderResult(
        $refcode as xs:string,
        $rulename as xs:string,
        $type as xs:string,
        $details as element()*
) {
    let $id := random:integer(65536)

    let $label :=
        <label class="iedreg" for="toggle-{$id}">
            <span class="iedreg link">More...</span>
        </label>

    let $toggle :=
        <input class="iedreg toggle" id="toggle-{$id}" type="checkbox" />

    return
        <div class="iedreg row">
            <div class="iedreg col outer noborder">

                <!-- report table -->
                <div class="iedreg table">
                    <div class="iedreg row">
                        <div class="iedreg col ten center middle">
                            <span class="iedreg medium {$type}">{$refcode}</span>
                        </div>

                        <div class="iedreg col left middle">
                            <span class="iedreg">{$rulename}</span>
                        </div>

                        <div class="iedreg col quarter right middle">
                            {if ($type = 'error') then
                                <span class="iedreg nowrap">1 error</span>
                            else
                                <span class="iedreg nowrap">1 message</span>
                            }
                        </div>

                        <div class="iedreg col ten center middle">
                            {$label}
                        </div>
                    </div>
                </div>

                <!-- details table -->
                {$toggle, $details}
            </div>
        </div>
};

declare function iedreg:notYet(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := iedreg:getNoDetails()
    return iedreg:renderResult($refcode, $rulename, 'none', $details)
};

declare function iedreg:failsafeWrapper(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $checkFunc as function(xs:string, xs:string, element()) as element()*
) as element()* {
    try {
        $checkFunc($refcode, $rulename, $root)
    } catch * {
        let $details := iedreg:getErrorDetails($err:code, $err:description)
        return iedreg:renderResult($refcode, $rulename, 'error', $details)
    }
};

(:~
 : --------------
 : html functions
 : --------------
 :)

declare function iedreg:css() as element()* {
    <style>
        <![CDATA[
pre.iedreg { display: inline }

div.iedreg { box-sizing: border-box; font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; font-size: 14px; color: #333 }
div.iedreg.header { font-size: 16px; font-weight: 500; margin: 0.8em 0 0.4em 0 }

div.iedreg.table { display: table; width: 100%; border-collapse: collapse }
div.iedreg.row { display: table-row; }
div.iedreg.col { display: table-cell; padding: 0.4em; border: 1pt solid #aaa }

div.iedreg.inner { width: 80%; margin-left: 10%; margin-top: 0.4em; margin-bottom: 0.6em }
div.iedreg.outer { padding-bottom: 0; border: 1pt solid #888 }
div.iedreg.inner { border: 1pt solid #aaa }
div.iedreg.parent { margin-bottom: 1.5em }

div.iedreg.th { border-bottom: 2pt solid #000; font-weight: 600 }
div.iedreg.error { background-color: #fdf7f7; border-bottom: 2pt solid #d9534f }
div.iedreg.warning { background-color: #faf8f0; border-bottom: 2pt solid #f0ad4e }
div.iedreg.info { background-color: #f4f8fa; border-bottom: 2pt solid #5bc0de }

div.iedreg.red { background-color: #fdf7f7; color: #b94a48 }
div.iedreg.yellow { background-color: #faf8f0; color: #8a6d3b }
div.iedreg.blue { background-color: #f4f8fa; color: #34789a }
div.iedreg.gray { background-color: #eee; color: #555 }

div.iedreg.msg { margin-top: 1em; margin-bottom: 1em; padding: 1em 2em }
div.iedreg.msg.merror { border-color: #d9534f }
div.iedreg.msg.mwarning { border-color: #f0ad4e }
div.iedreg.msg.minfo { border-color: #5bc0de }
div.iedreg.msg.mnone { border-color: #ccc }

div.iedreg.nopadding { padding: 0 }
div.iedreg.nomargin { margin: 0 }
div.iedreg.noborder { border: 0 }

div.iedreg.left { text-align: left }
div.iedreg.center { text-align: center }
div.iedreg.right { text-align: right }

div.iedreg.top { vertical-align: top }
div.iedreg.middle { vertical-align: middle }
div.iedreg.bottom { vertical-align: bottom }

div.iedreg.ten { width: 10%; }
div.iedreg.quarter { width: 25%; }
div.iedreg.half { width: 50%; }

input[type=checkbox].iedreg { display:none }
input[type=checkbox].iedreg + div.iedreg { display:none }
input[type=checkbox].iedreg:checked + div.iedreg { display: block }

span.iedreg { display:inline-block }

span.iedreg.nowrap { white-space: nowrap }
span.iedreg.link { cursor: pointer; cursor: hand; text-decoration: underline }

span.iedreg.big { padding: 0.1em 0.9em }
span.iedreg.medium { padding: 0.1em 0.5em }
span.iedreg.small { padding: 0.1em }

span.iedreg.header { display: block; font-size: 16px; font-weight: 600 }

span.iedreg.error { color: #fff; background-color: #d9534f }
span.iedreg.warning { color: #fff; background-color: #f0ad4e }
span.iedreg.info { color: #fff; background-color: #5bc0de }
span.iedreg.pass { color: #fff; background-color: #5cb85c }
span.iedreg.none { color: #fff; background-color: #999 }
]]>
    </style>
};

(:~
 : 1. CODE LIST CHECKS
 :)

declare function iedreg:runChecks01($root as element()) as element()* {
    let $rulename := '1. CODE LIST CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C1.1", "EPRTRAnnexIActivity mainActivity consistency", $root, scripts:checkMainEPRTRAnnexIActivity#3),
        iedreg:failsafeWrapper("C1.2", "EPRTRAnnexIActivity otherActivity consistency", $root, scripts:checkOtherEPRTRAnnexIActivity#3),
        iedreg:failsafeWrapper("C1.3", "IEDAnnexIActivity mainActivity consistency", $root, scripts:checkMainIEDAnnexIActivity#3),
        iedreg:failsafeWrapper("C1.4", "IEDAnnexIActivity otherActivity consistency", $root, scripts:checkOtherIEDAnnexIActivity#3),
        iedreg:failsafeWrapper("C1.5", "CountryId consistency", $root, scripts:checkCountryId#3),
        iedreg:failsafeWrapper("C1.6", "reasonValue consistency", $root, scripts:checkReasonValue#3)
    }</div>
};

(:~
 : 2. INSPIRE ID CHECKS
 :)

declare function iedreg:runChecks02($root as element()) as element()* {
    let $rulename := '2. INSPIRE ID CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C2.1", "High proportion of new inspireIds", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C2.2", "ProductionSite inspireId uniqueness", $root, scripts:checkProductionSiteUniqueness#3),
        iedreg:failsafeWrapper("C2.3", "ProductionFacility inspireId uniqueness", $root, scripts:checkProductionFacilityUniqueness#3),
        iedreg:failsafeWrapper("C2.4", "ProductionInstallation inspireId uniqueness", $root, scripts:checkProductionInstallationUniqueness#3),
        iedreg:failsafeWrapper("C2.5", "ProductionInstallationPart inspireId uniqueness", $root, scripts:checkProductionInstallationPartUniqueness#3)
    }</div>
};

(:~
 : 3. DUPLICATE IDENTIFICATION CHECKS
 :)

declare function iedreg:runChecks03($root as element()) as element()* {
    let $rulename := '3. DUPLICATE IDENTIFICATION CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C3.1", "Identification of ProductionSite duplicates", $root, scripts:checkProductionSiteDuplicates#3),
        iedreg:failsafeWrapper("C3.2", "Identification of ProductionFacility duplicates", $root, scripts:checkProductionFacilityDuplicates#3),
        iedreg:failsafeWrapper("C3.3", "Identification of ProductionInstallation duplicates", $root, scripts:checkProductionInstallationDuplicates#3),
        iedreg:failsafeWrapper("C3.4", "Identification of ProductionInstallationPart duplicates", $root, scripts:checkProductionInstallationPartDuplicates#3),
        iedreg:failsafeWrapper("C3.5", "Identification of ProductionSite duplicates within the database", $root, scripts:checkProductionSiteDatabaseDuplicates#3),
        iedreg:failsafeWrapper("C3.6", "Identification of ProductionFacility duplicates within the database", $root, scripts:checkProductionFacilityDatabaseDuplicates#3),
        iedreg:failsafeWrapper("C3.7", "Identification of ProductionInstallation duplicates within the database", $root, scripts:checkProductionInstallationDatabaseDuplicates#3),
        iedreg:failsafeWrapper("C3.8", "Identification of ProductionInstallationPart duplicates within the database", $root, scripts:checkProductionInstallationPartDatabaseDuplicates#3),
        iedreg:failsafeWrapper("C3.9", "Missing ProductionSites, previous submissions", $root, scripts:checkMissingProductionSites#3),
        iedreg:failsafeWrapper("C3.10", "Missing ProductionFacilities, previous submissions", $root, scripts:checkMissingProductionFacilities#3),
        iedreg:failsafeWrapper("C3.11", "Missing ProductionInstallations, previous submissions", $root, scripts:checkMissingProductionInstallations#3),
        iedreg:failsafeWrapper("C3.12", "Missing ProductionInstallationsParts, previous submissions", $root, scripts:checkMissingProductionInstallationParts#3)
    }</div>
};

(:~
 : 4. GEOGRAPHICAL AND COORDINATE CHECKS
 :)

declare function iedreg:runChecks04($root as element()) as element()* {
    let $rulename := '4. GEOGRAPHICAL AND COORDINATE CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C4.1", "ProductionSite radius", $root, scripts:checkProdutionSiteRadius#3),
        iedreg:failsafeWrapper("C4.2", "ProductionFacility radius", $root, scripts:checkProdutionFacilityRadius#3),
        iedreg:failsafeWrapper("C4.3", "ProductionInstallation radius", $root, scripts:checkProdutionInstallationRadius#3),
        iedreg:failsafeWrapper("C4.4", "Coordinates to country comparison", $root, iedreg:notYet#3),
        (:iedreg:failsafeWrapper("C4.4", "Coordinates to country comparison", $root, scripts:checkCountryBoundary#3),:)
        iedreg:failsafeWrapper("C4.5", "Coordinate precision completeness", $root, scripts:checkCoordinatePrecisionCompleteness#3),
        iedreg:failsafeWrapper("C4.6", "Coordinate continuity", $root, iedreg:notYet#3),
        (:iedreg:failsafeWrapper("C4.7", "ProductionSite to ProductionFacility coordinate comparison", $root, scripts:checkProdutionSiteBuffers#3),:)
        iedreg:failsafeWrapper("C4.7", "ProductionSite to ProductionFacility coordinate comparison", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C4.8", "ProductionInstallation to ProductionInstallationPart coordinate comparison", $root, scripts:checkProdutionInstallationPartCoords#3)
    }</div>
};

(:~
 : 5. ACTIVITY CHECKS
 :)

declare function iedreg:runChecks05($root as element()) as element()* {
    let $rulename := '5. ACTIVITY CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C5.1", "EPRTRAnnexIActivity uniqueness", $root, scripts:checkEPRTRAnnexIActivityUniqueness#3),
        iedreg:failsafeWrapper("C5.2", "EPRTRAnnexIActivity continuity", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C5.3", "IEDAnnexIActivity uniqueness", $root, scripts:checkIEDAnnexIActivityUniqueness#3),
        iedreg:failsafeWrapper("C5.4", "IEDAnnexIActivity continuity", $root, iedreg:notYet#3)
    }</div>
};

(:~
 : 6. STATUS CHECKS
 :)

declare function iedreg:runChecks06($root as element()) as element()* {
    let $rulename := '6. STATUS CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C6.1", "Decommissioned StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDecommissionedStatus#3),
        iedreg:failsafeWrapper("C6.2", "Decommissioned StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDecommissionedStatus#3),
        iedreg:failsafeWrapper("C6.3", "Disused StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDisusedStatus#3),
        iedreg:failsafeWrapper("C6.4", "Disused StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDisusedStatus#3),
        iedreg:failsafeWrapper("C6.5", "Decommissioned to functional plausibility", $root, iedreg:notYet#3)
    }</div>
};

(:~
 : 7. DATE CHECKS
 :)

declare function iedreg:runChecks07($root as element()) as element()* {
    let $rulename := '7. DATE CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C7.1", "dateOfStartOfOperation comparison", $root, scripts:checkDateOfStartOfOperation#3),
        iedreg:failsafeWrapper("C7.2", "dateOfStartOfOperation LCP restriction", $root, scripts:checkDateOfStartOfOperationLCP#3),
        iedreg:failsafeWrapper("C7.3", "dateOfStartOfOperation to dateOfGranting comparison", $root, scripts:checkDateOfGranting#3),
        iedreg:failsafeWrapper("C7.4", "dateOfGranting plausibility", $root, scripts:checkDateOfLastReconsideration#3),
        iedreg:failsafeWrapper("C7.5", "dateOfLastReconsideration plausibility", $root, scripts:checkDateOfLastUpdate#3)
    }</div>
};

(:~
 : 8. PERMITS & COMPETENT AUTHORITY CHECKS
 :)

declare function iedreg:runChecks08($root as element()) as element()* {
    let $rulename := '8. PERMITS &amp; COMPETENT AUTHORITY CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C8.1", "competentAuthorityInspections to inspections comparison", $root, scripts:checkInspections#3),
        iedreg:failsafeWrapper("C8.2", "competentAuthorityPermits and permit field comparison", $root, scripts:checkPermit#3),
        iedreg:failsafeWrapper("C8.3", "PermitURL to dateOfGranting comparison", $root, iedreg:notYet#3)
    }</div>
};

(:~
 : 9. DEROGATION CHECKS
 :)

declare function iedreg:runChecks09($root as element()) as element()* {
    let $rulename := '9. DEROGATION CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C9.1", "BATDerogationIndicitor to dateOfGranting comparison", $root, scripts:checkBATPermit#3),
        iedreg:failsafeWrapper("C9.2", "dateOfGranting to Transitional National Plan comparison", $root, scripts:checkArticle32#3),
        iedreg:failsafeWrapper("C9.3", "Limited lifetime derogation to reportingYear comparison", $root, scripts:checkArticle33#3),
        iedreg:failsafeWrapper("C9.4", "District heating plants derogation to reportingYear comparison", $root, scripts:checkArticle35#3),
        iedreg:failsafeWrapper("C9.5", "Limited life time derogation continuity", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C9.6", "District heat plant derogation continuity", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C9.7", "Transitional National Plan derogation continuity", $root, iedreg:notYet#3)
    }</div>
};

(:~
 : 10. LCP & WASTE INCINERATOR CHECKS
 :)

declare function iedreg:runChecks10($root as element()) as element()* {
    let $rulename := '10. LCP &amp; WASTE INCINERATOR CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C10.1", "otherRelevantChapters to plantType comparison", $root, scripts:checkRelevantChapters#3),
        iedreg:failsafeWrapper("C10.2", "LCP plantType", $root, scripts:checkLCP#3),
        iedreg:failsafeWrapper("C10.3", "totalRatedThermalInput plausibility", $root, scripts:checkRatedThermalInput#3),
        iedreg:failsafeWrapper("C10.4", "WI plantType", $root, scripts:checkWI#3),
        iedreg:failsafeWrapper("C10.5", "nominalCapacity plausibility", $root, scripts:checkNominalCapacity#3)
    }</div>
};

(:~
 : 11. CONFIDENTIALITY CHECKS
 :)

declare function iedreg:runChecks11($root as element()) as element()* {
    let $rulename := "11. CONFIDENTIALITY CHECKS"

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C11.1", "Confidentiality restriction", $root, scripts:checkConfidentialityRestriction#3),
        iedreg:failsafeWrapper("C11.2", "Confidentiality overuse", $root, scripts:checkConfidentialityOveruse#3)
    }</div>
};

(:~
 : 12. OTHER IDENTIFIERS & MISCELLANEOUS CHECKS
 :)

declare function iedreg:runChecks12($root as element()) as element()* {
    let $rulename := '12. OTHER IDENTIFIERS &amp; MISCELLANEOUS CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C12.1", "ETSIdentifier validity", $root, scripts:checkETSIdentifier#3),
        iedreg:failsafeWrapper("C12.2", "eSPIRSId validity", $root, scripts:checkeSPIRSIdentifier#3),
        iedreg:failsafeWrapper("C12.3", "ProductionFacility facilityName to parentCompanyName comparison", $root, scripts:checkFacilityName#3),
        iedreg:failsafeWrapper("C12.4", "nameOfFeature", $root, iedreg:notYet#3),
        iedreg:failsafeWrapper("C12.5", "reportingYear plausibility", $root, scripts:checkReportingYear#3),
        iedreg:failsafeWrapper("C12.6", "electronicMailAddress format", $root, scripts:checkElectronicMailAddressFormat#3),
        iedreg:failsafeWrapper("C12.7", "Lack of facility address", $root, scripts:checkFacilityAddress#3),
        iedreg:failsafeWrapper("C12.8", "Character string space identification", $root, scripts:checkWhitespaces#3)
    }</div>
};

declare function iedreg:runChecks($url as xs:string) as element()*
{
    let $doc := doc($url)
    let $root := $doc/child::gml:FeatureCollection

    let $envelopeURL := functx:substring-before-last-match($url, '/') || '/xml'

    let $add-envelope-url := %updating function ($root, $url ) {
insert node <gml:metaDataProperty xlink:href="{$url}"></gml:metaDataProperty> as first into $root
}

let $root := $root update (
updating $add-envelope-url(., $envelopeURL)
)

return (
iedreg:runChecks01($root),
iedreg:runChecks02($root),
iedreg:runChecks03($root),
iedreg:runChecks04($root),
iedreg:runChecks05($root),
iedreg:runChecks06($root),
iedreg:runChecks07($root),
iedreg:runChecks08($root),
iedreg:runChecks09($root),
iedreg:runChecks10($root),
iedreg:runChecks11($root),
iedreg:runChecks12($root)
)
} ;

declare function iedreg:check($url as xs:string) as element ()*
{
iedreg:css(), iedreg:runChecks($url)
};

(:~
 : vim: ts=2 sts=2 sw=2 et
 :)
