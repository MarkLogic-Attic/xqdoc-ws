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
 : 'deleted' from  the 'Modules' database.  The triggers assume that this main module
 : will reside in the 'Modules' database.  This main module currently expects the
 : xqDoc XML to be contained in the 'xqDoc' database.
 : <p/>
 : The following code will create the triggers associated with the 'delete' 
 : event.  (it is extracted from the install.xqy)
 : <p/>
 : Trigger for 'delete' content
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
 :              trgr:create-trigger("delete-xqdoc-xml", 
 : <br/>
 :                                  "delete xqdoc xml for the module when deleted", 
 : <br/>
 :                                  trgr:trigger-data-event( 
 : <br/>
 :                                      trgr:directory-scope("/", "infinity"),                                               
 : <br/>
 :                                      trgr:document-content("delete")), 
 : <br/>
 :                                  trgr:trigger-module( 
 : <br/>
 :                                      xdmp:database("', $MODULES-DB, '"), 
 : <br/>
 :                                      "/", 
 : <br/>
 :                                      "/ml-xqdoc-delete-xml.xqy"), 
 : <br/>
 :                                  true(), 
 : <br/>
 :                                  ())'),
 : <br/>
 :               xdmp:database($TRIGGERS-DB)) 
 : </pre>
 : <p/>
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

(:~ The database to use when deleting the xqDoc XML :)
define variable $xqdocDb as xs:string { "xqDoc" }

(: Check to see if the xqDoc XML associated with the module exists in the xqDoc database :)



let $uriQuery := concat("for $x in /*:xqdoc/*:module[*:name='",
                        $trgr:uri,
				"']/*:uri return xs:string($x)")

let $theUri := xdmp:eval-in($uriQuery, 
                            xdmp:database($xqdocDb))

return

(: If no URI found, then return ... otherwise, delete the xqDoc XML :)
if (empty($theUri)) then
  ()
else

(: Construct the query for deleting the xqDoc XML from the xqDoc database :)
let $deleteQuery := concat("xdmp:document-delete('",
                           $theUri,
		               "')")

return 

(: Delete the xqDoc XML from the xqDoc database :)
xdmp:eval-in($deleteQuery, 
             xdmp:database($xqdocDb))


    