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

module namespace db = "iedreg-database";

declare namespace EUReg = 'http://dd.eionet.europa.eu/euregistryonindustrialsites';
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";

declare namespace rest = "http://basex.org/rest";

declare variable $db:master := "http://admin:admin@ied-registry.herokuapp.com/rest/MASTER";

declare function db:getFeatureNames(
        $featureName as xs:string,
        $nameName as xs:string
) as element()* {
    let $seq :=
        for $file in doc($db:master)/rest:database/rest:resource/text()
        let $file := $db:master || "/" || $file
        let $doc := doc($file)
        let $root := $doc/child::gml:FeatureCollection

        return $root/descendant::*[local-name() = $featureName]/descendant::*[local-name() = $nameName]/descendant::*:nameOfFeature

    for $x at $i in $seq
    let $p := scripts:getParent($x)
    let $id := scripts:getInspireId($p)

    let $o :=
        for $y in subsequence($seq, $i + 1)
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id != $ic
        return $x
    where count($seq) - $i = count($o)
    return $x
};

declare function db:getAll(
        $name as xs:string
) as element()* {
    for $file in doc($db:master)/rest:database/rest:resource/text()
    let $file := $db:master || "/" || $file
    let $doc := doc($file)
    let $root := $doc/child::gml:FeatureCollection

    let $seq := $root/descendant::*[name() = $name]

    return $seq
};

declare function db:getReportingCountries(
) as element()* {
    for $file in doc($db:master)/rest:database/rest:resource/text()
    let $file := $db:master || "/" || $file
    let $doc := doc($file)
    let $root := $doc/child::gml:FeatureCollection

    let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

    return $cntry
};

declare function db:getReportingYearsByCountry(
        $c as xs:string
) as xs:string* {
    for $file in doc($db:master)/rest:database/rest:resource/text()
    let $file := $db:master || "/" || $file
    let $doc := doc($file)
    let $root := $doc/child::gml:FeatureCollection

    let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]
    where $cntry = $c

    let $year := $root/descendant::EUReg:ReportData/EUReg:reportingYear
    let $yr := $year/text()

    order by xs:integer($yr)
    return $yr
};

declare function db:query(
        $c as xs:string,
        $y as xs:string,
        $name as xs:string
) as element()* {
    for $file in doc($db:master)/rest:database/rest:resource/text()
    let $file := $db:master || "/" || $file
    let $doc := doc($file)
    let $root := $doc/child::gml:FeatureCollection

    let $country := $root/descendant::EUReg:ReportData/EUReg:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]
    where $cntry = $c

    let $year := $root/descendant::EUReg:ReportData/EUReg:reportingYear
    let $yr := $year/text()
    where $yr = $y

    let $seq := $root/descendant::*[name() = $name]

    return $seq
};

(:~
 : vim: sts=2 ts=2 sw=2 et
 :)
