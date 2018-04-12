xquery version "3.0";

(:~
: User: laszlo
: Date: 1/4/18
: Time: 11:37 AM
: To change this template use File | Settings | File Templates.
:)

module namespace functx = "http://www.functx.com";

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

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;

declare function functx:substring-before-last-match
($arg as xs:string?,
        $regex as xs:string) as xs:string? {

    replace($arg, concat('^(.*)', $regex, '.*'), '$1')
};
declare function functx:is-a-number
  ( $value as xs:anyAtomicType? )  as xs:boolean {

   string(number($value)) != 'NaN'
 } ;
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {

   $value = $seq
 } ;
declare function functx:value-intersect
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[.=$arg2])
 } ;
(: HELPER FUNCTIONS END :)