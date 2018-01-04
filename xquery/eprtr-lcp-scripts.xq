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

declare function scripts:getValidConcepts($value as xs:string, $vocName as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $vocabulary := "https://dd.eionet.europa.eu/vocabulary/"
    let $url := $vocabulary || $vocName || "/" ||$value || "/rdf"
    return
        data(doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/@rdf:about)
};

