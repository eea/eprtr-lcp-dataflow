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

module namespace scripts = "iedreg-scripts";

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

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace database = "iedreg-database" at "iedreg-database.xq";
(:import module namespace geo = "http://expath.org/ns/geo";:)

(:~
 : --------------
 : Util functions
 : --------------
 :)

declare function scripts:normalize($url as xs:string) as xs:string {
(: replace($url, 'http://dd\.eionet\.europa\.eu/vocabulary[a-z]*/euregistryonindustrialsites/', '') :)
    replace($url, 'http://dd\.eionet\.europa\.eu/vocabulary[a-z]*/euregistryonindustrialsites/[a-zA-Z0-9]+/', '')
};

declare function scripts:is-empty($item as item()*) as xs:boolean {
    normalize-space(string-join($item)) = ''
};

declare function scripts:makePlural($name as xs:string) as xs:string {
    let $name := replace($name, 'Site$', 'Sites')
    let $name := replace($name, 'Facility$', 'Facilities')
    let $name := replace($name, 'Installation$', 'Installations')
    let $name := replace($name, 'InstallationPart$', 'InstallationParts')
    return $name
};

declare function scripts:getPath($e as element()) as xs:string {
    $e/string-join(ancestor-or-self::*[not(fn:matches(local-name(), '^(FeatureCollection)|(featureMember)$'))]/local-name(.), '/')
};

declare function scripts:getParent($e as element()) as element() {
    $e/ancestor-or-self::*[fn:matches(local-name(), '^Production[a-zA-Z]')]
};

declare function scripts:getInspireId($e as element()) as element()* {
    let $parent := scripts:getParent($e)
    return $parent/child::*:inspireId/descendant::*:localId
};

declare function scripts:getGmlId($e as element()) as xs:string {
    let $id := $e/attribute::gml:id
    return if (scripts:is-empty($id)) then "–" else data($id)
};

declare function scripts:getValidConcepts($value as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"

    let $vocabulary := "http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/"
    let $vocabularyconcept := "http://dd.eionet.europa.eu/vocabularyconcept/euregistryonindustrialsites/"

    let $url := $vocabulary || $value || "/rdf"

    return
        data(doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/@rdf:about)
};

declare function scripts:getDetails(
        $msg as xs:string,
        $type as xs:string,
        $hdrs as (xs:string)*,
        $data as (map(*))*
) as element(div)* {
    let $msgClass := concat('inner msg',
            if ($type = 'error') then ' red merror'
            else if ($type = 'warning') then ' yellow mwarning'
            else if ($type = 'info') then ' blue minfo'
                else ()
    )

    return
        <div class="iedreg">

            <div class="iedreg {$msgClass}">{$msg}</div>

            <div class="iedreg table inner">
                <div class="iedreg row">
                    {for $h in $hdrs
                    return
                        <div class="iedreg col inner th"><span class="iedreg nowrap">{$h}</span></div>
                    }
                </div>
                {for $d in $data
                return
                    <div class="iedreg row">
                        {for $z at $i in $d('data')
                        let $x := if (fn:index-of($d('marks'), $i)) then <span class="iedreg nowrap">{$z}</span> else $z
                        return
                            <div class="iedreg col inner{if (fn:index-of($d('marks'), $i)) then ' ' || $type else ''}">{$x}</div>
                        }
                    </div>
                }
            </div>

        </div>
};

(:~
 : --------------
 : html functions
 : --------------
 :)

declare function scripts:renderResult(
        $refcode as xs:string,
        $rulename as xs:string,
        $errors as xs:integer,
        $warnings as xs:integer,
        $messages as xs:integer,
        $details as element()*
) {
    let $id := random:integer(65536)

    let $label :=
        <label class="iedreg" for="toggle-{$id}">
            <span class="iedreg link">More...</span>
        </label>

    let $toggle :=
        <input class="iedreg toggle" id="toggle-{$id}" type="checkbox" />

    let $showRecords := ($errors + $warnings + $messages > 0)

    let $type :=
        if ($errors > 0) then
            'error'
        else if ($warnings > 0) then
            'warning'
        else if ($messages > 0) then
                'info'
            else
                'pass'

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
                            <span class="iedreg nowrap">{$errors} errors</span>
                            <span class="iedreg nowrap">{$warnings} warnings</span>
                            {if ($messages > 0) then
                                <span class="iedreg nowrap">{$messages} messages</span>
                            else ()}
                        </div>

                        <div class="iedreg col ten center middle">
                            {if ($showRecords) then
                                $label
                            else ' '}
                        </div>
                    </div>
                </div>

                <!-- details table -->
                {if ($showRecords) then
                    ($toggle, $details)
                else
                    ()
                }
            </div>
        </div>
};

(:~
 : 1. CODE LIST CHECKS
 :)

declare function scripts:checkActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $activityName as xs:string,
        $activityType as xs:string,
        $seq as element()*
) as element()* {
    let $msg := "The " || $activityName || " specified in the " || $activityType || " field for the following " ||
                scripts:makePlural($featureName) || " is not recognised. Please use an activity listed in the " ||
                $activityName || "Value code list"
    let $type := "error"

    let $value := $activityName || "Value"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root/descendant::*[local-name() = $activityName]/descendant::*[local-name() = $activityType]

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $activity := replace($x/attribute::*:href, '/+$', '')

        let $p := scripts:getPath($x)
        let $v := scripts:normalize($activity)

        where not(scripts:is-empty($activity)) and not($activity = $valid)
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $hdrs := ("Feature", "GML ID", "Path", $activityName || "Value")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C1.1 EPRTRAnnexIActivity mainActivity consistency
 :)

declare function scripts:checkMainEPRTRAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"
    let $activityType := "mainActivity"
    let $seq := $root/descendant::*[local-name() = $activityName]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C1.2 EPRTRAnnexIActivity otherActivity consistency
 :)

declare function scripts:checkOtherEPRTRAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"
    let $activityType := "otherActivity"
    let $seq := $root/descendant::*[local-name() = $activityName]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C1.3 IEDAnnexIActivity mainActivity consistency
 :)

declare function scripts:checkMainIEDAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"
    let $activityType := "mainActivity"
    let $seq := $root/descendant::*[local-name() = $activityName]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C1.4 IEDAnnexIActivity otherActivity consistency
 :)

declare function scripts:checkOtherIEDAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"
    let $activityType := "otherActivity"
    let $seq := $root/descendant::*[local-name() = $activityName]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C1.5 CountryId consistency
 :)

declare function scripts:checkCountryId(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The CountryCodeValue specified in the countryId field is not recognised. Please use a CountryId listed in the CountryCodeValue code list"
    let $type := "error"

    let $value := "CountryCodeValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root/descendant::EUReg:ReportData

    let $data :=
        for $rd in $seq
        let $feature := $rd/local-name()
        let $id := scripts:getGmlId($rd)

        let $countries := $rd/descendant::*:countryId

        for $x in $countries
        let $country := replace($x/attribute::xlink:href, '/+$', '')

        let $p := scripts:getPath($x)
        let $v := scripts:normalize(data($country))

        where not(scripts:is-empty($country)) and not($country = $valid)
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "CountryId")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C1.6 reasonValue consistency
 :)

declare function scripts:checkReasonValue(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The ReasonValue supplied in the confidentialityReason field for the following spatial objects is not recognised. Please use a reason listed in the ReasonValue code list"
    let $type := "error"

    let $value := "ReasonValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root/descendant::*:confidentialityReason

    let $data :=
        for $r in $seq
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $reason := replace($r/attribute::xlink:href, '/+$', '')

        let $p := scripts:getPath($r)
        let $v := scripts:normalize(data($reason))

        where (not(empty($reason)) and not($reason = $valid))
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "ReasonValue")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : 2. INSPIRE ID CHECKS
 :)

declare function scripts:checkInspireIdUniqueness(
        $root as element(),
        $refcode as xs:string,
        $feature as xs:string
) as element()* {
    let $rulename := $feature || " inspireId uniqueness"

    let $msg := "All inspireIds for " || scripts:makePlural($feature) || " should be unique. Please ensure all inspireIds are different"
    let $type := "error"

    let $seq := $root/descendant::*[local-name() = $feature]

    let $dups := functx:non-distinct-values($seq/scripts:getInspireId(.))

    let $data :=
        for $d in $dups
        for $x in $seq
        let $id := scripts:getGmlId($x)
        where scripts:getInspireId($x)/text() = $d
        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $d)
        }

    let $hdrs := ("Feature", "GML ID", "Inspire ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C2.1 High proportion of new inspireIds
 :)

declare function scripts:checkAmountOfInspireIds(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warn := "The amount of new inspireIds within this submission equals PERC, which exceeds 50%, please verify to ensure these are new entities reported for the first time."
    let $info := "The amount of new inspireIds within this submission equals PERC, which exceeds the ideal threshold of 20%, please verify to ensure these are new entities reported for the first time."

    let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

    let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

    let $seq := $root/descendant::pf:inspireId

    let $fromDB := database:query($cntry, $lastReportingYear, (
        "pf:inspireId"
    ))

    let $xIDs := $seq/descendant::base:localId
    let $yIDs := $fromDB/descendant::base:localId

    let $data :=
        for $id in $xIDs
        let $p := scripts:getParent($id)

        where not($id = $yIDs)
        return map {
        "marks": (2),
        "data": ($p/local-name(), <span class="iedreg nowrap">{$id/text()}</span>)
        }

    let $ratio := count($data) div count($xIDs)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Feature", "Inspire ID")

    return
        if ($ratio gt 0.5) then
            let $msg := replace($warn, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
        else if ($ratio gt 0.2) then
            let $msg := replace($info, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "info", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : C2.2 ProductionSite inspireId uniqueness
 :)

declare function scripts:checkProductionSiteUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionSite"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C2.3 ProductionFacility inspireId uniqueness
 :)

declare function scripts:checkProductionFacilityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionFacility"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C2.4 ProductionInstallation inspireId uniqueness
 :)

declare function scripts:checkProductionInstallationUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionInstallation"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C2.5 ProductionInstallationPart inspireId uniqueness
 :)

declare function scripts:checkProductionInstallationPartUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionInstallationPart"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : 3. DUPLICATE IDENTIFICATION CHECKS
 :)

declare function scripts:checkDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string
) as element()* {
    let $nameName := $feature || 'Name'
    let $featureName := 'Production' || functx:capitalize-first($feature)

    let $msg := "The similarity threshold has been exceeded, for the following " || scripts:makePlural($featureName) || ". Please ammend the XML submission to ensure that there is no duplication"
    let $type := "warning"

    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $nameName]/descendant::*:nameOfFeature

    let $norm := ft:normalize(?, map {'stemming' : true()})

    let $data :=
        for $x at $i in $seq
        let $p := scripts:getParent($x)
        let $id := scripts:getGmlId($p)

        for $y in subsequence($seq, $i + 1)
        let $q := scripts:getParent($y)
        let $ic := scripts:getGmlId($q)

        let $z := strings:levenshtein($norm($x/data()), $norm($y/data()))
        where $z >= 0.5
        return map {
        "marks" : (4, 5, 6),
        "data" : (
            $featureName,
            <span class="iedreg nowrap">{$id}</span>,
            <span class="iedreg nowrap">{$ic}</span>,
            '"' || $x/data() || '"', '"' || $y/data() || '"',
            round-half-to-even($z * 100, 1) || '%'
        )
        }

    let $hdrs := ('Feature', 'GML IDs', ' ', 'Feature names', ' ', 'Similarity')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C3.1 Identification of ProductionSite duplicates
 :)

declare function scripts:checkProductionSiteDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'site'

    return scripts:checkDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.2 Identification of ProductionFacility duplicates
 :)

declare function scripts:checkProductionFacilityDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'facility'

    return scripts:checkDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.3 Identification of ProductionInstallation duplicates
 :)

declare function scripts:checkProductionInstallationDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installation'

    return scripts:checkDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.4 Identification of ProductionInstallationPart duplicates
 :)

declare function scripts:checkProductionInstallationPartDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installationPart'

    return scripts:checkDuplicates($refcode, $rulename, $root, $feature)
};

declare function scripts:checkDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string
) as element()* {
    let $nameName := $feature || 'Name'
    let $featureName := 'Production' || functx:capitalize-first($feature)

    let $msg := "The similarity threshold has been exceeded, for the following " || scripts:makePlural($featureName) || ". These " || scripts:makePlural($featureName) || " have similar " || scripts:makePlural($featureName) || " already present in the master database. Please ensure that there is no duplication."
    let $type := "warning"

    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $nameName]/descendant::*:nameOfFeature

    (: this is where we get the data from the database :)
    let $fromDB := database:getFeatureNames($featureName, $nameName)

    let $norm := ft:normalize(?, map {'stemming' : true()})

    let $data :=
        for $x in $seq
        let $p := scripts:getParent($x)
        let $id := scripts:getInspireId($p)

        for $y in $fromDB
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id != $ic

        let $z := strings:levenshtein($norm($x/data()), $norm($y/data()))
        where $z >= 0.5
        return map {
        "marks" : (4, 5, 6),
        "data" : (
            $featureName,
            <span class="iedreg nowrap">{$id}</span>,
            <span class="iedreg nowrap">{$ic}</span>,
            '"' || $x/data() || '"', '"' || $y/data() || '"',
            round-half-to-even($z * 100, 1) || '%'
        )
        }

    let $hdrs := ('Feature', 'Inspire ID', 'Inspire ID (DB)', 'Feature name', 'Feature name (DB)', 'Similarity')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C3.5 Identification of ProductionSite duplicates within the database
 :)

declare function scripts:checkProductionSiteDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'site'

    return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.6 Identification of ProductionFacility duplicates within the database
 :)

declare function scripts:checkProductionFacilityDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'facility'

    return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.7 Identification of ProductionInstallation duplicates within the database
 :)

declare function scripts:checkProductionInstallationDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installation'

    return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature)
};

(:~
 : C3.8 Identification of ProductionInstallationPart duplicates within the database
 :)

declare function scripts:checkProductionInstallationPartDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installationPart'

    return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature)
};

declare function scripts:checkMissing(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string,
        $allowed as xs:string*
) as element()* {
    let $featureName := 'Production' || functx:capitalize-first($feature)

    let $msg := "There are inspireIDs for " || scripts:makePlural($featureName) || " missing from this submission. Please verify to ensure that no " || scripts:makePlural($featureName) || " have been missed."
    let $type := "error"

    let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

    let $lastYear := max(database:getReportingYearsByCountry($cntry))

    let $seq := $root/descendant::pf:inspireId
    let $fromDB := database:query($cntry, $lastYear, "pf:inspireId")

    let $data :=
        for $id in $fromDB
        where not($id/descendant::*:localId = $seq/descendant::*:localId)

        let $p := scripts:getParent($id)
        where $p/local-name() = $featureName

        let $id := $id/descendant::*:localId/text()

        let $status := $p/pf:status/descendant::pf:statusType
        let $status := replace($status/@xlink:href, '/+$', '')
        let $status := scripts:normalize($status)

        where not($status = $allowed)
        return map {
        "marks" : (),
        "data" : (
            $featureName,
            <span class="iedreg nowrap">{$id}</span>,
            $status
        )
        }

    let $hdrs := ('Feature', 'Inspire ID', 'Status')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C3.9 Missing ProductionSites, previous submissions
 :)

declare function scripts:checkMissingProductionSites(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'site'
    let $allowed := ("decommissioned")

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed)
};

(:~
 : C3.10 Missing ProductionFacilities, previous submissions
 :)

declare function scripts:checkMissingProductionFacilities(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'facility'
    let $allowed := ("decommissioned", "Not regulated")

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed)
};

(:~
 : C3.11 Missing ProductionInstallations, previous submissions
 :)

declare function scripts:checkMissingProductionInstallations(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installation'
    let $allowed := ("decommissioned", "Not regulated")

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed)
};

(:~
 : C3.12 Missing ProductionInstallationsParts, previous submissions
 :)

declare function scripts:checkMissingProductionInstallationParts(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installationPart'
    let $allowed := ("decommissioned")

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed)
};

(:~
 : 4. GEOGRAPHICAL AND COORDINATE CHECKS
 :)

declare function scripts:haversine(
        $lat1 as xs:float,
        $lon1 as xs:float,
        $lat2 as xs:float,
        $lon2 as xs:float
) as xs:float {
    let $dlat := ($lat2 - $lat1) * math:pi() div 180
    let $dlon := ($lon2 - $lon1) * math:pi() div 180
    let $rlat1 := $lat1 * math:pi() div 180
    let $rlat2 := $lat2 * math:pi() div 180
    let $a := math:sin($dlat div 2) * math:sin($dlat div 2) + math:sin($dlon div 2) * math:sin($dlon div 2) * math:cos($rlat1) * math:cos($rlat2)
    let $c := 2 * math:atan2(math:sqrt($a), math:sqrt(1 - $a))
    return xs:float($c * 6371.0)
};

declare function scripts:checkRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $data as (map(*))*,
        $parentFeature as xs:string,
        $childFeature as xs:string,
        $lowerLimit as xs:float,
        $upperLimit as xs:float
) as element()* {
    let $warn := "The coordinates supplied for the following " || scripts:makePlural($childFeature) || " are outside of a " || $upperLimit || "km radius, of the coordinates supplied for their associated " || scripts:makePlural($parentFeature) || ". Please ensure all coordinates have been inputted correctly."
    let $info := "The coordinates supplied for the following " || scripts:makePlural($childFeature) || " are outside the ideal " || $lowerLimit || "km radius of the coordinates supplied for their associated " || scripts:makePlural($parentFeature) || ". Please ensure all coordinates have been inputted correctly."

    let $yellow :=
        for $m in $data
        let $dist := $m("data")[5]
        where $dist gt $upperLimit
        return $m

    let $blue :=
        for $m in $data
        let $dist := $m("data")[5]
        where $dist le $upperLimit and $dist gt $lowerLimit
        return $m

    let $hdrs := ("Feature", "GML ID", "Feature", "GML ID", "Distance (km)")

    let $details :=
        <div class="iedreg">{
            if (count($yellow) gt 0) then scripts:getDetails($warn, "warning", $hdrs, $yellow) else (),
            if (count($blue) gt 0) then scripts:getDetails($info, "info", $hdrs, $blue) else ()
        }</div>

    return
        scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};

(:~
 : C4.1 ProductionSite radius
 :)

declare function scripts:checkProdutionSiteRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionSite"
    let $childFeature := "ProductionFacility"
    let $lowerLimit := 5.0
    let $upperLimit := 10.0

    let $data :=
        for $x in $root/descendant::EUReg:ProductionSite
        let $x_id := scripts:getGmlId($x)
        let $x_location := $x/EUReg:location

        for $x_coords in $x_location/descendant::gml:*/descendant-or-self::*[not(*)]
        let $x_long := substring-before($x_coords, ' ')
        let $x_lat := substring-after($x_coords, ' ')

        for $y in $root/descendant::EUReg:ProductionFacility[pf:hostingSite[@xlink:href = '#' || $x_id]]
        let $y_id := scripts:getGmlId($y)
        let $y_geometry := $y/act-core:geometry

        for $y_coords in $y_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        let $y_long := substring-before($y_coords, ' ')
        let $y_lat := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (5),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $dist)
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C4.2 ProductionFacility radius
 :)

declare function scripts:checkProdutionFacilityRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionFacility"
    let $childFeature := "ProductionInstallation"
    let $lowerLimit := 1.0
    let $upperLimit := 5.0

    let $data :=
        for $x in $root/descendant::EUReg:ProductionFacility
        let $x_id := scripts:getGmlId($x)
        let $x_geometry := $x/act-core:geometry

        for $x_coords in $x_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        let $x_long := substring-before($x_coords, ' ')
        let $x_lat := substring-after($x_coords, ' ')

        for $y_id in $x/pf:groupedInstallation/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root/descendant::EUReg:ProductionInstallation[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry

        for $y_coords in $y_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        let $y_long := substring-before($y_coords, ' ')
        let $y_lat := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (5),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $dist)
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C4.3 ProductionInstallation radius
 :)

declare function scripts:checkProdutionInstallationRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionInstallation"
    let $childFeature := "ProductionInstallationPart"
    let $lowerLimit := 0.5
    let $upperLimit := 3.0

    let $data :=
        for $x in $root/descendant::EUReg:ProductionInstallation
        let $x_id := scripts:getGmlId($x)
        let $x_geometry := $x/pf:pointGeometry

        for $x_coords in $x_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        let $x_long := substring-before($x_coords, ' ')
        let $x_lat := substring-after($x_coords, ' ')

        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root/descendant::EUReg:ProductionInstallationPart[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry

        for $y_coords in $y_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        let $y_long := substring-before($y_coords, ' ')
        let $y_lat := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (5),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $dist)
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C4.4 Coordinates to country comparison
 :)
(:
declare function scripts:checkCountryBoundary(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "The following respective fields for spatial objects contain coordinates that fall outside of the country's boundary (including territorial waters). Please verify and correct coordinates in these fields."
  let $type := 'warning'

  let $srsName :=
  for $srs in distinct-values($root/descendant::gml:*/attribute::srsName)
    return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId/attribute::xlink:href
  let $cntry := tokenize($country, '/+')[last()]
  let $boundary := "boundary-" || lower-case($cntry) || ".gml"
  let $doc := doc("http://converterstest.eionet.europa.eu/xmlfile/" || $boundary)
  let $geom := $doc//GML:FeatureCollection/GML:featureMember/ogr:boundary/ogr:geometryProperty/child::*

  let $seq := (
    $root/descendant::EUReg:location,
    $root/descendant::act-core:geometry,
    $root/descendant::pf:pointGeometry
  )

  let $data :=
  for $g in $seq
    let $parent := scripts:getParent($g)
    let $feature := $parent/local-name()

    for $coords in $g/descendant::gml:*/descendant-or-self::*[not(*)]
      let $id := scripts:getGmlId($coords/parent::*)

      let $p := scripts:getPath($coords)

      let $long := substring-before($coords, ' ')
      let $lat := substring-after($coords, ' ')

      let $point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$long},{$lat}</GML:coordinates></GML:Point>

      where not(geo:within($point, $geom))
      return map {
        'marks': (3, 4),
        'data': ($feature, <span class="iedreg nowrap">{$id}</span>, replace($coords/text(), ' ', ', '), $cntry)
      }

  let $hdrs := ("Feature", "GML ID", "Coordinates", "Country")

  let $details := scripts:getDetails($msg, $type, $hdrs, $data)

  return
    scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};
:)
(:~
 : C4.5 Coordinate precision completeness
 :)

declare function scripts:checkCoordinatePrecisionCompleteness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The coordinates are not consistent to 4 decimal places for the following fields. Please ensure all coordinates have been inputted correctly."
    let $type := 'warning'

    let $seq := (
        $root/descendant::EUReg:location,
        $root/descendant::act-core:geometry,
        $root/descendant::pf:pointGeometry
    )

    let $data :=
        for $g in $seq
        let $parent := scripts:getParent($g)
        let $feature := $parent/local-name()

        for $coords in $g/descendant::gml:*/descendant-or-self::*[not(*)]
        let $id := scripts:getGmlId($coords/parent::*)

        let $p := scripts:getPath($coords)

        let $long := substring-before($coords, ' ')
        let $lat := substring-after($coords, ' ')
        let $errLong := if (string-length(substring-after($long, '.')) lt 4) then (5) else ()
        let $errLat := if (string-length(substring-after($lat, '.')) lt 4) then (4) else ()
        where (string-length(substring-after($long, '.')) lt 4) or (string-length(substring-after($lat, '.')) lt 4)
        return map {
        'marks' : ($errLong, $errLat),
        'data' : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $long, $lat)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "Longitude", "Latitude")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C4.6 Coordinate continuity
 :)
(:
declare function scripts:checkCoordinateContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $error := "The coordinates, for the following spatial objects, have changed by over 100m when compared to the master database. Changes in excess of 100m are considered as introducing poor quality data to the master database, please verify the coordinates and ensure they have been inputted correctly."
  let $warn :=  "The coordinates, for the following spatial objects, have changed by 30-100m compared to the master database. Please verify the coordinates and ensure that they have been inputted correctly."
  let $info :=  "The coordinates, for the following spatial objects, have changed by 10 -30m compared to the master database. Distance changes between 10-30m may represent coordinate refinement, however please verify the coordinates and ensure that they have been inputted correctly."

  let $srsName :=
  for $srs in distinct-values($root/descendant::gml:*/attribute::srsName)
    return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := (
    $root/descendant::EUReg:location,
    $root/descendant::act-core:geometry,
    $root/descendant::pf:pointGeometry
  )
  let $fromDB := database:query($cntry, $lastReportingYear, (
    "EUReg:location",
    "act-core:geometry",
    "pf:pointGeometry"
  ))

  let $data :=
  for $x in $seq/descendant::gml:*/descendant-or-self::*[not(*)]
    let $p := scripts:getParent($x)
    let $id := scripts:getInspireId($p)/text()

    let $y :=
    for $y in $fromDB/descendant::gml:*/descendant-or-self::*[not(*)]
      let $q := scripts:getParent($y)
      let $ic := scripts:getInspireId($q)/text()

      where $id = $ic

      return $y

    where not(empty($y))

    let $xlong := substring-before($x, ' ')
    let $xlat := substring-after($x, ' ')
    let $xp := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$xlong},{$xlat}</GML:coordinates></GML:Point>

    let $ylong := substring-before($y, ' ')
    let $ylat := substring-after($y, ' ')
    let $yp := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$ylong},{$ylat}</GML:coordinates></GML:Point>

    let $dist := round-half-to-even(geo:distance($xp, $yp) * 111319.9, 2)

    return [$p/local-name(), $id, string-join(($xlat, $xlong), ", "), string-join(($ylat, $ylong), ", "), $dist]

  let $red :=
  for $x in $data
    where $x(5) gt 100
    return map {
      "marks": (5),
      "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, <span class="iedreg nowrap">{$x(3)}</span>, <span class="iedreg nowrap">{$x(4)}</span>, $x(5))
    }

  let $yellow :=
  for $x in $data
    where $x(5) gt 30 and $x(5) le 100
    return map {
      "marks": (5),
      "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, <span class="iedreg nowrap">{$x(3)}</span>, <span class="iedreg nowrap">{$x(4)}</span>, $x(5))
    }

  let $blue :=
  for $x in $data
    where $x(5) gt 10 and $x(5) le 30
    return map {
      "marks": (5),
      "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, <span class="iedreg nowrap">{$x(3)}</span>, <span class="iedreg nowrap">{$x(4)}</span>, $x(5))
    }

  let $hdrs := ("Feature", "Inspire ID", "Coordinates", "Previous coordinates (DB)", "Difference (meters)")

  let $details :=
    <div class="iedreg">{
    if (empty($red)) then () else scripts:getDetails($error, "error", $hdrs, $red),
    if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
    if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
    }</div>

  return
    scripts:renderResult($refcode, $rulename, count($red), count($yellow), count($blue), $details)
};
:)
(:~
 : C4.7 ProductionSite to ProductionFacility coordinate comparison
 :)
(:
declare function scripts:checkProdutionSiteBuffers(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $warnRadius := 5000
  let $infoRadius := 30000

  let $warn := "The following ProductionFacilities have coordinates that are within a " || $warnRadius || "m radius of the coordinates provided for the associated ProductionSite. Please verify the coordinates and ensure that they have been inputted correctly."
  let $info := "The following ProductionFacilities have coordinates that are within a " || $infoRadius || "m radius of the coordinates provided for the associated ProductionSite. Please verify the coordinates and ensure that they have been inputted correctly."

  let $srsName :=
  for $srs in distinct-values($root/descendant::gml:*/attribute::srsName)
    return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

  let $data :=
  for $x in $root/descendant::EUReg:ProductionSite
    let $x_id := scripts:getGmlId($x)
    let $x_location := $x/EUReg:location

    for $x_coords in $x_location/descendant::gml:*/descendant-or-self::*[not(*)]
      let $x_long := substring-before($x_coords, ' ')
      let $x_lat := substring-after($x_coords, ' ')

      let $x_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$x_long},{$x_lat}</GML:coordinates></GML:Point>
      let $x_buffer_warn := geo:buffer($x_point, xs:double($warnRadius div 111319.9))
      let $x_buffer_info := geo:buffer($x_point, xs:double($infoRadius div 111319.9))

      let $facilities :=
      for $y in $root/descendant::EUReg:ProductionFacility[pf:hostingSite[@xlink:href='#' || $x_id]]
        let $y_id := scripts:getGmlId($y)
        let $y_geometry := $y/act-core:geometry

        for $y_coords in $y_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
          let $y_long := substring-before($y_coords, ' ')
          let $y_lat := substring-after($y_coords, ' ')

          let $y_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$y_long},{$y_lat}</GML:coordinates></GML:Point>
          let $y_buffer_warn := geo:buffer($y_point, xs:double($warnRadius div 111319.9))
          let $y_buffer_info := geo:buffer($y_point, xs:double($infoRadius div 111319.9))

          return [$y/local-name(), $y_id, $y_point, $y_buffer_warn, $y_buffer_info]

        return (
          [$x/local-name(), $x_id, $x_point, $x_buffer_warn, $x_buffer_info],
          $facilities
        )

  let $yellow :=
  for $x at $i in $data
    for $y in subsequence($data, $i + 1)
      let $dist := round-half-to-even(geo:distance($x(3), $y(3)) * 111319.9, 2)

      where count($data) gt 2

      where geo:intersects($x(4), $y(4))
      return map {
        "marks": (5),
        "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, $y(1), <span class="iedreg nowrap">{$y(2)}</span>, $dist)
      }

  let $blue :=
  for $x at $i in $data
    for $y in subsequence($data, $i + 1)
      let $dist := round-half-to-even(geo:distance($x(3), $y(3)) * 111319.9, 2)

      where count($data) gt 2

      for $z in $yellow
      where not($z('data')[1] = $x(1) and $z('data')[2]/text() = $x(2) and $z('data')[3] = $y(1) and $z('data')[4]/text() = $y(2) and $z('data')[5] = $dist)

      where geo:intersects($x(5), $y(5))
      return map {
        "marks": (5),
        "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, $y(1), <span class="iedreg nowrap">{$y(2)}</span>, $dist)
      }

  let $hdrs := ("Feature", "GML ID", "Feature", "GML ID", "Distance (meters)")

  let $details :=
    <div class="iedreg">{
    if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
    if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
    }</div>

  return
    scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};
:)
(:~
 : C4.8 ProductionInstallation to ProductionInstallationPart coordinate comparison
 :)

declare function scripts:checkProdutionInstallationPartCoords(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The coordinates provided for the following ProductionInstallationParts are identical to the coordinates for the associated ProductionInstallation. Please verify the coordinates and ensure that they have been inputted correctly."
    let $type := "warning"

    let $data :=
        for $x in $root/descendant::EUReg:ProductionInstallation
        let $x_id := scripts:getGmlId($x)
        let $x_geometry := $x/pf:pointGeometry

        where count($x/pf:groupedInstallationPart) gt 1

        for $x_coords in $x_geometry/descendant::gml:*/descendant-or-self::*[not(*)]
        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root/descendant::EUReg:ProductionInstallationPart[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry

        for $y_coords in $y_geometry/descendant::gml:*/descendant-or-self::*[not(*)]

        where $x_coords/text() = $y_coords/text()
        return map {
        "marks" : (5),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, replace($x_coords/text(), ' ', ', '))
        }

    let $hdrs := ("Feature", "GML ID", "Feature", "GML ID", "Coordinates")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : 5. ACTIVITY CHECKS
 :)

declare function scripts:checkActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $activityName as xs:string
) as element()* {
    let $msg := "Each " || $activityName || " should be unique, the following " || scripts:makePlural($featureName) || " share the same main and other Activity. Please evaluate and ensure the inputs for these fields are unique to one another"
    let $type := "error"

    let $seq := $root/descendant::*[local-name() = $featureName]

    let $data :=
        for $r in $seq
        let $parent := scripts:getParent($r)
        let $inspireId := scripts:getInspireId($parent)
        let $activity := $r/descendant::*[local-name() = $activityName]
        let $acts := $activity/descendant-or-self::*[not(*)]

        let $path := scripts:getPath($activity)
        let $id := scripts:getGmlId($parent)

        let $dups :=
            for $a in functx:non-distinct-values($acts/attribute::*:href)
            return scripts:normalize(data($a))

        for $act in $dups
        return map {
        "marks" : (3),
        "data" : ($featureName, <span class="iedreg nowrap">{$id}</span>, $act)
        }

    let $hdrs := ("Feature", "GML ID", $activityName)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

declare function scripts:checkActivityContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element(),
  $featureName as xs:string,
  $activityName as xs:string
) as element()* {
  let $warn := "There have been changes in the " || $activityName || " field, compared to the master database - this field should remain constant over time and seldom change, particularly between activity groups. Changes have been noticed in the following " || scripts:makePlural($featureName) || ". Please ensure all inputs are correct."
  let $info := "There have been changes in the " || $activityName || " field, compared to the master database - this field should remain constant over time and seldom change. Changes have been noticed in the following "|| scripts:makePlural($featureName) || ". Please ensure all inputs are correct."

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := $root/descendant::*[local-name()=$featureName]

  let $fromDB := database:query($cntry, $lastReportingYear, (
    "EUReg:" || $featureName
  ))

  let $data :=
  for $x in $seq
    let $id := scripts:getInspireId($x)

    for $y in $fromDB
      let $ic := scripts:getInspireId($y)

      where $id = $ic

      let $xActivity := $x/descendant::*[local-name()=$activityName]
      let $yActivity := $y/descendant::*[local-name()=$activityName]

      for $act in $xActivity/descendant-or-self::*[not(*)]
        let $p := scripts:getPath($x)
        let $q := scripts:getPath($act)

        let $xAct := replace($act/@xlink:href, '/+$', '')
        let $yAct := replace($yActivity/descendant-or-self::*[not(*) and local-name() = $act/local-name()]/@xlink:href, '/+$', '')

        let $xAct :=
          if (scripts:is-empty($xAct)) then
            " "
          else $xAct

        where not (scripts:is-empty($yAct))
        where not ($xAct = $yAct)
        return [$x/local-name(), $id/text(), $act/local-name(), scripts:normalize($xAct), scripts:normalize($yAct)]

  let $yellow :=
  for $x in $data
    where not(tokenize($x(4), "[.()]+")[1] = tokenize($x(5), "[.()]+")[1])
    return map {
      "marks": (4, 5),
      "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, $x(3), $x(4), $x(5))
    }

  let $blue :=
  for $x in $data
    where tokenize($x(4), "[.()]+")[1] = tokenize($x(5), "[.()]+")[1]
    return map {
      "marks": (4, 5),
      "data": ($x(1), <span class="iedreg nowrap">{$x(2)}</span>, $x(3), $x(4), $x(5))
    }

  let $hdrs := ("Feature", "Inspire ID", $activityName, "Value", "Value (DB)")

  let $details :=
    <div class="iedreg">{
    if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
    if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
    }</div>

  return
    scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};

(:~
 : C5.1 EPRTRAnnexIActivity uniqueness
 :)

declare function scripts:checkEPRTRAnnexIActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"

    return scripts:checkActivityUniqueness($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : C5.2 EPRTRAnnexIActivity continuity
 :)

declare function scripts:checkEPRTRAnnexIActivityContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $featureName := "ProductionFacility"
  let $activityName := "EPRTRAnnexIActivity"

  return scripts:checkActivityContinuity($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : C5.3 IEDAnnexIActivity uniqueness
 :)

declare function scripts:checkIEDAnnexIActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"

    return scripts:checkActivityUniqueness($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : C5.4 IEDAnnexIActivity continuity
 :)

declare function scripts:checkIEDAnnexIActivityContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $featureName := "ProductionInstallation"
  let $activityName := "IEDAnnexIActivity"

  return scripts:checkActivityContinuity($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : 6. STATUS CHECKS
 :)

declare function scripts:checkStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $type as xs:string,
        $parentName as xs:string,
        $childName as xs:string,
        $groupName as xs:string,
        $parentStatus as xs:string,
        $childStatus as xs:string*
) as element()* {
    let $warn := "The '" || $parentStatus || "' statuses, of the following " || scripts:makePlural($parentName) || ", are not consistent with the associated " || scripts:makePlural($childName) || ". Please verify inputs and ensure consistency when classifying a " || $parentName || " and its " || scripts:makePlural($childName) || " as '" || $parentStatus || "'."
    let $error := "The '" || $parentStatus || "' StatusTypes, of the following " || scripts:makePlural($parentName) || ", are not consistent with the associated " || scripts:makePlural($childName) || ". Please verify inputs and ensure consistency, classifying a " || $parentName || "'s " || scripts:makePlural($childName) || " as '" || string-join($childStatus, "' or '") || "' also."

    let $value := "ConditionOfFacilityValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $root/descendant::*[local-name() = $parentName]
        let $x_id := scripts:getGmlId($x)

        let $x_status := $x/pf:status/descendant::pf:statusType
        let $p := scripts:getPath($x_status)

        let $x_status := replace($x_status/@xlink:href, '/+$', '')
        where $x_status = $valid

        let $x_status := scripts:normalize($x_status)
        where $x_status = $parentStatus

        let $children :=
            for $y_id in $x/child::*[local-name() = $groupName]/@xlink:href
            let $y_id := replace(data($y_id), "^#", "")

            for $y in $root/descendant::*[local-name() = $childName][@gml:id = $y_id]
            let $y_status := replace($y/pf:status/descendant::pf:statusType/@xlink:href, '/+$', '')
            where $y_status = $valid

            let $y_status := scripts:normalize($y_status)
            where not($y_status = $childStatus)
            return $y_status

        return
            if (not(empty($children))) then
                map {
                "marks" : (4),
                "data" : ($parentName, <span class="iedreg nowrap">{$x_id}</span>, $p, $x_status)
                }
            else ()

    let $hdrs := ("Feature", "GML ID", "Path", "Status")

    return
        if ($type = "warning") then
            let $details := scripts:getDetails($warn, $type, $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
        else if ($type = "error") then
            let $details := scripts:getDetails($error, $type, $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : C6.1 Decommissioned StatusType comparison ProductionFacility and ProductionInstallation
 :)

declare function scripts:checkProductionFacilityDecommissionedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionFacility"
    let $childName := "ProductionInstallation"
    let $groupName := "groupedInstallation"
    let $parentStatus := "decommissioned"
    let $childStatus := "decommissioned"

    return scripts:checkStatus($refcode, $rulename, $root, "warning", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C6.2 Decommissioned StatusType comparison ProductionInstallations and ProductionInstallationParts
 :)

declare function scripts:checkProductionInstallationDecommissionedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionInstallation"
    let $childName := "ProductionInstallationPart"
    let $groupName := "groupedInstallationPart"
    let $parentStatus := "decommissioned"
    let $childStatus := "decommissioned"

    return scripts:checkStatus($refcode, $rulename, $root, "warning", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C6.3 Disused StatusType comparison ProductionFacility and ProductionInstallation
 :)

declare function scripts:checkProductionFacilityDisusedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionFacility"
    let $childName := "ProductionInstallation"
    let $groupName := "groupedInstallation"
    let $parentStatus := "disused"
    let $childStatus := ("disused", "decommissioned")

    return scripts:checkStatus($refcode, $rulename, $root, "error", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C6.4 Disused StatusType comparison ProductionInstallations and ProductionInstallationParts
 :)

declare function scripts:checkProductionInstallationDisusedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionInstallation"
    let $childName := "ProductionInstallationPart"
    let $groupName := "groupedInstallationPart"
    let $parentStatus := "disused"
    let $childStatus := ("disused", "decommissioned")

    return scripts:checkStatus($refcode, $rulename, $root, "error", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C6.5 Decommissioned to functional plausibility
 :)

declare function scripts:checkFunctionalStatusType(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "The StatusType, of the following spatial objects, has changed from 'decomissioned' in the previous submission to 'functional' in this current submission. Please verify inputs and ensure consistency with the previous report."
  let $type := "error"

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := $root/descendant::pf:statusType

  let $fromDB := database:query($cntry, $lastReportingYear, (
    "pf:statusType"
  ))

  let $value := "ConditionOfFacilityValue"
  let $valid := scripts:getValidConcepts($value)

  let $data :=
  for $x in $seq
    let $p := scripts:getParent($x)
    let $id := scripts:getInspireId($p)

    let $xStatus := replace($x/@xlink:href, '/+$', '')

    where not(scripts:is-empty($xStatus)) and $xStatus = $valid
    let $xStat := scripts:normalize($xStatus)

    for $y in $fromDB
      let $q := scripts:getParent($y)
      let $ic := scripts:getInspireId($q)

      where $id = $ic

      let $yStatus := replace($y/@xlink:href, '/+$', '')

      where not(scripts:is-empty($yStatus)) and $yStatus = $valid
      let $yStat := scripts:normalize($yStatus)

      where $xStat = "functional"
      where $yStat = "decommissioned"

      return map {
        "marks": (4, 5),
        "data": ($p/local-name(), <span class="iedreg nowrap">{$id/text()}</span>, scripts:getPath($x), $yStat, $xStat)
      }

  let $hdrs := ("Feature", "Inspire ID", "Path", "StatusType (DB)", "StatusType")

  let $details := scripts:getDetails($msg, $type, $hdrs, $data)

  return
    scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : 7. DATE CHECKS
 :)

declare function scripts:queryDate(
        $root as element(),
        $parentName as xs:string,
        $childName as xs:string,
        $groupName as xs:string,
        $dateName as xs:string
) as (map(*))* {
    for $x in $root/descendant::*[local-name() = $parentName]
    let $x_id := scripts:getGmlId($x)
    let $x_date := $x/child::*[local-name() = $dateName]

    where not(scripts:is-empty($x_date))
    let $x_date := xs:date($x_date/text())

    for $y_id in $x/child::*[local-name() = $groupName]/@xlink:href
    let $y_id := replace(data($y_id), "^#", "")

    for $y in $root/descendant::*[local-name() = $childName][@gml:id = $y_id]
    let $y_date := $y/child::*[local-name() = $dateName]

    where not(scripts:is-empty($y_date))
    let $y_date := xs:date($y_date/text())

    where $x_date gt $y_date

    return map {
    "marks" : (3, 4),
    "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $x_date, $y_date)
    }
};

(:~
 : C7.1 dateOfStartOperation comparison
 :)

declare function scripts:checkDateOfStartOfOperation(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $dateName := "dateOfStartOfOperation"

    let $msg := "The " || $dateName || " field within the ProductionFacility, ProductionInstallation and ProductionInstallationPart have been queried against each other to check chronology. In the following cases, the ProductionFacility operational start date occurs after that of the associated productionInstallations and/or the ProductionInstallation operational start date occurs after that of the associated ProductionInstallationParts. Please verify all inputs are accurate before submitting."
    let $type := "warning"

    let $data := (
        scripts:queryDate($root, "ProductionFacility", "ProductionInstallation", "groupedInstallation", $dateName),
        scripts:queryDate($root, "ProductionInstallation", "ProductionInstallationPart", "groupedInstallationPart", $dateName)
    )

    let $hdrs := ("Feature", "GML ID", "Feature date", "Feature child date")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C7.2 dateOfStartOperation LCP restriction
 :)

declare function scripts:checkDateOfStartOfOperationLCP(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $dateName := "dateOfStartOfOperation"

    let $msg := "The " || $dateName || " field for the following LCPs are blank. This is a mandatory requirement when reporting an LCP."
    let $type := "error"

    let $value := "PlantTypeValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root/descendant::*:ProductionInstallationPart/child::*:plantType

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $plant := $x/attribute::*:href
        let $date := $parent/child::*[local-name() = $dateName]

        let $p := scripts:getPath($x)
        let $v := scripts:normalize($plant)

        where (scripts:is-empty($date) and ($v = "LCP"))
        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $v)
        }

    let $hdrs := ("Feature", "GML ID", "Plant type")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C7.3 dateOfStartOperation to dateOfGranting comparison
 :)

declare function scripts:checkDateOfGranting(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The dateOfGranting does not precede dateOfStartOfOperation for the following ProductionInstallations. It is anticipated that a valid permit will be granted prior to operation, especially when a new ProductionInstallation is reported. Please verify dates and ensure they are correct."
    let $type := "warning"

    let $seq := $root/descendant::*:ProductionInstallation/EUReg:permit/EUReg:PermitDetails

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $dateOfGranting := $x/EUReg:dateOfGranting
        let $dateOfStart := $parent/EUReg:dateOfStartOfOperation

        where not(scripts:is-empty($dateOfGranting)) and not(scripts:is-empty($dateOfStart))
        let $dateOfGranting := xs:date($dateOfGranting/text())
        let $dateOfStart := xs:date($dateOfStart/text())

        where $dateOfGranting gt $dateOfStart
        return map {
        "marks" : (3, 4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $dateOfGranting, $dateOfStart)
        }

    let $hdrs := ("Feature", "GML ID", "dateOfGranting", "dateOfStartOfOperation")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkPermitDates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $date1 as xs:string,
        $date2 as xs:string
) as element()* {
    let $msg := "The " || $date1 || " does not precede " || $date2 || " for the following ProductionInstallations. Please verify dates and ensure they are correct."
    let $type := "warning"

    let $seq := $root/descendant::*:ProductionInstallation/EUReg:permit/EUReg:PermitDetails

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $d1 := $x/child::*[local-name() = $date1]
        let $d2 := $x/child::*[local-name() = $date2]

        where (not(scripts:is-empty($d1)) and not(scripts:is-empty($d2)))
        let $d1 := xs:date($d1/text())
        let $d2 := xs:date($d2/text())

        where $d1 gt $d2
        return map {
        "marks" : (3, 4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $d1, $d2)
        }

    let $hdrs := ("Feature", "GML ID", $date1, $date2)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C7.4 dateOfGranting plausibility
 :)

declare function scripts:checkDateOfLastReconsideration(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    scripts:checkPermitDates($refcode, $rulename, $root, "dateOfGranting", "dateOfLastReconsideration")
};

(:~
 : C7.5 dateOfLastReconsideration plausibility
 :)

declare function scripts:checkDateOfLastUpdate(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    scripts:checkPermitDates($refcode, $rulename, $root, "dateOfLastReconsideration", "dateOfLastUpdate")
};

(:~
 : 8. PERMITS & COMPETENT AUTHORITY CHECKS
 :)

(:~
 : C8.1 competentAuthorityInspections to inspections comparison
 :)

declare function scripts:checkInspections(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The competentAuthorityInspections field has not been filled out for the following ProductionInstallations where the inspection field is greater than or equal to 1. Please verify to ensure the competent authority for these insepctions has been specified in the appropriate fields."
    let $type := "warning"

    let $seq := $root/descendant::*:ProductionInstallation

    let $data :=
        for $x in $seq
        let $feature := $x/local-name()
        let $id := scripts:getGmlId($x)

        let $inspections := $x/EUReg:inspections
        let $authInspections := $x/EUReg:competentAuthorityInspections

        where not(scripts:is-empty($inspections))
        let $v := xs:float($inspections/text())

        where ($v gt 0) and scripts:is-empty($authInspections)
        return map {
        "marks" : (),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>)
        }

    let $hdrs := ("Feature", "GML ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C8.2 competentAuthorityPermits and permit field comparison
 :)

declare function scripts:checkPermit(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The competentAuthorityPermits field has not been filled out for the following ProductionInstallations where a permit action has been detailed. Please verify and ensure that the competent authority for these permits actions is specified."
    let $type := "info"

    let $seq := $root/descendant::*:ProductionInstallation

    let $data :=
        for $x in $seq
        let $feature := $x/local-name()
        let $id := scripts:getGmlId($x)

        let $permit := $x/EUReg:permit
        let $authPermits := $x/EUReg:competentAuthorityPermits

        where not(scripts:is-empty($permit)) and scripts:is-empty($authPermits)
        return map {
        "marks" : (),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>)
        }

    let $hdrs := ("Feature", "GML ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C8.3 PermitURL to dateOfGranting comparison
 :)

declare function scripts:checkDateOfGrantingPermitURL(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "The dateofGranting, for the following ProductionInstallations, has changed from the previous submission, but the PermitURL has remained the same. Please verify and ensure all required changes in the PermitURL field have been made."
  let $type := "info"

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := $root/descendant::EUReg:ProductionInstallation

  let $fromDB := database:query($cntry, $lastReportingYear, (
    "EUReg:ProductionInstallation"
  ))

  let $data :=
  for $x in $seq
    let $id := scripts:getInspireId($x)

    let $xDate := $x/EUReg:permit/descendant::EUReg:dateOfGranting
    let $xUrl := $x/EUReg:permit/descendant::EUReg:permitURL

    for $y in $fromDB
      let $ic := scripts:getInspireId($y)

      where $id = $ic

      let $yDate := $y/EUReg:permit/descendant::EUReg:dateOfGranting
      let $yUrl := $y/EUReg:permit/descendant::EUReg:permitURL

      where not($xDate = $yDate)
      where ($xUrl = $yUrl) or (empty($xUrl) and empty($yUrl))

      let $url := if (scripts:is-empty($xUrl)) then " " else $xUrl/text()
      let $oldDate := if (scripts:is-empty($yDate/text())) then " " else xs:date($yDate/text())
      let $newDate := if (scripts:is-empty($xDate/text())) then " " else xs:date($xDate/text())

      return map {
        "marks": (4, 5),
        "data": ($x/local-name(), <span class="iedreg nowrap">{$id/text()}</span>, $oldDate, $newDate, $url)
      }

  let $hdrs := ("Feature", "Inspire ID", "dateofGranting (DB)", "dateofGranting", "permitURL")

  let $details := scripts:getDetails($msg, $type, $hdrs, $data)

  return
    scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : 9. DEROGATION CHECKS
 :)

(:~
 : C9.1 BATDerogationIndicitor to dateOfGranting comparison
 :)

declare function scripts:checkBATPermit(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "When the BATDerogationIndicator Boolean is 'true', the Boolean for permitGranted should also be 'true'. The Boolean fields within the following ProductionInstallations are not consistent with this rule. Please verify and ensure all information is correct."
    let $type := "info"

    let $seq := $root/descendant::*:ProductionInstallation

    let $data :=
        for $x in $seq
        let $id := scripts:getGmlId($x)

        let $bat := $x/EUReg:BATDerogationIndicator
        let $permit := $x/EUReg:permit/descendant::EUReg:permitGranted

        let $bat := $bat = true()
        let $permit := not(scripts:is-empty($permit)) and $permit = true()

        where $bat and not($permit)

        return map {
        "marks" : (3, 4),
        "data" : ($x/local-name(), $id, $bat, $permit)
        }

    let $hdrs := ("Feature", "GML ID", "BATDerogationIndicator", "permitGranted")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};
(:~
 : C9.2 dateOfGranting to Transitional National Plan comparison
 :)

declare function scripts:checkArticle32(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The DerogationValue indicates the ProductionInstallation is subject to 'Article 32' of the IED, however the dateOfGranting contains a date that occurs after the 27th November 2002 for the following ProductionInstallationParts. This date is not applicable for the derogation reported. Please verify and ensure dates have been inputted correctly."
    let $type := "warning"

    let $value := "DerogationValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $root/descendant::EUReg:ProductionInstallation
        let $x_id := scripts:getGmlId($x)
        let $dateOfGranting := $x/EUReg:permit/descendant::EUReg:dateOfGranting

        where not(scripts:is-empty($dateOfGranting))
        let $dateOfGranting := xs:date($dateOfGranting/text())

        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root/descendant::EUReg:ProductionInstallationPart[@gml:id = $y_id]
        let $derogations := replace($y/EUReg:derogations/@xlink:href, '/+$', '')

        where not(scripts:is-empty($derogations)) and $derogations = $valid
        let $derogations := scripts:normalize($derogations)

        where ($derogations = "Article32") and ($dateOfGranting gt xs:date("2002-11-27"))
        return map {
        "marks" : (4),
        "data" : ($y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $derogations, $dateOfGranting)
        }

    let $hdrs := ("Feature", "GML ID", "DerogationValue", "dateOfGranting")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkDerogationsYear(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $article as xs:string,
        $year as xs:integer
) as element()* {
    let $value := "DerogationValue"

    let $msg := "The " || $value || " indicates '" || $article || "' has been reported, however the reporting year is greater than " || $year || ". The derogation in the following fields is no longer valid in respect to the reporting year. Please verify and correct the inputs for these fields."
    let $type := "error"

    let $valid := scripts:getValidConcepts($value)

    let $reportingYear := $root/descendant::EUReg:ReportData/EUReg:reportingYear

    let $data :=
        for $x in $root/descendant::EUReg:ProductionInstallationPart
        let $id := scripts:getGmlId($x)
        let $derogations := replace($x/EUReg:derogations/@xlink:href, '/+$', '')

        where not(scripts:is-empty($derogations)) and $derogations = $valid
        let $derogations := scripts:normalize($derogations)

        where not(scripts:is-empty($reportingYear))
        let $reportingYear := xs:integer($reportingYear/text())

        where ($derogations = $article) and ($reportingYear gt $year)
        return map {
        "marks" : (4),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$id}</span>, $derogations, $reportingYear)
        }

    let $hdrs := ("Feature", "GML ID", "DerogationValue", "reportingYear")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C9.3 Limited lifetime derogation to reportingYear comparison
 :)

declare function scripts:checkArticle33(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $article := "Article33"
    let $year := 2023

    return scripts:checkDerogationsYear($refcode, $rulename, $root, $article, $year)
};

(:~
 : C9.4 District heating plants derogation to reportingYear comparison
 :)

declare function scripts:checkArticle35(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $article := "Article35"
    let $year := 2022

    return scripts:checkDerogationsYear($refcode, $rulename, $root, $article, $year)
};

declare function scripts:checkDerogationsContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element(),
  $msg as xs:string,
  $article as xs:string
) as element()* {
  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := $root/descendant::EUReg:derogations

  let $fromDB := database:query($cntry, $lastReportingYear, (
    "EUReg:derogations"
  ))

  let $value := "DerogationValue"
  let $valid := scripts:getValidConcepts($value)

  let $data :=
  for $x in $seq
    let $p := scripts:getParent($x)
    let $id := scripts:getInspireId($p)

    let $xderogations := replace($x/@xlink:href, '/+$', '')

    where not(scripts:is-empty($xderogations)) and $xderogations = $valid
    let $xder := scripts:normalize($xderogations)

    for $y in $fromDB
      let $q := scripts:getParent($y)
      let $ic := scripts:getInspireId($q)

      where $id = $ic

      let $yderogations := replace($y/@xlink:href, '/+$', '')

      where not(scripts:is-empty($yderogations)) and $yderogations = $valid
      let $yder := scripts:normalize($yderogations)

      where $yder = $article
      where not($xder = $article)

      return map {
        "marks": (3, 4),
        "data": ($p/local-name(), <span class="iedreg nowrap">{$id/text()}</span>, $xder, $yder)
      }

  let $hdrs := ("Feature", "Inspire ID", "DerogationValue", "DerogationValue (DB)")

  let $details := scripts:getDetails($msg, "warning", $hdrs, $data)

  return
    scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C9.5 Limited life time derogation continuity
 :)

declare function scripts:checkArticle33Continuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "Under certain limited lifetime derogations, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following ProductionInstallationParts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
  let $article := "Article33"

  return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : C9.6 District heat plant derogation continuity
 :)

declare function scripts:checkArticle35Continuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "Under the district heat plant derogation, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following Installation Parts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
  let $article := "Article35"

  return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : C9.7 Transitional National Plan derogation continuity
 :)

declare function scripts:checkArticle32Continuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "Under Transitional National Plan derogation, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following ProductionInstallationParts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
  let $article := "Article32"

  return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : 10. LCP & WASTE INCINERATOR CHECKS
 :)

(:~
 : C10.1 otherRelevantChapters to plantType comparison
 :)

declare function scripts:checkRelevantChapters(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The following ProductionInstallations have PlantTypeValues that are not consistent with the chapter specified in the otherRelevantChapters field. Please verify and ensure where 'Chapter III' is referred to the PlantTypeValue is 'LCP', and where 'Chapter IV' is referred the PlantTypeValue is 'WI'."
    let $type := "warning"

    let $validChapters := scripts:getValidConcepts("RelevantChapterValue")
    let $validPlants := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root/descendant::EUReg:ProductionInstallation

    let $data :=
        for $x in $seq
        let $x_id := scripts:getGmlId($x)
        let $chapter := replace($x/EUReg:otherRelevantChapters/@xlink:href, '/+$', '')

        where $chapter = $validChapters
        let $chapter := scripts:normalize($chapter)

        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root/descendant::EUReg:ProductionInstallationPart[@gml:id = $y_id]
        let $plant := replace($y/EUReg:plantType/@xlink:href, '/+$', '')

        where $plant = $validPlants
        let $plant := scripts:normalize($plant)

        where ((($chapter = "ChapterIII") and not($plant = "LCP")) or (($chapter = "ChapterIV") and not($plant = "WI")))
        return map {
        "marks" : (5, 6),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$x_id}</span>, $y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $chapter, $plant)
        }

    let $hdrs := ("Feature", "GML ID", "Feature", "GML ID", "Relevant Chapter", "Plant Type")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C10.2 LCP plantType
 :)

declare function scripts:checkLCP(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "When PlantTypeValue is 'LCP' the totalRatedThermalInput and derogations fields should both be populated, and nominalCapacity and specificConditions fields should not be populated. The populated fields for the following ProductionInstallationParts do not meet the above criteria. Please verify and ensure the correct fields have been populated."
    let $type := "warning"

    let $valid := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root/descendant::EUReg:ProductionInstallationPart

    let $data :=
        for $x in $seq
        let $id := scripts:getGmlId($x)
        let $plant := replace($x/EUReg:plantType/@xlink:href, '/+$', '')
        let $derogations := $x/EUReg:derogations
        let $totalRatedThermalInput := $x/EUReg:totalRatedThermalInput
        let $nominalCapacity := $x/EUReg:nominalCapacity
        let $specificConditions := $x/EUReg:nominalCapacity

        where $plant = $valid
        let $plant := scripts:normalize($plant)

        where $plant = "LCP" and (scripts:is-empty($derogations) or scripts:is-empty($totalRatedThermalInput) or not(scripts:is-empty($nominalCapacity)) and not(scripts:is-empty($specificConditions)))
        return map {
        "marks" : (),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$id}</span>)
        }


    let $hdrs := ("Feature", "GML ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C10.3 totalRatedThermalInput plausibility
 :)

declare function scripts:checkRatedThermalInput(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The totalRatedThermalInput fields in this submission contain an integer less than or equal to 50 or an integer greater than 8500, meaning the spatial object is no longer considered an LCP. Please verify and ensure the values entered are correct."
    let $type := "warning"

    let $seq := $root/descendant::EUReg:ProductionInstallationPart/EUReg:totalRatedThermalInput

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $v := xs:float($x)
        where $v le 50 or $v gt 8500

        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $v)
        }

    let $hdrs := ("Feature", "GML ID", "totalRatedThermalInput")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C10.4 WI plantType
 :)

declare function scripts:checkWI(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "When PlantTypeValue is 'WI' the nominalCapacity field should be populated, and totalRatedThermalInput and derogations fields should not be populated. The populated fields for the following ProductionInstallationParts do not meet the above criteria. Please verify and ensure the correct fields have been populated."
    let $type := "warning"

    let $valid := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root/descendant::EUReg:ProductionInstallationPart

    let $data :=
        for $x in $seq
        let $id := scripts:getGmlId($x)
        let $plant := replace($x/EUReg:plantType/@xlink:href, '/+$', '')
        let $derogations := $x/EUReg:derogations
        let $totalRatedThermalInput := $x/EUReg:totalRatedThermalInput
        let $nominalCapacity := $x/EUReg:nominalCapacity

        where $plant = $valid
        let $plant := scripts:normalize($plant)

        where $plant = "WI" and (not(scripts:is-empty($derogations)) or not(scripts:is-empty($totalRatedThermalInput)) or scripts:is-empty($nominalCapacity))
        return map {
        "marks" : (),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$id}</span>)
        }


    let $hdrs := ("Feature", "GML ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C10.5 nominalCapacity plausibility
 :)

declare function scripts:checkNominalCapacity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $error := "The integer supplied in the permittedCapacityHazardous field is greater than the integer supplied in the totalNominalCapacityAnyWasteType field, for the following ProductionInstallationParts. Please review and amend so the permittedCapacityHazardous field represents an integer less than or equal to the totalNominalCapacityAnyWasteType."
    let $warn := "The integer specified in the totalNominalCapacityAnyWasteType field exceeds the anticipated maximum threshold of 60. Please verify and ensure the integer supplied is correct."
    let $info := "The integer specified in the totalNominalCapacityAnyWasteType field is greater than the ideal threshold of 30. Please verify and ensure the integer supplied is correct."

    let $seq := $root/descendant::EUReg:ProductionInstallationPart/EUReg:nominalCapacity

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $hazardous := $x/descendant::EUReg:permittedCapacityHazardous/xs:float(.)
        let $any := $x/descendant::EUReg:totalNominalCapacityAnyWasteType/xs:float(.)

        return map {
        "marks" : (3, 4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $hazardous, $any)
        }

    let $red :=
        for $m in $data
        let $hazardous := $m("data")[3]
        let $any := $m("data")[4]
        where $hazardous gt $any
        return $m

    let $yellow :=
        for $m in $data
        let $hazardous := $m("data")[3]
        let $any := $m("data")[4]
        where $any gt 60
        return map {
        "marks" : (4),
        "data" : $m("data")
        }

    let $blue :=
        for $m in $data
        let $hazardous := $m("data")[3]
        let $any := $m("data")[4]
        where $any gt 30 and $any le 60
        return map {
        "marks" : (4),
        "data" : $m("data")
        }

    let $hdrs := ("Feature", "GML ID", "permittedCapacityHazardous", "totalNominalCapacityAnyWasteType")

    let $details :=
        <div class="iedreg">{
            if (empty($red)) then () else scripts:getDetails($error, "error", $hdrs, $red),
            if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
            if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
        }</div>

    return
        scripts:renderResult($refcode, $rulename, count($red), count($yellow), count($blue), $details)
};

(:~
 : 11. CONFIDENTIALITY CHECKS
 :)

(:~
 : C11.1 Confidentiality restriction
 :)

declare function scripts:checkConfidentialityRestriction(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The following ProductionFacilities and/or ProductionInstallations, have claims for confidentiality for the competent authority address. The address details of a competent authority cannot be claimed as confidential. Please leave the confidentialityReason field unpopulated"
    let $type := "error"

    let $seq := $root/descendant::*:CompetentAuthority

    let $data :=
        for $s in $seq
        let $feature := $s/parent::*/parent::*
        let $reason := $s/descendant::*:AddressDetails/child::*:confidentialityReason

        let $id := scripts:getGmlId($feature)
        let $p := scripts:getPath($reason)
        let $rsn := scripts:normalize(data($reason/attribute::*:href))

        where (not(scripts:is-empty($reason)))
        return map {
        "marks" : (4),
        "data" : ($feature/local-name(), <span class="iedreg nowrap">{$id}</span>, $p, $rsn)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "Confidentiality reason")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C11.2 Confidentiality overuse
 :)

declare function scripts:checkConfidentialityOveruse(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $warn := "The total amount of data types claiming confidentiality in the XML submission is PERC, which is greater than expected (10% of data types). Please evaluate to determine all inputs are correct and all cliams for confidentiality are necessary."
    let $info := "The total amount of data types claiming confidentiality in the XML submission is PERC, which is greater than ideally anticipated (5% of data types). Please evaluate to determine all inputs are correct and all claims for confidentiality are necessary."

    let $value := "ReasonValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := (
        $root/descendant::EUReg:AddressDetails,
        $root/descendant::EUReg:FeatureName,
        $root/descendant::EUReg:ParentCompanyDetails
    )

    let $data :=
        for $r in $seq/child::EUReg:confidentialityReason
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()

        let $p := scripts:getPath($r)
        let $id := scripts:getGmlId($parent)

        let $reason := $r/attribute::xlink:href
        let $v := scripts:normalize(data($reason))

        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $ratio := count($data) div count($seq)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Feature", "GML ID", "Path", "confidentialityReason")

    return
        if ($ratio gt 0.1) then
            let $msg := replace($warn, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
        else if ($ratio gt 0.05) then
            let $msg := replace($info, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "info", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : 12. OTHER IDENTIFIERS & MISCELLANEOUS CHECKS
 :)

declare function scripts:getIdentifier(
        $file as xs:string,
        $identifier as xs:string
) as element()* {
    let $url := "http://converterstest.eionet.europa.eu/xmlfile/" || $file
    return if (doc-available($url)) then
        doc($url)/descendant::*[local-name() = $identifier]
    else if (doc-available($file)) then
            doc($file)/descendant::*[local-name() = $identifier]
        else
            ()
};

declare function scripts:checkIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string,
        $identifier as xs:string,
        $ids as xs:string*
) as element()* {
    let $msg := "The following " || scripts:makePlural($feature) || " have " || $identifier || " values that are not valid. Please verify an ensure all IDs are correct."
    let $type := "warning"

    let $seq := $root/descendant::*[local-name() = $feature]/child::*[local-name() = $identifier]

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $id := scripts:getGmlId($parent)

        let $v := $x/text()
        where not($v = $ids)

        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $v)
        }

    let $hdrs := ("Feature", "GML ID", $identifier)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C12.1 ETSIdentifier validity
 :)

declare function scripts:checkETSIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $feature := "ProductionInstallation"
    let $identifier := "ETSIdentifier"
    let $ids := scripts:getIdentifier('iedreg-ets.xml', $identifier)/text()

    return scripts:checkIdentifier($refcode, $rulename, $root, $feature, $identifier, $ids)
};

(:~
 : C12.2 eSPIRSId validity
 :)

declare function scripts:checkeSPIRSIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $feature := "ProductionInstallation"
    let $identifier := "eSPIRSIdentifier"
    let $ids := scripts:getIdentifier('iedreg-espirs.xml', $identifier)/text()

    return scripts:checkIdentifier($refcode, $rulename, $root, $feature, $identifier, $ids)
};

(:~
 : C12.3 ProductionFacility facilityName to parentCompanyName comparison
 :)

declare function scripts:checkFacilityName(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The facilityName fields and parentCompany fields are the same for the following ProductionFacilities. Please verify and consider refining either name so that each name is distinct."
    let $type := "info"

    let $seq := $root/descendant::EUReg:ProductionFacility

    let $data :=
        for $x in $seq
        let $id := scripts:getGmlId($x)
        let $facilityName := $x/EUReg:facilityName/descendant::EUReg:nameOfFeature
        let $companyName := $x/EUReg:parentCompany/descendant::EUReg:parentCompanyName

        where not(scripts:is-empty($facilityName)) and not(scripts:is-empty($companyName))
        where ($facilityName/text() = $companyName/text())
        return map {
        "marks" : (3),
        "data" : ($x/local-name(), <span class="iedreg nowrap">{$id}</span>, $facilityName/text())
        }

    let $hdrs := ("Feature", "GML ID", "facilityName")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C12.4 nameOfFeature
 :)

declare function scripts:checkNameOfFeatureContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $msg := "The names, provided in this XML submission, for the following spatial objects are not the same as the names within the master database. Please verify and ensure that all names have been inputted correctly."
  let $type := "info"

  let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
  let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

  let $lastReportingYear := max(database:getReportingYearsByCountry($cntry))

  let $seq := $root/descendant::EUReg:nameOfFeature

  let $fromDB := database:query($cntry, $lastReportingYear, (
    "EUReg:nameOfFeature"
  ))

  let $data :=
  for $x in $seq
    let $p := scripts:getParent($x)
    let $id := scripts:getInspireId($p)

    for $y in $fromDB
      let $q := scripts:getParent($y)
      let $ic := scripts:getInspireId($q)

      where $id = $ic

      let $xName := normalize-space($x/text())
      let $yName := normalize-space($y/text())

      where not($xName = $yName)
      return map {
        "marks": (4, 5),
        "data": ($p/local-name(), <span class="iedreg nowrap">{$id/text()}</span>, <span class="iedreg nowrap">{$xName}</span>, <span class="iedreg nowrap">{$yName}</span>)
      }

  let $hdrs := ("Feature", "Inspire ID", "nameOfFeature", "nameOfFeature (DB)")

  let $details := scripts:getDetails($msg, $type, $hdrs, $data)

  return
    scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C12.5 reportingYear plausibility
 :)

declare function scripts:checkReportingYear(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The XML submission has a different reportingYear to that of Reportnet's envelope year. Please verify and ensure the correct year has been inputted."
    let $type := "warning"

    let $url := data($root/gml:metaDataProperty/attribute::xlink:href)
    let $envelope := doc($url)/envelope

    let $error :=
        if (scripts:is-empty($envelope)) then
            error(xs:QName('err:FOER0000'), 'Failed to retrieve envelope metadata')
        else
            ()

    let $envelopeYear := $envelope/year
    where not(scripts:is-empty($envelopeYear))
    let $envelopeYear := xs:integer($envelopeYear/text())

    let $seq := $root/descendant::EUReg:ReportData

    let $data :=
        for $x in $seq
        let $feature := $x/local-name()
        let $id := scripts:getGmlId($x)

        let $reportingYear := $x/EUReg:reportingYear
        let $p := scripts:getPath($reportingYear)

        where not(scripts:is-empty($reportingYear))
        let $reportingYear := xs:integer($reportingYear/text())

        return map {
        "marks" : (4, 5),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $reportingYear, $envelopeYear)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "reportingYear", "envelopeYear")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C12.6 electronicMailAddress format
 :)

declare function scripts:checkElectronicMailAddressFormat(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The email address specified in the electronicMailAddress field, for the following ProductionFacility/ProductionInstallation, does not contain the at (@) symbol and at least one dot (.) after it (e.g. emailaddress@test.com). Please verify and ensure all email addresses are inputted correctly"
    let $type := "info"

    let $seq := $root/descendant::*:electronicMailAddress

    let $data :=
        for $r in $seq
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()

        let $p := scripts:getPath($r)
        let $id := scripts:getGmlId($parent)
        let $email := $r/text()

        where (not(matches($r, '.+@.+\..{2,63}')))
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $email)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "E-mail address")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C12.7 Lack of facility address
 :)

declare function scripts:checkFacilityAddress(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warn := "The number of ProductionFacilities without the address field populated equals PERC, which exceeds threshold limit 0.7%. Please verify and populate the required address fields."
    let $info := "The number of ProductionFacilities without the address field populated equals PERC, which exceeds recommended limit 0.1%. Please verify and populate the required address fields."

    let $seq := $root/descendant::*:ProductionFacility

    let $data :=
        for $f in $seq
        let $inspireId := scripts:getInspireId($f)

        let $p := scripts:getPath($f)
        let $id := scripts:getGmlId($f)

        where (string-length(string-join($f/child::*:address/child::*:AddressDetails/child::*, '')) = 0)
        return map {
        "marks" : (2),
        "data" : ($p, <span class="iedreg nowrap">{$id}</span>)
        }

    let $ratio := count($data) div count($seq)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Path", "Inspire ID")

    return
        if ($ratio <= 0.001) then
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
        else if ($ratio <= 0.007) then
            let $msg := replace($info, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "info", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
        else
            let $msg := replace($warn, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C12.8 Character string space identification
 :)

declare function scripts:checkWhitespaces(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The first character, of the following spatial objects' characterStrings, represents a space. Please verify and ensure the CharacterString has been inputted correctly to prevent duplication"
    let $type := "warning"

    let $seq := $root/descendant::*

    let $data :=
        for $e in $seq
        let $p := scripts:getPath($e)
        let $whites := <whites>{functx:get-matches-and-non-matches($e/text(), '^\s+')}</whites>
        let $result := <span class="iedreg">&quot;<pre class="iedreg">{replace(replace(replace($whites/match/text(), '\t', '\\t'), '\r', '\\r'), '\n', '\\n')}</pre>{$whites/non-match/text()}&quot;</span>

        where ($e/text() and not($e/*) and not(normalize-space($e) = '') and not(empty($e/text())) and matches($e, '^\s+'))
        return map {
        "marks" : (2),
        "data" : ($p, $result)
        }

    let $hdrs := ("Path", "CharacterString")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : vim: sts=2 ts=2 sw=2 et
 :)
