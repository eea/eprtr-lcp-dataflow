xquery version "1.0" encoding "UTF-8";

(:~
 : XQuery script that validates the reported data on the LCP report.
 :
 : @author Aris Katsanas
 :)

declare namespace xmlconv="http://converters.eionet.europa.eu";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace functx = "http://www.functx.com";
declare namespace eworx = "http://www.eworx.gr";


declare variable $source_url as xs:string external;
(: xml files paths:)

declare variable $xmlconv:BASIC_DATA_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_basicdata.xml");
declare variable $xmlconv:OLD_PLANTS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_v2_plantsdb.xml");
declare variable $xmlconv:CLRTAP_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_clrtap.xml");
declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_avg_emissions.xml");
declare variable $xmlconv:FINDINGS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_Findings_Step1.xml");

declare variable $xmlconv:VALID_OTHER_SECTOR as xs:string* := ("iron_steel","esi","district_heating","chp","other");
declare variable $eworx:SchemaModel := eworx:getSchemaModel($source_url);


(: HELPER FUCTIONS START :)
(: http://www.xqueryfunctions.com/ :)
declare function functx:non-distinct-values
( $seq as xs:anyAtomicType* )  as xs:anyAtomicType* {

    for $val in distinct-values($seq)
    return $val[count($seq[. = $val]) > 1]
} ;

declare function functx:if-empty
( $arg as item()? ,
        $value as item()* )  as item()* {

    if (string($arg) != '')
    then data($arg)
    else $value
} ;

declare function functx:substring-after-last-match
( $arg as xs:string? ,
        $regex as xs:string )  as xs:string {

    replace($arg,concat('^.*',$regex),'')
} ;

declare function functx:substring-before-if-contains
( $arg as xs:string? ,
        $delim as xs:string )  as xs:string? {

    if (contains($arg,$delim))
    then substring-before($arg,$delim)
    else $arg
} ;

declare function functx:name-test
( $testname as xs:string? ,
        $names as xs:string* )  as xs:boolean {

    $testname = $names
            or
            $names = '*'
            or
            functx:substring-after-if-contains($testname,':') =
                    (for $name in $names
                    return substring-after($name,'*:'))
            or
            substring-before($testname,':') =
                    (for $name in $names[contains(.,':*')]
                    return substring-before($name,':*'))
} ;

declare function functx:substring-after-if-contains
( $arg as xs:string? ,
        $delim as xs:string )  as xs:string? {

    if (contains($arg,$delim))
    then substring-after($arg,$delim)
    else $arg
} ;

declare function functx:dynamic-path
( $parent as node() ,
        $path as xs:string )  as item()* {

    let $nextStep := functx:substring-before-if-contains($path,'/')
    let $restOfSteps := substring-after($path,'/')
    for $child in
        ($parent/*[functx:name-test(name(),$nextStep)],
        $parent/@*[functx:name-test(name(),
                substring-after($nextStep,'@'))])
    return if ($restOfSteps)
    then functx:dynamic-path($child, $restOfSteps)
    else $child
} ;

declare function functx:path-to-node
( $nodes as node()* )  as xs:string* {

    $nodes/string-join(ancestor-or-self::*/name(.), '/')
} ;

(: HELPER FUNCTIONS END :)

(: :)

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

declare function eworx:testBasicElementType( $elem as element() ){

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


declare function eworx:testDocumentBasicTypes( $source_url as xs:string ){

    let $res := for $attr in doc($source_url)//Plant/descendant::*
    where  eworx:testBasicElementType($attr) = "false"
    return <tr>
        <td class='error' title="Details"> Invalid input value on the field <b> { name($attr) } </b></td>
        <td title="PlantId">{ data   (($attr)/ancestor::*/PlantId ) }</td>
        <td class="tderror" title="Invalid value">{ data ( $attr ) }</td>
        <td title="xml path">{ functx:path-to-node (($attr) ) }</td>

    </tr>

    return
        if (exists($res )) then
            xmlconv:RowBuilder("LCP XML","XML Document Validity Errors. QAs did not run","",$res)
        else ()


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

declare function xmlconv:RowBuilder ( $RuleCode as xs:string, $RuleName as xs:string, $ResMessage as xs:string, $ResDetails as element()*  ) as element( ) *{

  let $RuleCode := substring-after($RuleCode, ' ')

    let $errors := $ResDetails/td[@class = 'error']
    let $warnings := $ResDetails/td[@class = 'warning']
    let $info := $ResDetails/td[@class = 'info']

    let $ResCode := if ( count($errors) > 0) then 'error'
    else if   ( count($warnings) > 0 ) then 'warning'
    else if   ( count($info) > 0 ) then 'info'
    else 'passed'

    (: $ResCode the result of the QA :)

    (: TESTING :)
    let $ResMessage := <p> { count($errors) } Errors, { count($warnings) } Warnings { if (count($info) > 0) then concat(' , ' ,xs:string(count($info)), ' Info' ) else () } </p>

    let $step1 :=
        (: Row Result :)
        <tr class="mainviewrow">
            <td class="bullet">
                <div class="{$ResCode}">{ $RuleCode }</div>
            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (count($ResDetails) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")' class="feedback">Show records</a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
                }
            </tr>

    let $step2 := if (count($ResDetails) > 0 ) then
        <tr style="display:none;" id="feedbackRow-{$RuleCode}">
            <td colspan="4">
                <table class="showdatatable table table-bordered" >
                    <tr>{
                        for $th in $ResDetails[1]//td return <th>{ data($th/@title) }</th>
                    }</tr>
                    {$ResDetails}


                </table>
            </td>
        </tr>
    else ()

    return ( $step1 , $step2 )


    };

declare function xmlconv:RowAggregator ( $RuleCode as xs:string, $RuleName as xs:string, $ResMessage as xs:string, $ResRows as element()*  ) as element( ) *{

  let $RuleCode := substring-after($RuleCode, ' ')

    let $errors := $ResRows/td/div[@class = 'error']
    let $warnings := $ResRows/td/div[@class = 'warning']
    let $info := $ResRows/td/div[@class = 'info']

    let $ResCode := if ( count($errors) > 0) then 'error'
    else if   ( count($warnings) > 0 ) then 'warning'
        else if   ( count($info) > 0 ) then 'info'
            else 'passed'


    (: TESTING :)
    let $ResMessage := <p> { count($errors) } Subchecks issued Errors, { count($warnings) } Subchecks issued Warnings { if (count($info) > 0) then concat(' , ' ,xs:string(count($info)), ' Info' ) else () } </p>

    let $step1 :=
        (: Row Result :)
        <tr class="detailsrow">
            <td class="bullet">

                <div class="{$ResCode}">{ $RuleCode }</div>

            </td>


            <td class="rulename">{ $RuleName }</td>
            <td class="message">{ $ResMessage }</td>

            {if (count($ResRows) > 0 ) then
                <td>
                    <a id='feedbackLink-{$RuleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$RuleCode}")'>Show records</a>
                </td>
            else <td> </td> (: space to keep the table rows consistent:)
            }
        </tr>

    let $step2 := if (count($ResRows) > 0 ) then
        <tr style="display:none;" id="feedbackRow-{$RuleCode}">
            <td colspan="1">
                <td colspan="4">
                <table class="detailstable table table-bordered">

                    {
                        for $res in $ResRows return ( $res  )
                    }

                </table>
                </td>
            </td>
        </tr>
    else ()

    return ( $step1 , $step2 )


};

(::)

declare function xmlconv:RunQAs( $source_url ) as element()* {


    let $docRoot := doc($source_url)
    let $memberState := if ( $docRoot//BasicData/MemberState = "UK") then ("GB", "UK")
      else $docRoot//BasicData/MemberState
    let $reportingYear := eworx:getNumber ( $docRoot//BasicData/ReferenceYear )

    (: external files used for some checks :)
    let $oldBasic := doc($xmlconv:BASIC_DATA_PATH)
    let $oldReport := if ( $reportingYear = 2016 ) then doc($xmlconv:OLD_PLANTS_PATH)//Plant[MemberState = $memberState and $reportingYear - 1 = ReferenceYear] (: get MS's previous year plants :)
        else ()

    let $findings := doc($xmlconv:FINDINGS_PATH)

    (: Get Vocabularies from DD :)
    let $xmlconv:VALID_OTHER_SECTOR :=
        if (doc-available("http://dd.eionet.europa.eu/vocabulary/lcp/sectors/rdf") ) then
            let $dd := doc("http://dd.eionet.europa.eu/vocabulary/lcp/sectors/rdf")
        for $i in $dd//(skos:Concept)
            return functx:substring-after-last-match(data($i/@rdf:about), '/')
     else
        $xmlconv:VALID_OTHER_SECTOR


    (: LCP 1.1 - Basic Data :)

    (: Valid Email :)
    let $email := $docRoot//BasicData/Email
    let $invalidEmail :=
      if
      (  ( matches(($email),
                '^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$') ) ) then
            ()
           else
          <tr>
           <td class='error' title="Details"> Please Provide a valid email address</td>
              <td class="tderror" title="Email">{data($email)}</td>
          </tr>

    (:  Required fields for each plant :)
    let $invalidPlant :=
        for $plant in ($docRoot//Plant[ functx:if-empty(PlantName,'') ='' or functx:if-empty(PlantId,'') =''])
        return  <tr>
            <td class='error' title="Details"> Please provide all the mandatory fields</td>
            <td class="{ if (functx:if-empty( data($plant/PlantName)   , ' ') = ' ') then "tderror" else ""  }" title="PlantName"> { functx:if-empty( data($plant/PlantName)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($plant/PlantId)   , ' ') = ' ') then "tderror" else ""  }" title="PlantID"> { functx:if-empty( data($plant/PlantId)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($plant/PlantLocation/StreetName)   , ' ') = ' ') then "tderror" else ""  }" title="StreetName"> { functx:if-empty( data($plant/PlantLocation/StreetName)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($plant/PlantLocation/City)   , ' ') = ' ') then "tderror" else ""  }" title="City"> { functx:if-empty( data($plant/PlantLocation/City)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($plant/PlantLocation/PostalCode)   , ' ') = ' ') then "tderror" else ""  }" title="PostalCode"> { functx:if-empty( data($plant/PlantLocation/PostalCode)   , '#Missing Value')  } </td>
        </tr>

    (:  :)
    let $invalidRefinery :=
        for $plant in ($docRoot//Plant[  PlantDetails/Refineries = ('', 'false') and not ( data(PlantDetails/OtherSector)= $xmlconv:VALID_OTHER_SECTOR )  ] )
        return  <tr>
            <td class='error' title="Details"> When not Refinery, OtherSector should be filled with one of the valid values</td>
            <td title="PlantName"> {  functx:if-empty (data($plant/PlantName) ,  '#Missing Value') } </td>
            <td title="PlantID"> { functx:if-empty( data($plant/PlantId)   , '#Missing Value')  } </td>
            <td class="tderror" title="Refineries"> { functx:if-empty ( data($plant/PlantDetails/Refineries)   , '#Missing Value')  } </td>
            <td class="tderror" title="OtherSector"> { functx:if-empty( data($plant/PlantDetails/OtherSector)   , '#Missing Value'  ) } </td>
        </tr>

    (: warning if some contact info missing :)
    let $missingContactInfo :=
    for $bdata in ($docRoot//BasicData[  Organization = '' or StreetName = '' or City = '' or NameOfDepartmentContactPerson = '' or Phone = '' or PostalCode = '' ])
    return
        <tr>
            <td class='warning' title="Details"> Missing some contact info </td>
            <td class="{ if (functx:if-empty( data($bdata/NameOfDepartmentContactPerson)   , ' ') = ' ') then "tdwarning" else ""  }" title="NameOfDepartmentContactPerson"> { functx:if-empty( data($bdata/NameOfDepartmentContactPerson)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($bdata/Organization)   , ' ') = ' ') then "tdwarning" else ""  }" title="Organization"> { functx:if-empty( data($bdata/Organization)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($bdata/City)   , ' ') = ' ') then "tdwarning" else ""  }" title="City"> { functx:if-empty( data($bdata/City)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($bdata/StreetName)   , ' ') = ' ') then "tdwarning" else ""  }" title="StreetName"> { functx:if-empty( data($bdata/StreetName)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($bdata/PostalCode)   , ' ') = ' ') then "tdwarning" else ""  }" title="PostalCode"> { functx:if-empty( data($bdata/PostalCode)   , '#Missing Value')  } </td>
            <td class="{ if (functx:if-empty( data($bdata/Phone)   , ' ') = ' ') then "tdwarning" else ""  }" title="Phone"> { functx:if-empty( data($bdata/Phone)   , '#Missing Value')  } </td>
        </tr>

    let $message := if (count($invalidEmail) > 0) then "Please provide a valid email" else "passed"

    let $LCP_1_1_1 := xmlconv:RowBuilder("LCP 1.1.1","Valid Email", $message,  $invalidEmail  )
    let $LCP_1_1_2 := xmlconv:RowBuilder("LCP 1.1.2","Contact Info", $message,  $missingContactInfo  )
    let $LCP_1_1_3 := xmlconv:RowBuilder("LCP 1.1.3","Plant Completeness", $message,  $invalidPlant  )
    let $LCP_1_1_4 := xmlconv:RowBuilder("LCP 1.1.4","Not Refinery", $message,  $invalidRefinery  )

    let $LCP_1_1_A := xmlconv:RowAggregator("LCP 1.1","Basic Data Completeness", $message, ($LCP_1_1_1, $LCP_1_1_2, $LCP_1_1_3, $LCP_1_1_4) )

    let $LCP_1_1 := $LCP_1_1_A
    (: LCP 1.2 :)

    let $LCP_1_2 := if ( $reportingYear != 2016 ) then ()
    else

        let $res := if ( eworx:getNumber( $docRoot//BasicData/NumberOfPlants ) != count($docRoot//Plant) ) then
            <tr>
                <td class='error' title="Details"> Number of plants in Basic Data form differs from the number of reported plants. </td>
                <td title="Number of plants(Basic Data)">{data($docRoot//BasicData/NumberOfPlants)}</td>
                <td title="Number of plants found">{count($docRoot//Plant) }</td>
            </tr>
        else

            let $diff := ( ( eworx:getNumber ($docRoot//BasicData/NumberOfPlants ) - $oldBasic//BasicData[MemberState = $memberState and $reportingYear - 1 = ReferenceYear]/NumberOfPlants ) div
                    abs($oldBasic//BasicData[MemberState = $memberState and $reportingYear - 1 = ReferenceYear]/NumberOfPlants) )
            return
            if ( abs( $diff ) > 0.1 ) then
                <tr>
                    <td class='warning' title="Details"> Please provide an explanation for the significant deviation of Plant Count</td>
                    <td title="#Plants this year">{data($docRoot//BasicData/NumberOfPlants)}</td>
                    <td title="#Plants last year">{data($oldBasic//BasicData[MemberState = $memberState and $reportingYear - 1 = ReferenceYear]/NumberOfPlants)}</td>
                    <td class="tdwarning" title="Change(%)">{$diff * 100}</td>
                </tr>
            else if ( abs( $diff ) > 0.05 ) then
                <tr>
                    <td class='info' title="Details"> Deviation in the number of plants versus last report</td>
                    <td title="#Plants this year">{data($docRoot//BasicData/NumberOfPlants)}</td>
                    <td title="#Plants last year">{data($oldBasic//BasicData[MemberState = $memberState and $reportingYear - 1 = ReferenceYear]/NumberOfPlants)}</td>
                    <td class="tdinfo" title="Change(%)">{$diff * 100}</td>

                </tr>
            else
                ()

        return xmlconv:RowBuilder("LCP 1.2","Number of plants", $message, $res  )


    (: LCP 2.1 - Unequivocal naming of plants:)
    let $dupl := functx:non-distinct-values( $docRoot//Plant/PlantName)
    let $res :=
        for $plant in $docRoot//Plant[PlantName = $dupl]

            return (: Returns records with duplicate Plant Name :)
                <tr>
                    <td class='error' title="Details"> Please provide a unique plant name</td>
                    <td class="tderror" title="PlantName"> { data($plant/PlantName)  } </td>
                    <td title="PlantID"> { data($plant/PlantId)  } </td>
                    <td title="EPRTRNationalId"> { data($plant/EPRTRNationalId)  } </td>
                    <td title="FacilityName"> { data($plant/FacilityName)  } </td>
                </tr>

    let $LCP_2_1 := xmlconv:RowBuilder("LCP 2.1","Unequicoval naming of plants", $message, $res  )

    (: LCP 2.2 :)
    let $oldIds :=  $oldReport//PlantId
    let $LCP_2_2 := if ( $reportingYear != 2016 ) then ()
    else
        let $res:=
            for $plant in $docRoot//Plant[PlantId = $oldIds]
            where ( fn:normalize-space( string( $oldReport[  PlantId  = $plant/PlantId ][1]/PlantName ) ) != string(fn:normalize-space($plant/PlantName[1]) ) )
            return
                <tr>
                    <td class='warning' title="Details"> Make sure to use the comments to explain the change of the name</td>
                    <td title="PlantID"> { data($plant/PlantId)  } </td>
                    <td class="tdwarning" title="PlantName({$reportingYear})"> { data($plant/PlantName)  } </td>
                    <td class="tdwarning" title="PlantName({$reportingYear - 1})"> { data($oldReport[  PlantId   = $plant/PlantId ]/PlantName )  } </td>
                    <td class="tdwarning" title="Comments"> { functx:if-empty( data($plant/Comments) , ' ')  } </td>
                </tr>

        return xmlconv:RowBuilder("LCP 2.2","Consistency of plant ID and name over time", $message, $res  )

    (: LCP 2.3 :)

    let $invalidCoords :=
        for $plant in $docRoot//Plant
        let $memberState := if ($memberState = "UK") then "GB"
            else $memberState
        return
            (: fallback check with mapquest :)
            if ( $plant//GeographicalCoordinate/Latitude = "" or $plant//GeographicalCoordinate/Longitude = "") then
                <tr>
                    <td class='error' title="Details"> Please provide coordinates for the plant</td>
                    <td title="PlantID"> { data($plant/PlantId)  } </td>
                    <td title="PlantName({$reportingYear})"> { data($plant/PlantName)  } </td>
                    <td class="tderror" title="Latitude"> { data($plant//GeographicalCoordinate/Latitude)  } </td>
                    <td class="tderror" title="Longitude"> { data($plant//GeographicalCoordinate/Longitude)  } </td>
                </tr>

            else if ($memberState != ( eworx:geonames($plant//GeographicalCoordinate/Latitude, $plant//GeographicalCoordinate/Longitude)  ) ) then
                if ( $memberState != eworx:mapquest($plant//GeographicalCoordinate/Latitude, $plant//GeographicalCoordinate/Longitude)) then
                        <tr>
                            <td class='error' title="Details"> Coordinates out of country borders</td>
                            <td title="PlantID"> { data($plant/PlantId)  } </td>
                            <td title="PlantName({$reportingYear})"> { data($plant/PlantName)  } </td>
                            <td class="tderror" title="Latitude"> { data($plant//GeographicalCoordinate/Latitude)  } </td>
                            <td class="tderror" title="Longitude"> { data($plant//GeographicalCoordinate/Longitude)  } </td>
                        </tr>
                else
                    ()
            else
                ()

    let $decimalCoord :=
        for $plant in $docRoot//Plant[ GeographicalCoordinate/Latitude != "" and GeographicalCoordinate/Longitude != "" and
        not (( string-length( substring-after( GeographicalCoordinate/Latitude, '.') ) >= 5 )
                and
                ( string-length( substring-after( GeographicalCoordinate/Longitude, '.') ) >= 5 ) )
        ]
        return <tr>
            <td class='warning' title="Details"> Please provide 5 decimal places for each coordinate of the plant</td>
            <td title="PlantID"> { data($plant/PlantId)  } </td>
            <td title="PlantName({$reportingYear})"> { data($plant/PlantName)  } </td>
            <td class="{ if (string-length( substring-after( $plant//GeographicalCoordinate/Latitude, '.') ) >= 5 ) then () else "tdwarning" }" title="Latitude"> { data($plant//GeographicalCoordinate/Latitude) } </td>
            <td class="{ if (string-length( substring-after( $plant//GeographicalCoordinate/Longitude, '.') ) >= 5 ) then () else "tdwarning" }" title="Longitude"> { data($plant//GeographicalCoordinate/Longitude)  } </td>
        </tr>

    let $LCP_2_3 := xmlconv:RowBuilder("LCP 2.3","Location check", $message, ($invalidCoords , $decimalCoord )  )

    (: LCP 2.4 :)

    let $res:=
        for $plant in $docRoot//Plant[  EPRTRNationalId  = "" ]
        return
        <tr>
            <td class='warning' title="Details"> Make sure you have provided a comment for the missing E-PRTR ID</td>
            <td title="PlantName"> { data($plant/PlantName)  } </td>
            <td title="PlantID"> { data($plant/PlantId)  } </td>
            <td class="tdwarning" title="EPRTRNationalId"> { functx:if-empty( data($plant/EPRTRNationalId) , '#Missing' ) } </td>
            <td class="tdwarning" title="Comments"> { functx:if-empty(data($plant/Comments) , ' ')  } </td>
        </tr>

    let $LCP_2_4 := xmlconv:RowBuilder("LCP 2.4","E-PRTR ID", $message, $res  )

    (: LCP 3.2 :)
    let $below50K :=
        for $plant in $docRoot//Plant
        where  ( functx:if-empty ( eworx:getNumber ($plant/PlantDetails/MWth ) < 50 , 0 ))
        return
            <tr>
                <td class='error' title="Details"> Plants with 50MW or more are to be reported</td>
                <td title="PlantName"> { data($plant/PlantName)  } </td>
                <td title="PlantID"> { data($plant/PlantId)  } </td>
                <td class="tderror" title="MW"> { data($plant/PlantDetails/MWth)  } </td>
            </tr>

    let $excluded := $findings/dataroot/QAQC_Findings_Step1[MemberState=$memberState and substring(Test, 4,3) = '3.2']

    let $above10M :=
        for $plant in $docRoot//Plant[ not (  PlantId = $excluded/PlantId ) ]
        where  ( ( eworx:getNumber ($plant/PlantDetails/MWth ) > 10000 ))
        return
            <tr>
                <td class='info' title="Details"> Large value of MWth  </td>
                <td title="PlantName"> { data($plant/PlantName)  } </td>
                <td title="PlantID"> { data($plant/PlantId)  } </td>
                <td class="tdinfo" title="MW"> { data($plant/PlantDetails/MWth)  } </td>
            </tr>

    let $LCP_3_2 := xmlconv:RowBuilder("LCP 3.2","Rated thermal input value", $message, ($below50K , $above10M ) )


    (: LCP 3.3 :)

    let $excluded := $findings/dataroot/QAQC_Findings_Step1[MemberState=$memberState and substring(Test, 4,3) = '3.3']

    let $res :=
        for $plant in $docRoot//Plant[ not (  PlantId = $excluded/PlantId ) ]
        return
            let $Biomass := eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass)
            let $Coal := eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal)
            let $Lignite := eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite)
            let $OtherSolidFuels := sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherSolidFuels/OtherSolidFuel[Value castable as xs:double]/Value)
            let $LiquidFuels :=  eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels)
            let $NaturalGas :=  eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas)
            let $OtherGases :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherGases/OtherGas[Value castable as xs:double]/Value)
            let $Peat :=  eworx:getNumber($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat)

            let $inputinTJ := eworx:sum ( ( $Biomass, $Coal, $Lignite, $LiquidFuels, $NaturalGas, $OtherGases , $OtherSolidFuels, $Peat, 0)  )

                        (: input in TJ is compared to rated thermal input in MW:)
            let $ratio := $inputinTJ div eworx:getNumber($plant/PlantDetails/MWth)

            let $a:= if ($ratio > 100) then
                <tr>
                    <td class='warning' title="Details"> Fuel input to thermal input ratio very high. Please confirm in the comments</td>
                    <td title="PlantName"> { string($plant/PlantName)  } </td>
                    <td title="PlantID"> { string($plant/PlantId)  } </td>
                    <td title="Total Input(TJ)"> { string($inputinTJ)  } </td>
                    <td title="Rated Thermal Input(MW)"> { string($plant/PlantDetails/MWth)  } </td>
                    <td class="tdwarning" title="Ratio"> { round-half-to-even ($ratio ,2)  } </td>
                </tr>
            else if ($ratio > 34) then
                <tr>
                    <td class='info' title="Details"> Fuel input to thermal input ratio among the highest reported</td>
                    <td title="PlantName"> { string($plant/PlantName)  } </td>
                    <td title="PlantID"> { string($plant/PlantId)  } </td>
                    <td title="Total Input(TJ)"> { string($inputinTJ)  } </td>
                    <td title="Rated Thermal Input(MW)"> { string($plant/PlantDetails/MWth)  } </td>
                    <td class="tdinfo" title="Ratio"> { round-half-to-even ($ratio, 2)  } </td>
                </tr>
            else
                ()
            return $a

    let $LCP_3_3 := xmlconv:RowBuilder("LCP 3.3","Plausibility of fuel input", $message, $res  )

    (: LCP 4.1 :)
    let $LCP_4_1 := if ( $reportingYear != 2016 ) then ()
    else
        let $CLRTAP := doc($xmlconv:CLRTAP_PATH)//country[MemberState = $memberState and Year = $reportingYear ]

        let $tsp := if  ($CLRTAP/TSP castable as xs:double ) then
            round-half-to-even ( (eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP) div ($CLRTAP/TSP * 1000) ) * 100 , 3 ) else
            'Dust emissions were not reported under CLRTAP. Therefore they cannot be compared to emissions reported under the LCP Directive'

        let $res := <tr>
            <td class='info' title="Details"> Percentage of plant emissions to national total</td>
            <td title="SO2 (%)"> { round-half-to-even(  ( eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2) div ($CLRTAP/SO2 * 1000) ) * 100, 3 )}  </td>
            <td title="NOx (%)"> { round-half-to-even( ( eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx ) div ( $CLRTAP/NOx * 1000 ) ) * 100, 3 )} </td>
            <td title="Dust (%)"> { $tsp }  </td>
        </tr>

        return xmlconv:RowBuilder("LCP 4.1","Share in overall reported emissions", $message, $res  )


    (: LCP 4.2 :)
    (: excluding plants with energy total input of 1 or less TJ:)
    (: excluding plants that have been resolved/resolved for all years:)
    let $excluded := $findings/dataroot/QAQC_Findings_Step1[MemberState=$memberState and substring(Test, 4,3) = '4.2']

    let $res :=
        for $plant in $docRoot//Plant[ not (  PlantId = $excluded/PlantId ) ]
            let $Biomass :=  if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass)castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass) else 0
            let $OtherSolidFuels :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherSolidFuels/OtherSolidFuel[Value castable as xs:double]/Value)
            let $LiquidFuels :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) else 0
            let $NaturalGas :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) else 0
            let $OtherGases :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherGases/OtherGas[Value castable as xs:double]/Value)
            let $Peat := if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) else 0
            let $Coal := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) else 0
            let $Lignite := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) else 0
            let $totalInputTJ := $Biomass + $OtherSolidFuels + $LiquidFuels + $NaturalGas + $OtherGases + $Coal + $Lignite + $Peat

            let $oBio := $Biomass * 0.0085
            let $oSolid := $OtherSolidFuels * 0.3463
            let $oLiq := $LiquidFuels * 0.1360
            let $oNatGas := $NaturalGas * 0.0003
            let $oOtherGas := $OtherGases * 0.0083
            let $oCoal := $Coal * 0.3020
            let $oLignite := $Lignite * 0.3020
            let $oPeat := $Peat * 0.3020

            let $expected := $oBio + $oSolid + $oNatGas + $oOtherGas + $oLiq + $oCoal + $oLignite + $oPeat
            let $expected := if ($expected = 0)
                                then 0.0000001
                                else $expected

            let $SO2 := if (($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2) castable as xs:double)
                        then xs:double($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2)
                        else 0
            where(
                $expected > 0.0000001
                and
                    $totalInputTJ > 1
                and (
                    $SO2 div $expected > 20
                    or (
                        ($SO2 div $expected < 1 div 500)
                        and
                        $oBio + $oSolid + $oOtherGas + $oLiq + $oCoal + $oLignite + $oPeat > 0
                    )
                )
            )
            return
                <tr>
                    <td class='warning' title="Details">Significant difference in reported and expected SO2 emissions</td>
                    <td title="PlantName"> { data($plant/PlantName)  } </td>
                    <td title="PlantID"> { data($plant/PlantId)  } </td>
                    <td class="tdwarning" title="SO2"> { $SO2  } </td>
                    <td title="expected SO2"> { round-half-to-even ($expected , 3) } </td>
                </tr>

    let $LCP_4_2 := xmlconv:RowBuilder("LCP 4.2","SO2 emission outlier test", $message, $res  )


    (: LCP 4.3 :)

    let $excluded := $findings/dataroot/QAQC_Findings_Step1[MemberState=$memberState and substring(Test, 4,3) = '4.3']

    let $res :=
        for $plant in $docRoot//Plant[ not (  PlantId = $excluded/PlantId ) ]
        let $Biomass :=  if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass)castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass) else 0
        let $OtherSolidFuels :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherSolidFuels/OtherSolidFuel[Value castable as xs:double]/Value)
        let $LiquidFuels :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) else 0
        let $NaturalGas :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) else 0
        let $OtherGases :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherGases/OtherGas[Value castable as xs:double]/Value)
        let $Peat := if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) else 0
        let $Coal := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) else 0
        let $Lignite := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) else 0

        let $oBio := $Biomass * 0.0854
        let $oSolid := $OtherSolidFuels * 0.1598
        let $oLiq := $LiquidFuels * 0.0912
        let $oNatGas := $NaturalGas * 0.0250
        let $oOtherGas := $OtherGases * 0.0339
        let $oCoal := $Coal * 0.1271
        let $oLignite := $Lignite * 0.1271
        let $oPeat := $Peat * 0.1271

        let $expected := $oBio + $oSolid + $oNatGas + $oOtherGas + $oLiq + $oCoal + $oLignite + $oPeat
        let $expected := if ($expected = 0)
                            then 0.0000001
                            else $expected

        let $NOx := if (($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx) castable as xs:double)
                    then xs:double($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx)
                    else 0
        where(
            $expected > 0.0000001
            and (
                $NOx div $expected > 20
                or
                $NOx div $expected < 1 div 10
            )
        )
        return
            <tr>
                <td class='warning' title="Details">Significant difference in reported and expected NOx emissions</td>
                <td title="PlantName"> { data($plant/PlantName)  } </td>
                <td title="PlantID"> { data($plant/PlantId)  } </td>
                <td class="tdwarning" title="NOx"> { $NOx } </td>
                <td title="expected NOx"> { round-half-to-even ( $expected, 3)  } </td>
            </tr>

    let $LCP_4_3 := xmlconv:RowBuilder("LCP 4.3","NOx emission outlier test", $message, $res  )

    (: LCP 4.4 :)
    (: excluding plants with energy total input of 1 or less TJ:)
    let $excluded := $findings/dataroot/QAQC_Findings_Step1[MemberState=$memberState and substring(Test, 4,3) = '4.4']

    let $res :=
        for $plant in $docRoot//Plant[ not (  PlantId = $excluded/PlantId ) ]
            let $Biomass :=  if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass)castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Biomass) else 0
            let $OtherSolidFuels :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherSolidFuels/OtherSolidFuel[Value castable as xs:double]/Value)
            let $LiquidFuels :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/LiquidFuels) else 0
            let $NaturalGas :=  if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/NaturalGas) else 0
            let $OtherGases :=  sum($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/OtherGases/OtherGas[Value castable as xs:double]/Value)
            let $Peat := if (($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Peat) else 0
            let $Coal := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Coal) else 0
            let $Lignite := if ( ($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) castable as xs:double) then xs:double($plant/EnergyInputAndTotalEmissionsToAir/EnergyInput/Lignite) else 0
            let $totalInputTJ := $Biomass + $OtherSolidFuels + $LiquidFuels + $NaturalGas + $OtherGases + $Peat + $Coal + $Lignite

            let $oBio := $Biomass * 0.0041
            let $oSolid := $OtherSolidFuels * 0.0202
            let $oLiq := $LiquidFuels * 0.0048
            let $oNatGas := $NaturalGas * 0.0001
            let $oOtherGas := $OtherGases * 0.0004
            let $oCoal := $Coal * 0.0134
            let $oLignite := $Lignite * 0.0134
            let $oPeat := $Peat * 0.0134

            let $expected := $oBio + $oSolid + $oNatGas + $oOtherGas + $oLiq + $oCoal + $oLignite + $oPeat
            let $expected := if ($expected = 0)
                                then 0.0000001
                                else $expected

            let $TSP := if (($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP) castable as xs:double)
                            then xs:double($plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP)
                            else 0
            where(
                $expected > 0.0000001
                and
                    $totalInputTJ > 1
                and (
                    $TSP div $expected > 20
                    or
                    (
                        $TSP div $expected < 1 div 500
                        and
                        $oBio + $oSolid + $oOtherGas + $oLiq + $oCoal + $oLignite + $oPeat > 0
                    )
                )
            )
            return
                <tr>
                    <td class='warning' title="Details">Significant difference in reported and expected TSP emissions</td>
                    <td title="PlantName"> { data($plant/PlantName)  } </td>
                    <td title="PlantID"> { data($plant/PlantId)  } </td>
                    <td class="tdwarning" title="Dust"> { $TSP } </td>
                    <td title="expected Dust"> { round-half-to-even ( $expected, 3)  } </td>
                </tr>

    let $LCP_4_4 := xmlconv:RowBuilder("LCP 4.4","Dust emission outlier test", $message, $res  )


    (: LCP 4.5 :)

    let $LCP_4_5 := if ( $reportingYear != 2016 ) then ()
    else

        let $Avg_Emissions := doc($xmlconv:AVG_EMISSIONS_PATH)//emissions[MemberState = $memberState and $reportingYear - 1 = Year]

        (: SO2:)

        let $diff :=   ( eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2) - eworx:getNumber($Avg_Emissions/SO2) ) div abs(eworx:getNumber($Avg_Emissions/SO2))

        let $res1 :=
            if ( abs($diff) > 0.3) then
                <tr>
                    <td class='warning' title="Details"> More than 30% diffence in this year's total <b>SO2</b> amounts reported to the average of last three years. Please provide a brief explanation for this change in emissions. </td>
                    <td title="Total Reported Amount({$reportingYear})"> {  eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2) }</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/SO2 }</td>
                    <td class="tdwarning" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>
                </tr>
            else if ( abs($diff) > 0.1 ) then
                <tr>
                    <td class='info' title="Details"> More than 10% diffence in this year's total <b>SO2</b> amounts reported to the average of last three years.</td>
                    <td title="Total Reported Amount({$reportingYear})"> {  eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/SO2) }</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/SO2 }</td>
                    <td class="tdinfo" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>
                </tr>
            else ()

        (: NOx :)

        let $diff :=   ( eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx) - eworx:getNumber($Avg_Emissions/NOx) ) div abs(eworx:getNumber($Avg_Emissions/NOx))

        let $res2 :=
            if ( abs($diff) > 0.3) then
                <tr>
                    <td class='warning' title="Details"> More than 30% diffence in this year's total <b>NOx</b> amounts reported to the average of last three years. Please make sure that the reported data are correct. </td>
                    <td title="Total Reported Amount({$reportingYear})"> {  eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx) }</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/NOx }</td>
                    <td class="tdwarning" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>

                </tr>
            else if ( abs($diff) > 0.1 ) then
                <tr>
                    <td class='info' title="Details"> More than 10% diffence in this year's total <b>NOx</b> amounts reported to the average of last three years.</td>
                    <td title="Total Reported Amount({$reportingYear})"> {  eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/NOx) }</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/NOx }</td>
                    <td class="tdinfo" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>
                </tr>
            else ()

        (: TSP :)

        let $diff :=   ( eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP) - eworx:getNumber($Avg_Emissions/TSP) ) div abs(eworx:getNumber($Avg_Emissions/TSP))

        let $res3 :=
            if ( abs($diff) > 0.3) then
                <tr>
                    <td class='warning' title="Details"> More than 30% diffence in this year's total amount of <b>Dust</b> reported to the average of last three years. Please make sure that the reported data are correct. </td>
                    <td title="Total Reported Amount({$reportingYear})"> {   eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP) }</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/TSP }</td>
                    <td class="tdwarning" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>

                </tr>
            else if ( abs($diff) > 0.1 ) then
                <tr>
                    <td class='info' title="Details"> More than 10% diffence in this year's total amount of <b>Dust</b> reported to the average of last three years.</td>
                    <td title="Total Reported Amount({$reportingYear})"> {  eworx:sum($docRoot//Plant/EnergyInputAndTotalEmissionsToAir/TotalEmissionsToAir/TSP)}</td>
                    <td title="Average of Total Reported Amount ({$reportingYear - 3}-{$reportingYear - 1})"> {  $Avg_Emissions/TSP }</td>
                    <td class="tdinfo" title="Change (%) "> {  round-half-to-even ($diff * 100 , 2 )} </td>
                </tr>
            else ()

            return xmlconv:RowBuilder("LCP 4.5","Consistency with emission trend at national level", $message, ($res1,$res2,$res3)  )

    (: RETURN ALL ROWS IN A TABLE :)

    return
(       $LCP_1_1 ,
         $LCP_1_2 ,
         $LCP_2_1 ,
         $LCP_2_2 ,
         $LCP_2_3 ,
         $LCP_2_4 ,
         $LCP_3_2 ,
         $LCP_3_3 ,
         $LCP_4_1 ,
         $LCP_4_2 ,
         $LCP_4_3 ,
         $LCP_4_4 ,
         $LCP_4_5
)

};

declare function xmlconv:DoValidate($source_url as xs:string) as element(table){

    let $res :=
    if ( exists(eworx:testDocumentBasicTypes($source_url))) then
        eworx:testDocumentBasicTypes($source_url)
    else
        xmlconv:RunQAs($source_url)

    return   <table class="table table-bordered table-condensed" id="maintable">
        <colgroup>
            <col width="45px" style="text-align:center"/>
            <col width="40%" style="text-align:left"/>
            <col width="40%" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        { $res }

    </table>
};

(:~
: JavaScript
:)
declare function xmlconv:getJS() as element(script) {

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}


    function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display === "table-row") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "table-row";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}
                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};



(:~
: Legend
:)
declare function xmlconv:getLegend() as element()*{

    let $legend :=
        <fieldset style="font-size: 90%; display: inline;" id="legend">
            <legend>How to read the test results</legend>
            All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
            <ul style="list-style-type: none;">QC TESTS
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="error">Red</div></div> - the check issued an error. Please correct the invalid records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="warning">Orange</div></div> - the check issued a warning. Please review the corresponding records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="info">Blue</div></div> - the check issued info. Please review the corresponding records.</li>
                <li><div class="bullet" style="width:50px; display:inline-block;margin-left:10px"><div class="passed">Green</div></div> - the check passed without errors or warnings.</li>
            </ul>
            <p>Click on the "Show records" link to see more details about the test result.</p>
        </fieldset>
    return
        (<br></br>,$legend,<br></br>, <br></br>)
};



(:~
: CSS
:)
declare function xmlconv:getCSS() as element()*{
(
 <style>
<![CDATA[

.bullet {
  width: 55px; }

.bullet div {
  font-size: 0.8em;
  color: white;
  padding-left: 5px;
  padding-right: 5px;
  margin-right: 5px;
  margin-top: 2px;
  text-align: center;
  width: 50px; }

.bullet div.error {
  background-color: #E83131; }

.bullet div.warning {
  background-color: #F5A105; }

.bullet div.info {
  background-color: #2D789C; }

.bullet div.passed {
  background-color: #409C2D; }

table {
  width: 100%; }

th, td {
  padding: 3px; }

.rulename {
  text-align: left;
  font-weight: bold; }

.message {
  text-align: right; }

#maintable {
  background-color: #FAFAFA; }

.showdatatable {
  font-size: 15px; }
  .showdatatable tr .error {
    background-color: #f2dede; }
  .showdatatable .tderror {
    border: 2px solid  #E83131;
    background-color: #FFFFFF; }
  .showdatatable .tdwarning {
    border: 2px solid  #F5A105;
    background-color: #FFFFFF;  }
  .showdatatable .tdinfo {
    border: 2px solid  #2D789C;
    background-color: #FFFFFF; ; }
h2 {
  font-weight: bold;
  padding: 0.2em 0.4em;
  background-color: rgb(240, 244, 245);
  color: #000000;
  border-top: 1px solid rgb(224, 231, 215);
}

]]>
</style>,  <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" rel="stylesheet"></link>
)

};

declare function xmlconv:main($source_url as xs:string) {

  let $ResultTable := xmlconv:DoValidate( $source_url )



  (: failedQA are the QAs that failed(at least on error :)
  let $failedQA :=  $ResultTable/tr[td/div/@class = 'error']
  let $nameofailedQA := data($failedQA/td/div)

  let $errors := if ( count($nameofailedQA) > 0 ) then
      <div> This XML file issued crucial errors in the following checks : <font color="#E83131"> { fn:string-join($nameofailedQA , ' , ') } </font>

      </div>
  else
      <div> This XML file issued no crucial errors       <br/>
      </div>


  let $warningQAs :=  $ResultTable/tr[td/div/@class = 'warning']
  let $nameofwarnQA := data($warningQAs/td/div)

  let $warnings := if ( count($warningQAs) > 0 ) then
      <div> This XML file issued warnings in the following checks : <font color="orange"> { fn:string-join($nameofwarnQA , ' , ') } </font>

      </div>
  else
      <div> This XML file issued no warnings       <br/>
      </div>

  let $infoQA :=  $ResultTable/tr[td/div/@class = 'info']
  let $infoName := data($infoQA/td/div)

  let $infos := if ( count($infoQA) > 0 ) then
      <div> This XML file issued info for the following checks : <font color="blue"> { fn:string-join($infoName , ' , ')  }  </font>

      </div>
  else
      ()
  let $js := xmlconv:getJS()

  let $legend := xmlconv:getLegend()

  let $css := xmlconv:getCSS()

  let $feedbackStatus := if (exists ($failedQA) ) then <div>(<level>BLOCKER</level>,<msg>{ $errors }</msg>)</div>
  else if (exists ($warningQAs) )  then <div> (<level>WARNING</level>,<msg>{ $warnings }</msg>)</div>
  else <div>(<level>INFO</level>,<msg>"No errors or warnings issued"</msg>)</div>



  (::)
  return
      <div class="feedbacktext">
      <span id="feedbackStatus" class="{$feedbackStatus//level}" style="display:none">{data($feedbackStatus//msg)}</span>
          <h2>Reporting obligation for: Summary of emission inventory for large combustion plants (LCP), Art 4.(4) and 15.(3) plants
      </h2>

            { ( $css, $js, $errors, $warnings, $infos, $legend,  $ResultTable )}

      </div>



};

xmlconv:main($source_url)
