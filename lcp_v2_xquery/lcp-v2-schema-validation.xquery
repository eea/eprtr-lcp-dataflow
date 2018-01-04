xquery version "1.0" encoding "UTF-8";

(:~ 
 : LCP schema validation
 : This module is used to validate reported data with the LCP schema.
 : Refers to obligation: http://rod.eionet.europa.eu/obligations/9
 : @author George Sofianos
 :)

declare namespace xmlconv="http://converters.eionet.europa.eu";

declare variable $xmlconv:xmlValidatorUrl as xs:string := 'http://converters.eionet.europa.eu/api/runQAScript?script_id=-1&amp;url=';
declare variable $ignoredMessages := ();
declare variable $source_url as xs:string external;

declare function xmlconv:validateXmlSchema($source_url)
{
    let $successfulResult := 
      <div class="feedbacktext">
        <span id="feedbackStatus" class="INFO" style="display:none">XML Schema validation passed without errors.</span>
        <span style="display:none"><p>OK</p></span>
        <h2>XML Schema validation</h2>
        <p><span style="background-color: green; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;text-align:center">OK</span>XML Schema validation passed without errors.</p>
         <p>The file was validated against <a href="http://dd.eionet.europa.eu/schemas/LCP-article_72_IED/LCP-IED.xsd">http://dd.eionet.europa.eu/schemas/LCP-article_72_IED/LCP-IED.xsd</a></p>
       </div>

    let $fullUrl := concat($xmlconv:xmlValidatorUrl, fn:encode-for-uri($source_url))
    let $validationResult := doc($fullUrl)

    let $hasErrors := count($validationResult//*[local-name() = "tr"]) > 1

    let $filteredResult :=
        if ($hasErrors) then
            <div class="feedbacktext">
                {
                for $elem in $validationResult/child::div/child::*
                return
                    if ($elem/local-name() = "table") then
                        <table class="datatable" border="1">
                            {
                            for $tr in $elem//tr
                            return
                                if (not(empty(index-of($ignoredMessages, normalize-space($tr/td[3]/text()))))) then
                                    ()
                                else
                                    $tr
                            }
                         </table>
                    else
                        $elem
                }
            </div>
        else
            $validationResult

    let $hasErrorsAfterFiltering := count($filteredResult//*[local-name()="tr"]) > 1

    return
        if ($hasErrors and not($hasErrorsAfterFiltering)) then
            $successfulResult
        else
            $filteredResult

};

(:~ 
 : Main Function
 :)
declare function xmlconv:proceed($source_url as xs:string) {
    xmlconv:validateXmlSchema($source_url)
};

xmlconv:proceed($source_url)