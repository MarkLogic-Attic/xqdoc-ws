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
 : This main module will be invoked by the trigger when the database associated
 : with the xqDoc XML ('xqDoc') has been brought online.  The logic contained 
 : in this module will retrieve the xqDoc XML associated with the MarkLogic XDMP built-ins
 : from the xqDoc web service and store the xqDoc XML into the database for the 
 : xqDoc XML ('xqDoc'). The trigger assumes that this main module will reside
 : in the 'Modules' database. In addition, the supporting library modules 
 : (ml-xqdoc-ws-lib.xqy and ml-ws-lib.xqy) will also need to reside in the 'Modules' database.
 : This main module currently expects the generated xqDoc XML to be stored in the
 : 'xqDoc' database.  This means that a database for 'xqDoc' must be created.  
 : <p/>
 : The following code will create the trigger associated with the 'online' 
 : event.  (it is extracted from the install.xqy)
 : <p/>
 : Trigger for 'online' event
 : <p/>
 : <pre>
 : define variable $ADMIN-USER  { xdmp:get-current-user() }
 : <br/>
 : define variable $MODULES-DB  { "Modules" }
 : <br/>
 : define variable $TRIGGERS-DB { "Triggers" }
 : <br/>
 : xdmp:eval-in(
 : <br/>
 :      concat('import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
 : <br/>
 :              trgr:create-trigger("get-xqdoc-xdmp-xml", 
 : <br/>
 :                                  "get the xqdoc xml for the MarkLogic XDMP built-ins", 
 : <br/>
 :                                  trgr:trigger-database-online-event("', $ADMIN-USER, '"),                           
 : <br/>
 :                                  trgr:trigger-module( 
 : <br/>
 :                                    xdmp:database("', $MODULES-DB, '"), 
 : <br/>
 :                                    "/", 
 : <br/>
 :                                    "/ml-xqdoc-xdmp-xml.xqy"), 
 : <br/>
 :                                  true(), 
 : <br/>
 :                                  ())'),
 : <br/>
 :              xdmp:database($TRIGGERS-DB))
 : </pre>
 : <p/>
 :  @author Darin McBeath
 :  @since October 18, 2005
 :  @version 1.0
 :)


import module "ml-xqdoc-ws-lib" at "/ml-xqdoc-ws-lib.xqy"

declare namespace xqws="ml-xqdoc-ws-lib"

declare namespace xqdoc="http://www.xqdoc.org/1.0"

declare namespace mine="http://xqdoc.org/mine"

(:~ The database to use when storing the xqDoc XML :)
define variable $xqdocDb as xs:string { "xqDoc" }

(: 
 : Check to see if the xqDoc XML for the MarkLogic XDMP built-ins  has already
 : been stored in the xqDoc XML database ("xqDoc").  If it already
 : exists, then there is no reason to call the xqDoc web service.
 :)
 if (xdmp:eval-in(concat("if (exists(doc('", $xqws:ML-XDMP-URI, "'))) then true() else false()"),
                  xdmp:database($xqdocDb))) then
   ()
 else

(: 
 : Get the XML from the xqDoc Web Service for the MarkLogic XDMP
 : built-ins.  If a different version of the XDMP built-ins is desired,
 : then change the URI below to the appropriate value. 
 :)
let $xqdocXdmpXml := xqws:get-xqdoc-module-xml((), 
                                               $xqws:ML-XDMP-3.0-URI,())

(: 
 : Since the xqDoc XML can contain embedded "'", these need to be escaped since
 : they will cause xdmp:eval problems
 :)
let $quotedXdmpXml := xdmp:quote($xqdocXdmpXml)

let $fixedXdmpXml := replace($quotedXdmpXml, "'", "&apos;")


(: Construct the query for inserting the xqDoc XML into the xqDoc database :)
let $xdmpQuery := concat("declare namespace mine='http://xqdoc.org/mine' ", 
                         "define variable $mine:xdmpXml as xs:string external ",
                         "xdmp:document-insert('",
                         $xqws:ML-XDMP-URI,
		             "',",
                         "xdmp:unquote(", 
                         "$mine:xdmpXml",
                         "),(),",
                         "'xqdoc'",
		             ")")


return 

(: Insert the xqDoc XML into the xqDoc database :)
xdmp:eval-in($xdmpQuery, 
             xdmp:database($xqdocDb),
			 (xs:QName("mine:xdmpXml"), $fixedXdmpXml))

