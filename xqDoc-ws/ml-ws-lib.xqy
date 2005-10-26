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
 :  This library module provides a function that supports
 :  interactions with a web service (via HTTP and SOAP 1.1).  
 :  There is currently no support for SOAP Attachments.  
 :  However, the current function should support rpc literal,
 :  wrapped document literal, and document literal style
 :  SOAP requests.  The XQuery that uses this module to
 :  invoke a web service will need to construct the XML
 :  payload (message) that is defined for the web service.
 :  This information can be obtained from the web service
 :  WSDL and supporting XML type files.
 :
 :  @author Darin McBeath
 :  @since October 18, 2005
 :  @version 1.0
 :)
module "ml-ws-lib"
 
declare namespace ws="ml-ws-lib"

declare namespace soapenv="http://schemas.xmlsoap.org/soap/envelope/"

default function namespace="http://www.w3.org/2003/05/xpath-functions" 


(:~ 
 :  This function is responsible for constructing the SOAP request for
 :  the specified web service and invoking the web service.  When the response 
 :  is returned from the web service, all of the SOAP  information will
 :  be removed and only the payload information will be returned.  
 :  This will shield the invoking function from any knowledge that SOAP 
 :  was used to interact with the web service.  In addition, SOAP faults
 :  will be converted to 'errors' when they are returned.
 :
 :  @param $endpoint The address (endpoint) for the web service.
 :  @param $operation The operation to invoke on the web service.
 :  @param $payload The message (payload) for the web service.
 :  @param $options HTTP options that should be added to the request.  Options for
 :                  authorization, headers, and timeout will be honored.  Options
 :                  for data will be ignored.
 :
 :  @return The XML response from the web service.
 :
 :  @error SOAP fault encountered
 :)
define function ws:invoke-web-service($endpoint as xs:string, 
                                      $operation as xs:string,
                                      $payload as element(),
                                      $options as element()?)
                                      as element()?
{

  let $soap-envelope := <soapenv:Envelope>
                        <soapenv:Body>
						{ $payload }
						</soapenv:Body>
                        </soapenv:Envelope>

  let $soap-response := xdmp:http-post($endpoint,
                                       ws:build-options($operation,
                                                        $soap-envelope,
                                                        $options))

  return

    (: Make sure there was a response payload :)

	if (not(exists($soap-response[2]))) then
      error("No response returned from the service.")
	else 

    (: Step over the SOAP information and get the response payload :)

	let $response := $soap-response[2]
	return
	  if (exists($response//soapenv:Fault)) then
	    error($response//soapenv:Fault/faultstring)
	  else
	    $response//soapenv:Body/* 
}


(:~ 
 :  This function is responsible for construction the MarkLogic options
 :  element that will be used to provide xdmp:http-post with additional
 :  parameters.  This includes the ability to specify HTTP headers, HTTP
 :  basic authorization (username/password), and HTTP timeout value.  In
 :  addition, the method to be invoked on the web service (the operation)
 :  will be added as a SOAP Action HTTP header and the SOAP envelope 
 :  will be added as the HTTP Post body.
 :
 :  @param $operation The operation to invoke on the web service.
 :  @param $soap-envelope The envelope (soap message) for the web service.
 :  @param $options HTTP options that should be added to the request.  Options for
 :                  authentication, headers, and timeout will be honored.  Options
 :                  for data will be ignored.  The options must be in the format
 :                  specified by MarkLogic when performing an xdmp:http-post.
 :
 :  @return The options element for the xdmp:http-post.
 :
 :)
define function ws:build-options($operation as xs:string,
                                 $soap-envelope as element(),
                                 $options as element()?)
                                 as element()
{
if (exists($options)) then

   <options xmlns="xdmp:http">
     <headers>
      <SOAPAction>{$operation}</SOAPAction>
      {
      (: Check for headers :)
      if (exists($options/*:headers)) then
        $options/*:headers/*
      else
        ()
      }
     </headers>
     {
     (: Check for authentication :)
      if (exists($options/*:authentication)) then
        $options/*:authentication
      else
        ()
     }
     {
     (: Check for timeout :)
      if (exists($options/*:timeout)) then
        $options/*:timeout
      else
        ()
     }

     <data>{ xdmp:quote($soap-envelope) }</data>
   </options>

else

   <options xmlns="xdmp:http">
     <headers>
      <SOAPAction>{$operation}</SOAPAction>
     </headers>
     <data>{ xdmp:quote($soap-envelope) }</data>
   </options>

}
