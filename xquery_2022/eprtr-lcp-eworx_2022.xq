xquery version "3.0";

(:~
: User: laszlo
: Date: 1/4/18
: Time: 11:42 AM
: To change this template use File | Settings | File Templates.
:)

module namespace eworx = "http://www.eworx.gr";

import module namespace functx = "http://www.functx.com" at "eprtr-lcp-functx_2022.xq";

declare function eworx:getSchemaTypes
( $node as node()* ) {

    let $name := $node/@name
    let $res := for $i in ($node)/child::*
    return
        if (name($i) = "xs:complexType") then
            eworx:getSchemaTypes($i)
        else if (name($i) = "xs:sequence") then
            eworx:getSchemaTypes($i)
        else if ( name($i) = "xs:element") then
                element {data($i/@name)}  {($i/@type, eworx:getSchemaTypes($i))}
            else
                ()

    return
        $res
};

declare function eworx:getNumber ( $value ) {

  if ( $value castable as xs:double) then
        xs:double( $value )
  else ()

};

declare function eworx:getSchemaModel
( $source_url as xs:string ) {

    eworx:getSchemaTypes(doc(doc($source_url)//@xsi:noNamespaceSchemaLocation)/xs:schema)

} ;

declare function eworx:testBasicElementType( $elem as element() , $source_url as xs:string){

    let $eworx:SchemaModel := eworx:getSchemaModel($source_url)
    let $path := functx:path-to-node($elem) (: get the path of the element :)
    (: and check the type of the element according to the schema model:)
    let $metaType := functx:dynamic-path (<lol> {$eworx:SchemaModel} </lol> , $path)/@type

    let $res :=
        if ($metaType = "xs:integer") then
            if ($elem castable as xs:integer) then "true"
            else if ($elem = "") then "true"
            else "false"

        else if ($metaType = "xs:float") then
            if ($elem castable as xs:float) then "true"
            else if ($elem = "") then "true"
            else "false"

        else if ($metaType = "xs:double") then
            if ($elem castable as xs:double) then "true"
            else if ($elem = "") then "true"
            else "false"

        else if ($metaType = "xs:date") then
            if ($elem castable as xs:date) then "true"
            else if ($elem = "") then "true"
            else "false"

        else if ($metaType = "xs:boolean") then
            if ($elem castable as xs:boolean) then "true" else "false"

        else if ($metaType = "TrueFalseType") then
            if ($elem castable as xs:boolean) then "true"
            else if ($elem = "") then "true"
            else "false"
        else
            "true"

    return $res

} ;


declare function eworx:sum( $seq ){

    let $nseq :=
        for $i in $seq
        return
            if ($i castable as xs:double) then $i
            else ()

    return sum($nseq)

} ;

declare function eworx:normalizeId( $oldid as xs:string, $country_code as xs:string ){
    (: behavior for testing on reports with the old PlantId format :)
    if ($country_code = "DE") then
        ( substring( $oldid, 3) , $oldid)
    else
        ( xs:integer( substring($oldid , 3 )), $oldid )

} ;


(: BACKUP REVERSE GEOCODE PROVIDER :)
declare function eworx:mapquest( $latitude as xs:string?, $longitude as xs:string?) {

    let $key := "7DQbW5ZaXUsKZy0gJz3K9yG0GDZbpDkr"

    let $url := concat("http://open.mapquestapi.com/nominatim/v1/reverse.php?key=" , $key , "&amp;format=xml&amp;lat=" , $latitude , "&amp;lon=" , $longitude )

    let $ret :=
    if ( doc-available( $url) ) then
        let $res := doc($url)
        return upper-case($res//country_code)
    else
     ()

    return $ret
};

(: REVERSE GEOCODE PROVIDER :)
declare function eworx:geonames( $latitude as xs:string?, $longitude as xs:string?) as xs:string? {

    let $username := "aka_eworx"

    let $url := concat("http://api.geonames.org/countryCodeXML?lat=" , $latitude , "&amp;lng=" , $longitude , '&amp;username=' , $username )

    let $ret :=
    if ( doc-available( $url) ) then
        let $res := doc($url)
        return upper-case($res//countryCode)
    else
        ()

    return $ret

};
