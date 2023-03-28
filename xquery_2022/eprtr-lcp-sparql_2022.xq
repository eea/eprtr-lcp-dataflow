xquery version "3.0";

(:~
  : -------------------------
  : Sparqlx Function Library
  : -------------------------
 
  : Creation date: March 2023
:)

module namespace sparqlx = "eprtr-lcp-sparql_2022";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint :)
declare variable $sparqlx:CR_SPARQL_URL := "https://cr.eionet.europa.eu/sparql";

declare function sparqlx:run($sparql as xs:string) as element(sparql:result)* {
    doc("https://cr.eionet.europa.eu/sparql?query=" || encode-for-uri($sparql) || "&amp;format=application/xml")//sparql:result
};

declare function sparqlx:getLink($sparql as xs:string) as xs:string* {
    "https://cr.eionet.europa.eu/sparql?query=" || encode-for-uri($sparql) || "&amp;format=application/html"
};

(:~
 : Get the SPARQL endpoint URL.
 : @param $sparql SPARQL query.
 : @param $format xml or html.
 : @param $inference use inference when executing sparql query.
 : @return link to sparql endpoint
 :)
declare function sparqlx:getSparqlEndpointUrlz($sparql as xs:string, $format as xs:string) as xs:string {
    let $sparql := fn:encode-for-uri(fn:normalize-space($sparql))
    let $resultFormat :=
        if ($format = "xml") then
            "application/xml"
        else if ($format = "html") then
            "text/html"
        else
            $format
    let $defaultGraph := ""
    let $uriParams := concat("query=", $sparql, "&amp;format=", $resultFormat, $defaultGraph)
    let $uri := concat($sparqlx:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};
