xquery version "3.1" encoding "UTF-8";

(:
    XQuery script that validates the reported data on the EPRTR and LCP report.
:)

import module namespace functx = "http://www.functx.com" at "eprtr-lcp-functx.xq";
import module namespace eworx = "http://www.eworx.gr" at "eprtr-lcp-eworx.xq";
import module namespace scripts = "eprtr-lcp-scripts" at "eprtr-lcp-scripts.xq";

declare namespace xmlconv = "http://converters.eionet.europa.eu";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $source_url as xs:string external;
(: xml files paths:)

declare variable $xmlconv:BASIC_DATA_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_basicdata.xml");
declare variable $xmlconv:OLD_PLANTS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_v2_plantsdb.xml");
declare variable $xmlconv:CLRTAP_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_clrtap.xml");
declare variable $xmlconv:AVG_EMISSIONS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_avg_emissions.xml");
declare variable $xmlconv:FINDINGS_PATH as xs:string := ("https://converters.eionet.europa.eu/xmlfile/LCP_Findings_Step1.xml");

declare variable $xmlconv:VALID_OTHER_SECTOR as xs:string* := ("iron_steel","esi","district_heating","chp","other");
(:declare variable $eworx:SchemaModel := eworx:getSchemaModel($source_url);:)

declare function xmlconv:RowBuilder ( $RuleCode as xs:string, $RuleName as xs:string, $ResDetails as element()*  ) as element( ) *{

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

declare function xmlconv:isInVocabulary(
        $seq as element()*,
        $concept as xs:string
) as element()*{
    let $valid := scripts:getValidConcepts($concept)
        for $elem in $seq
        let $ok := $valid = data($elem)
        return
            if (not($ok))
            then
                <tr>
                    <td class='error' title="Details"> {$concept} has not been recognised</td>
                    <td class="tderror" title="{node-name($elem)}"> {data($elem)} </td>
                    <!-- <td title="localId"> {data($elem/ancestor-or-self::*[local-name() = $feature]//localId)} </td> -->
                    <td title="path">{functx:path-to-node($elem)}</td>
                </tr>
            else
                ()
};

declare function xmlconv:RunQAs( $source_url ) as element()* {

    let $docRoot := doc($source_url)

    (:
        C1.1 – combustionPlantCategory consistency
    :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/combustionPlantCategory/combustionPlantCategory
        return xmlconv:isInVocabulary($seq, "CombustionPlantCategoryValue")
    let $LCP_1_1 := xmlconv:RowBuilder("EPRTR-LCP 1.1","combustionPlantCategory consistency", $res )

    (:
        C1.2 – CountryCode consistency
    :)
    let $res :=
        let $seq := $docRoot//*[local-name() = ("countryCode", "countryId")]
        return xmlconv:isInVocabulary($seq, "CountryCodeValue")
    let $LCP_1_2 := xmlconv:RowBuilder("EPRTR-LCP 1.2","CountryCode consistency", $res )

    (:
        C1.3 – EPRTRPollutant consistency
    :)
    let $res :=
        let $seq := $docRoot//ProductionFacilityReport/*[local-name() = ("offsitePoluantTransfer", "pollutantRelease")]//pollutant
        return xmlconv:isInVocabulary($seq, "EPRTRPollutantCodeValue")
    let $LCP_1_3 := xmlconv:RowBuilder("EPRTR-LCP 1.3","EPRTRPollutantCodeValue consistency", $res )

    (:
        C1.4 – fuelInput consistency
    :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport//fuelInput/fuelInput
        return xmlconv:isInVocabulary($seq, "FuelInputValue")
    let $LCP_1_4 := xmlconv:RowBuilder("EPRTR-LCP 1.4","FuelInputValue consistency", $res )

    (:
        C1.5 – LCPPollutant consistency
    :)
    let $res :=
        let $seq := $docRoot//ProductionInstallationPartReport/emissionsToAir/pollutant
        return xmlconv:isInVocabulary($seq, "LCPPollutantCodeValue")
    let $LCP_1_5 := xmlconv:RowBuilder("EPRTR-LCP 1.5","LCPPollutantCodeValue consistency", $res )

    (:
        C1.6 – mediumCode consistency
    :)
    let $res :=
        let $seq := $docRoot//pollutantRelease/mediumCode
        return xmlconv:isInVocabulary($seq, "MediumCodeValue")
    let $LCP_1_6 := xmlconv:RowBuilder("EPRTR-LCP 1.6","MediumCodeValue consistency", $res )

    (:
        C1.7 - methodClassification consistency
    :)
    let $res :=
        let $seq := $docRoot//methodClassification
        return xmlconv:isInVocabulary($seq, "MethodClassificationValue")
    let $LCP_1_7 := xmlconv:RowBuilder("EPRTR-LCP 1.7","MethodClassificationValue consistency", $res )

    (:
        C1.8 - methodCode consistency
    :)
    let $res :=
        let $seq := $docRoot//methodCode
        return xmlconv:isInVocabulary($seq, "MethodCodeValue")
    let $LCP_1_8 := xmlconv:RowBuilder("EPRTR-LCP 1.8","MethodCodeValue consistency", $res )

    (: RETURN ALL ROWS IN A TABLE :)
    return
        (
            $LCP_1_1,
            $LCP_1_2,
            $LCP_1_3,
            $LCP_1_4,
            $LCP_1_5,
            $LCP_1_6,
            $LCP_1_7,
            $LCP_1_8
        )

};

declare function eworx:testDocumentBasicTypes( $source_url as xs:string ){

    let $res := for $attr in doc($source_url)//Plant/descendant::*
    where  eworx:testBasicElementType($attr, $source_url) = "false"
    return <tr>
        <td class='error' title="Details"> Invalid input value on the field <b> { name($attr) } </b></td>
        <td title="PlantId">{ data   (($attr)/ancestor::*/PlantId ) }</td>
        <td class="tderror" title="Invalid value">{ data ( $attr ) }</td>
        <td title="xml path">{ functx:path-to-node (($attr) ) }</td>

    </tr>

    return
        if (exists($res )) then
            xmlconv:RowBuilder("LCP XML", "XML Document Validity Errors. QAs did not run", $res)
        else ()


} ;

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
