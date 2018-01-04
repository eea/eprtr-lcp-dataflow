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

module namespace scripts3 = "iedreg-scripts-qa3";

import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";
import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";

declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace gml = "http://www.opengis.net/gml/3.2";

(:~
 : 13.12+
 :)

(: C13.12 otherRelevantChapters consistency

    <EUReg:otherRelevantChapters  xlink:href > shall contain a value from codelist
    http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/RelevantChapterValue
:)
declare function scripts3:checkOtherRelevantChapters(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "RelevantChapter"
    let $activityType := "otherRelevantChapters"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(: C13.13 pf:status consistency

    <pf:statusType xlink:href > shall contain a value from codelist
    http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/
:)

declare function scripts3:checkStatusType(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility, ProductionInstallation or ProductionInstallationPart"
    let $activityName := "ConditionOfFacility"
    let $activityType := "statusType"
    let $seq := $root/descendant::*[local-name() = "status"]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(: C13.14 plantType consistency

    <EUReg:plantType xlink:href > shall contain a value from codelist
    http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/PlantTypeValue
:)

declare function scripts3:checkPlantType(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "PlantType"
    let $activityType := "plantType"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(: C13.15 derogations consistency

    <EUReg:derogations  xlink:href> shall contain values from codelist
    http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/DerogationValue/
:)

declare function scripts3:checkDerogations(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "Derogation"
    let $activityType := "derogations"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(: C13.16 derogations consistency

    <EUReg:specificConditions  xlink:href> shall contain values
    from codelist  http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/Article51Value
:)

declare function scripts3:checkSpecificConditions(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "Article51"
    let $activityType := "specificConditions"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C13 OTHER CHECKS
:)

(: C13.1 checkReportData

    "must start with # and be followed by the value of the gml:id of the Report Data feature.
    This means checking that starts with ""#""  +  what follows is the gml:id of the ReportData feature type.
    Example: <EUReg:reportData xlink:href=""#RD_1""/> is correct if the element <EUReg:ReportData gml:id=""RD_1""> exists"
:)

declare function scripts3:checkReportData(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionSite"
    let $activityType := "reportData"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]
    let $gmlID := data($root/descendant::*[local-name() = "ReportData"][@gml:id]/@gml:id)

    let $msg := "The gml:ID specified in the " || $activityType || " field for the following " ||
                scripts:makePlural($featureName) || " is not recognised.
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@xlink:href)

        let $ok := (
            $v eq concat("#", $gmlID)
            and
            fn:substring($v, 1, 1) eq "#"
        )
        where not($ok)
            return map {
            "marks" : (5),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v, $gmlID)
            }

    let $hdrs := ("Feature", "GML ID", "Path", concat($activityType, " xlink:href"), "ReportData gml:id")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: C13.2 hostingSite

    "Each facility must specify its hosting site. The  hostingSite is  optional
    in INSPIRE PF (so the XMLValidator would not detect the error),
    but for the EURegistry it is mandatory (oneHostingSite constraint).
    This means that for the <EUReg:ProductionFacility> the </pf:status> tag
    shall be followed by the <pf:hostingSite> tag"
:)

declare function scripts3:checkeHostingSite(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $seq := $root/descendant::*[local-name() = $featureName]

    let $msg := "The status element is not followed by hostingSite element in the following " ||
                scripts:makePlural($featureName)||". Please verify and ensure the correct order of elements"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)
        let $indexOfStatus :=
            if (exists($seq/child::*[local-name() = "status"]))
            then
                functx:index-of-node($seq/*, $seq/*[local-name() = "status"])
            else
                0
        let $indexOfHostingSite :=
            if (exists($seq/child::*[local-name() = "hostingSite"]))
            then
                functx:index-of-node($seq/*, $seq/*[local-name() = "hostingSite"])
            else
                0

        let $p := scripts:getPath($x)

        let $ok := $indexOfHostingSite - $indexOfStatus = 1
        where not($ok)
        return map {
        "marks" : (5),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $indexOfStatus, $indexOfHostingSite)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "position of pf:status", "position of pf:hostingSite")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: C13.3 pf:hostingSite xlink:href

    "must start with # and be followed by the value of the gml:id of the relevant ProductionSite
    Example:  <pf:hostingSite xlink:href=""#_123456789.Site""/> is correct if the
    <EUReg:ProductionSite gml:id=""_123456789.Site""> element exists"
:)

declare function scripts3:checkeHostingSiteHref(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityType := "hostingSite"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]
    let $gmlID := data($root/descendant::*[local-name() = "ProductionSite"][@gml:id]/@gml:id)

    let $msg := "The gml:ID specified in the " || $activityType || " xlink:href field for the following " ||
                scripts:makePlural($featureName) || " is not recognised.
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@xlink:href)

        let $ok := (
            $v eq concat("#", $gmlID)
            and
            fn:substring($v, 1, 1) eq "#"
        )
        where not($ok)
            return map {
            "marks" : (5),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v, $gmlID)
            }

    let $hdrs := ("Feature", "GML ID", "Path", concat($activityType, " xlink:href"), "ProductionSite gml:id")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: C13.4 pf:groupedInstallation 

    "Each installation belongs to a facility. For each ProductionInstallation gml:id,
    a relevant <pf:groupedInstallation xlink:href=""#_gml:id""/> must exist.
    Example:
    for the <EUReg:ProductionInstallation gml:id=""_010101011.INSTALLATION""> there must be the element
    <pf:groupedInstallation xlink:href=""#_010101011.INSTALLATION""/>"
:)

declare function scripts3:checkGroupedInstallation(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityType := "groupedInstallation"
    let $seq := $root/descendant::*[local-name() = "ProductionInstallation"]
    let $gmlIDs := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]/@xlink:href

    let $msg := "The gml:id specified in the following " || scripts:makePlural("ProductionInstallation") ||
                " does not have a relevant " || $activityType || ".
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@gml:id)

        let $ok := count(fn:index-of($gmlIDs, concat("#", $v))) >= 1
        where not($ok)
            return map {
            "marks" : (3),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p)
            }

    let $hdrs := ("Feature", "GML ID", "Path")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: C13.5 pf:groupedInstallation xlink:href
"must start with # and be followed by the value of the gml:id of the relevant production installation
Example: <pf:groupedInstallation xlink:href=""#_010101011.INSTALLATION""/> is correct if the production installation
<EUReg:ProductionInstallation gml:id=""_010101011.INSTALLATION""> exists"

:)

declare function scripts3:checkGroupedInstallationHref(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityType := "groupedInstallation"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]
    let $gmlIDs := $root/descendant::*[local-name() = "ProductionInstallation"]/@gml:id

    let $msg := "The gml:id specified in the following " || scripts:makePlural($activityType) ||
                " does not have a relevant ProductionInstallation.
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@xlink:href)

        let $ok := (
            count(fn:index-of($gmlIDs, fn:substring($v, 2))) >= 1
            and
            fn:substring($v, 1, 1) eq "#"
        )
        where not($ok)
            return map {
            "marks" : (4),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
            }

    let $hdrs := ("Feature", "GML ID", "Path", "groupedInstallation/@xlink:href")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:  C13.6 act-core:geometry

    in INSPIRE PF, the geometry for the facility is a generic GM_Object,
    the EURegistry constraints to be a point (geometryIsKindOfGM_Point constraint).
    <act-core:geometry> descendant shall be <gml:Point>
:)

declare function scripts3:checkActCoreGeometry(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = "geometry"]

    let $msg := "The act-core:geometry does not have gml:Point descendant for the following " ||
                scripts:makePlural($featureName) || ". Please verify them"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)

        let $ok := exists($x/descendant::*[local-name() = "Point"])
        where not($ok)
            return map {
            "marks" : (3),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p)
            }

    let $hdrs := ("Feature", "GML ID", "Path")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: 13.7 act-core:activity validity

    <act-core:activity xlink:href> shall contain a value from codelist
    http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/NACEValue
:)

declare function scripts3:checkActCoreActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "NACE"
    let $activityType := "activity"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(: 13.8 pf:groupedInstallationPart validity

    for each ProductionInstallationPart gml:id , a relevant <pf:groupedInstallationPart xlink:href=""#_gml:id""/> must exist.
    Example:
    for the <EUReg:ProductionInstallationPart gml:id=""_987654321.PART""> there must be
    a related element <pf:groupedInstallationPart xlink:href=""#_987654321.PART""/>
:)

declare function scripts3:checkGroupedInstallationPart(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityType := "groupedInstallationPart"
    let $seq := $root/descendant::*[local-name() = $featureName]
    let $gmlIDs := $root/descendant::*[local-name() = "ProductionInstallation"]/descendant::*[local-name() = $activityType]/@xlink:href

    let $msg := "The gml:id specified in the following " || scripts:makePlural($featureName) ||
                " does not have a relevant " || $activityType || ".
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@gml:id)

        let $ok := count(fn:index-of($gmlIDs, concat("#", $v))) >= 1
        where not($ok)
            return map {
            "marks" : (3),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p)
            }

    let $hdrs := ("Feature", "GML ID", "Path")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: 13.9 pf:groupedInstallationPart xlink:href validity

    must start with # and be followed by the value of the gml:id of the relevant production installation
    Example: <pf:groupedInstallationPart xlink:href=""#_987654321.PART""/> is correct if the installation part
    <EUReg:ProductionInstallationPart gml:id=""_987654321.PART""> exists"
:)

declare function scripts3:checkGroupedInstallationPartHref(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityType := "groupedInstallationPart"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]
    let $gmlIDs := $root/descendant::*[local-name() = "ProductionInstallationPart"]/@gml:id

    let $msg := "The gml:id specified in the following " || scripts:makePlural($activityType) ||
                " does not have a relevant ProductionInstallationPart.
                Please verify and ensure the correct gml:ID has been inputted"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $v := data($x/@xlink:href)

        let $ok := (
            count(fn:index-of($gmlIDs, fn:substring($v, 2))) >= 1
            and
            fn:substring($v, 1, 1) eq "#"
        )
        where not($ok)
            return map {
            "marks" : (4),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
            }

    let $hdrs := ("Feature", "GML ID", "Path", "groupedInstallationPart/@xlink:href")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:  13.10 pf:status validity

    status field in INSPIRE PF is 'voidable -one to many', whilst EURegistry constraints it not to be void
    and be only one (onlyOneStatusAndNotVoid constraint). The status value must moreover
    be contained in ConditionOfFacilityValue codelist
    This means that :
    1. elements <pf:status xsi:nil=""true""/>  are not allowed
    2. two consecutive <pf:status> elements are not allowed."
:)


declare function scripts3:checkStatusNil(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := ("ProductionFacility", "ProductionInstallation", "ProductionInstallationPart")
    let $activityType := "status"
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $activityType]

    let $msg := "The " || $activityType ||" element in the following " || scripts:makePlural(fn:string-join($featureName, ', ')) ||
                " have xsi:nil attribute value true or two or more consecutive pf:status elements are found.
                Please verify pf:status elements"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)

        let $ok := (
            fn:lower-case($x/@xsi:nil) ne "true"
            and
            $x/following-sibling::*[1]/local-name() ne $activityType
        )
        let $v := if (fn:lower-case($x/@xsi:nil) eq "true")
                    then
                        "xsi:nil is true"
                    else
                        "two or more consecutive elements found"
        where not($ok)
            return map {
            "marks" : (4),
            "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
            }
    let $hdrs := ("Feature", "GML ID", "Path", "status")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:  13.11 pf:pointGeometry validity

    The pointGeometry field is  optional  in INSPIRE PF (so the XMLValidator would not detect the error),
    but for the EURegistry it is mandatory (pointGeometryIsMandatory constraint)
    For the <EUReg:ProductionInstallation> and the <EUReg:ProductionInstallationPart>,
    the </pf:inspireId> tag shall be followed by the <pf:pointGeometry> tag
:)


declare function scripts3:checkePointGeometry(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := ("ProductionInstallation", "ProductionInstallationPart")
    let $seq := $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = "inspireId"]

    let $msg := "The inspireId element is not followed by pointGeometry element
                in the following " || scripts:makePlural(fn:string-join($featureName, ', ')) ||
                ". Please verify and ensure the correct order of elements"
    let $type := "error"

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($x)
        let $following := $x/following-sibling::*[1]/local-name()

        let $ok := $following = "pointGeometry"
        where not($ok)
        return map {
        "marks" : (5),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $following)
        }

    let $hdrs := ("Feature", "GML ID", "Path", "element after inspireId")
    let $details := scripts:getDetails($msg, $type, $hdrs, $data)
    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : vim: sts=2 ts=2 sw=2 et
 :)
