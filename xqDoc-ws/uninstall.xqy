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
 :  This main module performs the uninstallation of the XQuery modules and triggers
 :  that are necessary to access the xqDoc web service.  The uninstallation script
 :  is divided into four distinct sections.  
 :  <p/>
 :  The first section deletes all of the main modules that will be invoked when
 :  a particular 'trigger' is placed on the task manager by MarkLogic.  Three of
 :  these main modules access the xqDoc web service for pre-built xqDoc xml for
 :  MarkLogic XDMP built-ins, MarkLogic CTS built-ins, and the XPath F&O.  These
 :  modules should only be invoked when the database (xqDoc) is brought online.
 :  However, these main modules are smart enough to not access the xqDoc web
 :  service if they have already stored the associated xqDoc xml in the xqDoc database.
 :  The other two modules will be invoked when a module stored in the Modules database
 :  is inserted, changed or deleted.  A brief description of the main modules follows:
 :  <ol>
 :  <li>Retrieve CTS xqDoc XML</li>                                                
 :  <li>Retrieve XDMP xqDoc XML</li>                                               
 :  <li>Retrieve XPath F&O xqDoc XML</li>                                          
 :  <li>Generate xqDoc XML for a new/updated XQuery module</li>                    
 :  <li>Delete xqDoc XML for a deleted XQuery module</li>                          
 :  </ol>
 :  The second section deletes the supporting SOAP library modules that will be used
 :  by the above main modules for accessing the xqDoc web service.  These modules will
 :  also be deleted from the Modules database.  The core web service library module
 :  is a 'general purpose' library module for accessing a web service.  This module
 :  could be used as a starting point for accessing other web services.  The other
 :  module is specific to xqDoc ... it builds up the payloads for the xqDoc web
 :  service and then uses the core library module for actually accessing the web
 :  service. A brief description of the library modules follows:
 :  <ol>
 :  <li>Core web service library module</li>                                      
 :  <li>xqDoc web service specific library module</li> 
 :  </ol> 
 :  The third section removes all of the triggers from the Triggers database.  As mentioned
 :  earlier, there are (3) triggers for when the xqDoc database is brought online and
 :  (3) triggers for when a module changes in the Modules database.  A brief
 :  description of each trigger follows:
 :  <ol>                                                              
 :  <li>Online database -- retrieve CTS xqDoc XML</li>                             
 :  <li>Online database -- retrieve XDMP xqDoc XML</li>                            
 :  <li>Online database -- retrieve XPath F&O xqDoc XML</li>                       
 :  <li>Deleted module -- remove xqDoc XML</li>                                    
 :  <li>Inserted module -- create new xqDoc</li> 
 :  <li>Updated module -- create new xqDoc XML</li>                                
 :  </ol>
 :  The fourth section deletes the xqDoc library and main modules from the Modules
 :  database.  These modules will control the presentation of the xqDoc xml.  A
 :  brief description of each module follows:
 :  <ol>
 :  <li>The default xqDoc entry page</li>                                            
 :  <li>Retrieve a specific module</li>                                            
 :  <li>Retrieve the code</li>                                                     
 :  <li>xqDoc library of supporting functions</li>                                 
 :  </ol>
 :  @author Darin McBeath
 :  @since October 18, 2005
 :  @version 1.0
 :)

(:~ Default root directory for the CQ installation ... normally, this is 'cq' :)
define variable $CQ-ROOT     { "cq" }

(:~ A user with 'admin' privileges.  The assumption made is that the current
 :  user (executing the install script via the CQ tool) will have 'admin'
 :  privileges.  If this is not the case, then specify the username.
 :)
define variable $ADMIN-USER  { xdmp:get-current-user() }

(:~ The default 'modules' database to use for storing the xqDoc presentation
 :  modules and the modules that are the 'targets' for the Triggers.  The
 :  assumption is that the default 'Modules' database that is created as 
 :  part of the MarkLogic installation will be used.  If this is not the case,
 :  then change the value to reflect the correct 'modules' database.
 :)
define variable $MODULES-DB  { "Modules" }

(:~ The default 'triggers' database to use for storing the Triggers.  The assumption
 :  is that the default 'Triggers' database that is created as part of the 
 :  MarkLogic installation will be used.  If this is not the case, then change
 :  the value to reflect the correct 'triggers' database.
 :)
define variable $TRIGGERS-DB { "Triggers" }

(:---------------------------------------------------------------------------:)
(: Delete the main modules (from the $MODULES-DB) that will be invoked       :)
(: as a result of a trigger event.  There are (5) main modules.              :)
(:  1. Retrieve CTS xqDoc XML                                                :)
(:  2. Retrieve XDMP xqDoc XML                                               :)
(:  3. Retrieve XPath F&O xqDoc XML                                          :)
(:  4. Generate xqDoc XML for a new/updated XQuery module                    :)
(:  5. Delete xqDoc XML for a deleted XQuery module                          :)
(:---------------------------------------------------------------------------:)
 
let $triggerModules := (

(: Delete module to retrieve CTS xqDoc XML :)

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-cts-xml.xqy")', 
      xdmp:database($MODULES-DB))
,

(: Delete module to retrieve XDMP xqDoc XML :)

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-xdmp-xml.xqy")', 
      xdmp:database($MODULES-DB))
,

(: Delete module to retrieve XPATH xqDoc XML :)

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-xpath-xml.xqy")', 
      xdmp:database($MODULES-DB))
,

(: Insert module to delete xqDoc XML when the associated XQuery module is deleted :)

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-delete-xml.xqy")', 
      xdmp:database($MODULES-DB))
,

(: Insert module to generate xqDoc XML when the associated XQuery module is changed :) 

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-generate-xml.xqy")', 
      xdmp:database($MODULES-DB))
)

(:---------------------------------------------------------------------------:)
(: Delete the library modules (from the $MODULES-DB) that will be used to    :)
(: to invoke the xqDoc web service.  There are 2 library modules.            :)
(:  1. Core web service library module                                       :)
(:  2. xqDoc web service specific library module                             :)
(:---------------------------------------------------------------------------:)

let $soapModules := (

(: Delete the library module for handling general web service calls :) 

xdmp:eval-in(
      'xdmp:document-delete("/ml-ws-lib.xqy")', 
      xdmp:database($MODULES-DB))
,

(: Delete the library module for handling xqDoc specific web service calls :) 

xdmp:eval-in(
      'xdmp:document-delete("/ml-xqdoc-ws-lib.xqy")', 
      xdmp:database($MODULES-DB))
)
 
(:---------------------------------------------------------------------------:)
(: Delete the triggers (from the $TRIGGERS-DB) that will 'trigger' the       :)
(: the invocation of a main module (contained in $MODULES-DB) to perform     :)
(: the appropriate action as a result of the trigger event. There are (6)    :)
(: triggers.                                                                 :)
(:  1. Online database -- retrieve CTS xqDoc XML                             :)
(:  2. Online database -- retrieve XDMP xqDoc XML                            :)
(:  3. Online database -- retrieve XPath F&O xqDoc XML                       :)
(:  4. Deleted module -- remove xqDoc XML                                    :)
(:  5. Inserted module -- create new xqDoc XML                               :)
(:  6. Updated module -- create new xqDoc XML                                :)
(:---------------------------------------------------------------------------:)

let $deleteTriggers := (

(: Delete the online trigger to load MarkLogic CTS built-ins :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("get-xqdoc-cts-xml")', 
              xdmp:database($TRIGGERS-DB))
,

(: Delete the online trigger to load MarkLogic XDMP built-ins :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("get-xqdoc-xdmp-xml")', 
              xdmp:database($TRIGGERS-DB))
,

(: Delete the online trigger to load XPath F&O for May 2003 :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("get-xqdoc-xpath-xml")', 
              xdmp:database($TRIGGERS-DB))
,

(: Delete the trigger for new module added to the modules database :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("generate-xqdoc-create")', 
              xdmp:database($TRIGGERS-DB))
,

(: Delete the  trigger for existing module modified in the modules database :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("generate-xqdoc-update")', 
              xdmp:database($TRIGGERS-DB))
, 

(: Delete the trigger for removing a module from the modules database :)

xdmp:eval-in(
      'import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy" 
              trgr:remove-trigger("delete-xqdoc-xml")', 
              xdmp:database($TRIGGERS-DB)) 
)

(:---------------------------------------------------------------------------:)
(: Delete the main modules and library modules (from the $MODULES-DB) to     :)
(: support the presentation of xqDoc XML.   There are 4 modules.             :)
(:  1. The default xqDoc entry page                                          :)
(:  2. Retrieve a specific module                                            :)
(:  3. Retrieve the code                                                     :)
(:  4. xqDoc library of supporting functions                                 :)
(:---------------------------------------------------------------------------:)

let $xqDocModules := (

(: Delete the default.xqy main module for xqDoc presentation :) 

xdmp:eval-in(
     'xdmp:document-delete("xqDoc/default.xqy")', 
     xdmp:database($MODULES-DB))
,

(: Delete the get-module.xqy main module for xqDoc presentation :) 

xdmp:eval-in(
     'xdmp:document-delete("xqDoc/get-module.xqy")', 
     xdmp:database($MODULES-DB))
,

(: Delete the get-code.xqy main module for xqDoc presentation :) 

xdmp:eval-in(
     'xdmp:document-delete("xqDoc/get-code.xqy")', 
     xdmp:database($MODULES-DB))
,

(: Delete the xqdoc-display.xqy for xqDoc presentation :) 

xdmp:eval-in(
     'xdmp:document-delete("xqDoc/xqdoc-display.xqy")', 
     xdmp:database($MODULES-DB))
)

return
   (xdmp:set-response-content-type("text/html"),
    xdmp:add-response-header("Pragma", "no-cache"),
    xdmp:add-response-header("Cache-Control", "no-cache"),
    xdmp:add-response-header("Expires", "0"),
    <html>
    <head>
    <title>xqDoc Uninstallation Success</title>
    </head>
    <body>
    The xqDoc web service modules and triggers have been successfuly uninstalled.
    </body>
    </html>)

