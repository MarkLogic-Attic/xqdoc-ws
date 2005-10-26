(:
 : Copyright (c)2005 Elsevier, Inc.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :)

(:~
 : This main module will be invoked by the trigger when a module has been
 : 'created' or 'updated' into the 'Modules' database.  The triggers assume
 : that this main module  will reside in the 'Modules' database. In addition,
 : the supporting library modules (ml-xqdoc-ws-lib.xqy and ml-ws-lib.xqy) will
 : also need to reside in the 'Modules' database.  This main module currently expects the
 : generated xqDoc XML to be stored in the 'xqDoc' database.  This means that a database
 : for 'xqDoc' must be created.  
 : <p/>
 : The following code will create the triggers associated with the 'created' and
 : 'modify' events (they are extracted from the install.xqy)
 : <p/>
 : Trigger for 'created' content
 : <p/>
 : <pre>
 : define variable $MODULES-DB  { "Modules" }
 : <br/>
 : define variable $TRIGGERS-DB { "Triggers" }
 : <br/>
 : xdmp:eval-in(
 : <br/>
 :      concat('import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
 : <br/>
 :              trgr:create-trigger("generate-xqdoc-create", 
 : <br/>
 :                                  "generate xqdoc xml for the module when created", 
 : <br/>
 :                                  trgr:trigger-data-event( 
 : <br/>
 :                                       trgr:directory-scope("/", "infinity"),                                               
 : <br/>
 :                                       trgr:document-content("create")), 
 : <br/>
 :                                  trgr:trigger-module( 
 : <br/>
 :                                       xdmp:database("', $MODULES-DB, '"), 
 : <br/>
 :                                       "/", 
 : <br/>
 :                                       "/ml-xqdoc-generate-xml.xqy"), 
 : <br/>
 :                                  true(), 
 : <br/>
 :                                  ())'),
 : <br/>
 :               xdmp:database($TRIGGERS-DB))
 : </pre>
 : <p/>
 : Trigger for 'modified' content
 : <p/>
 : <pre>
 : define variable $MODULES-DB  { "Modules" }
 : <br/>
 : define variable $TRIGGERS-DB { "Triggers" }
 : <br/>
 : xdmp:eval-in(
 : <br/>
 :      concat('import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
 : <br/>
 :              trgr:create-trigger("generate-xqdoc-update", 
 : <br/>
 :                                  "generate xqdoc xml for the module when updated", 
 : <br/>
 :                                  trgr:trigger-data-event( 
 : <br/>
 :                                      trgr:directory-scope("/","infinity"),                                                
 : <br/>
 :                                      trgr:document-content("modify")), 
 : <br/>
 :                                  trgr:trigger-module( 
 : <br/>
 :                                      xdmp:database("', $MODULES-DB, '"), 
 : <br/>
 :                                      "/", 
 : <br/>
 :                                      "/ml-xqdoc-generate-xml.xqy"), 
 : <br/>
 :                                  true(), 
 : <br/>
 :                                  ())'),
 : <br/>
 :               xdmp:database($TRIGGERS-DB)) 
 : </pre>
 :  @author Darin McBeath
 :  @since October 18, 2005
 :  @version 1.0
 :)


import module "ml-xqdoc-ws-lib" at "/ml-xqdoc-ws-lib.xqy"

declare namespace xqws="ml-xqdoc-ws-lib"

declare namespace xqdoc="http://www.xqdoc.org/1.0"

declare namespace trgr="http://marklogic.com/xdmp/triggers"

declare namespace mine="http://xqdoc.org/mine"

(:~ The URI for the XQuery module to be processed ... passed by the Trigger :)
define variable $trgr:uri as xs:string external

(:~ The database to use when storing the xqDoc XML :)

define variable $xqdocDb as xs:string { "xqDoc" }

(: Get the XML from the xqDoc Web Service:)

let $xqdocXml  := xqws:get-xqdoc-xquery-xml((),
                                            (),
                                            (),
                                            (),
                                            (),
			  			        xdmp:quote(doc($trgr:uri)),
                                            $trgr:uri)

(: 
 : Since the xqDoc XML can contain embedded "'", these need to be escaped since
 : they will cause xdmp:eval problems
 :)
let $quotedXml := xdmp:quote($xqdocXml)

let $fixed1Xml := replace($quotedXml, "'", "&apos;")

(: 
 : Currently, xqDoc has a limitation whereby it expects the URI contained
 : in the xqDoc XML to be the same as the URI used to store the xqDoc XML (for library modules).
 : This will be addressed in a future release of xqDoc (later this year), but
 : for now, we will ensure they are the same with the following code.  
 :)
let $theUri := if ($xqdocXml//*:module[@type="library"]) then
                 xs:string($xqdocXml//*:module/*:uri)
               else
                 $trgr:uri

(: Construct the query for inserting the xqDoc XML into the xqDoc database :)
let $query := concat("declare namespace mine='http://xqdoc.org/mine' ", 
                     "define variable $mine:xml as xs:string external ",
                     "xdmp:document-insert('",
                     $theUri,
		         "',",
                     "xdmp:unquote(", 
                     "$mine:xml",
                     "),(),",
                     "'xqdoc'",
		         ")")


return 

(: Insert the xqDoc XML into the xqDoc database :)
xdmp:eval-in($query, 
             xdmp:database($xqdocDb), 
			 (xs:QName("mine:xml"), $fixed1Xml)) 

