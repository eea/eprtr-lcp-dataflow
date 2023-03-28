xquery version "3.0" encoding "UTF-8";

(:~
  : ------------------------------
  : Sparql Query Function Library
  : ------------------------------
 
  : Creation date: March 2023
:)

module namespace query = "eprtr-lcp-query_2022";
import module namespace sparqlx = "eprtr-lcp-sparql_2022" at "eprtr-lcp-sparql_2022.xq";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";


(: C0 :)
(: The query returns the latest report envelope for a specific country and reporting year :)
declare function query:getLatestEnvelopePerYearOrFilenotfound(
    $cdrUrl as xs:string,
    $reportingYear as xs:string
) as xs:string {
  let $query := concat("
PREFIX iedreg: <http://rod.eionet.europa.eu/schema.rdf#>
SELECT *
WHERE {
    FILTER(CONTAINS(str(?graph), '", $cdrUrl,"')) 
    GRAPH ?graph {
        ?envelope a iedreg:Delivery ;
                    iedreg:released ?date ;
                    iedreg:hasFile ?file ;
                    iedreg:period ?period
    } 
    FILTER(CONTAINS(str(?period), '", $reportingYear, "')).
    FILTER regex(?file, '(xml|gml)').
  } 
  order by desc(?date)
  limit 1
")
  let $result := distinct-values(data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri))
  return if ($result) then $result else "FILENOTFOUND"
};
