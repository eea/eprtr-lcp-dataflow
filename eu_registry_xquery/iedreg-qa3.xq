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

 : Author: Claudia Ifrim
 : Date: December 2017

 :)

module namespace iedreg-qa3 = "http://cdrtest.eionet.europa.eu/help/ied_registry_qa3";

declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace iedreg = "http://cdrtest.eionet.europa.eu/help/ied_registry" at "iedreg.xq";
import module namespace scripts3 = "iedreg-scripts-qa3" at "iedreg-scripts-qa3.xq";

(:~
 : 13. OTHER CHECKS
 :)

declare function iedreg-qa3:runChecks13($root as element()) as element()* {
    let $rulename := '13. GML Validation Checks'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C13.1", "reportData validity", $root, scripts3:checkReportData#3),
        iedreg:failsafeWrapper("C13.2", "hostingSite position validity", $root, scripts3:checkeHostingSite #3),
        iedreg:failsafeWrapper("C13.3", "hostingSite xlink:href validity", $root, scripts3:checkeHostingSiteHref#3),
        iedreg:failsafeWrapper("C13.4", "ProductionInstallation gml:id validity", $root, scripts3:checkGroupedInstallation#3),
        iedreg:failsafeWrapper("C13.5", "groupedInstallation xlink:href validity", $root, scripts3:checkGroupedInstallationHref#3),
        iedreg:failsafeWrapper("C13.6", "act-core:geometry validity", $root, scripts3:checkActCoreGeometry#3),
        iedreg:failsafeWrapper("C13.7", "act-core:activity validity", $root, scripts3:checkActCoreActivity#3),
        iedreg:failsafeWrapper("C13.8", "ProductionInstallationPart gml:id validity", $root, scripts3:checkGroupedInstallationPart#3),
        iedreg:failsafeWrapper("C13.9", "pf:groupedInstallationPart xlink:href validity", $root, scripts3:checkGroupedInstallationPartHref#3),
        iedreg:failsafeWrapper("C13.10", "pf:status validity", $root, scripts3:checkStatusNil#3),
        iedreg:failsafeWrapper("C13.11", "pf:pointGeometry validity", $root, scripts3:checkePointGeometry#3),
        iedreg:failsafeWrapper("C13.12", "otherRelevantChapters consistency", $root, scripts3:checkOtherRelevantChapters#3),
        iedreg:failsafeWrapper("C13.13", "statusType consistency", $root, scripts3:checkStatusType#3),
        iedreg:failsafeWrapper("C13.14", "plantType consistency", $root, scripts3:checkPlantType#3),
        iedreg:failsafeWrapper("C13.15", "derogations consistency", $root, scripts3:checkDerogations#3),
        iedreg:failsafeWrapper("C13.16", "specificConditions consistency", $root, scripts3:checkSpecificConditions#3)
    }</div>
};

declare function iedreg-qa3:runChecks($url as xs:string) as element()*
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
iedreg-qa3:runChecks13($root)
)
} ;

declare function iedreg-qa3:check($url as xs:string) as element ()*
{
iedreg:css(), iedreg-qa3:runChecks($url)
};
