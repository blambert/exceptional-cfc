<cfcomponent output="false">
	<!---
	ColdFusion component for Exceptional API
	http://github.com/blambert/exceptional-cfc
	--->

	<!--- secured and unsecured notifier endpoints --->
	<cfset variables.endpoint = {
		default = "http://api.getexceptional.com/api/errors",
		secure  = "https://api.getexceptional.com/api/errors"
	}>

	<!--- default instance variables --->
	<cfset variables.instance = {
		api_key     = "",
		protocol_version = 6,
		environment = "production",
		use_ssl     = FALSE
	}>
	
	<cffunction name="init" access="public" returntype="any" output="no" hint="Initialise the instance with the appropriate API key">
		<cfargument name="api_key" type="string" required="yes" hint="The API key for the account to submit errors to">
		<cfargument name="environment" type="string" required="no" default="production" hint="The enviroment name to report to">
		<cfargument name="use_ssl" type="boolean" required="no" default="FALSE" hint="Should we use SSL when submitting?">
		<cfset setApiKey(arguments.api_key)>
		<cfset setEnvironment(arguments.environment)>
		<cfset setUseSSL(arguments.use_ssl)>
		<cfreturn this>
	</cffunction>

	<cffunction name="setApiKey" access="public" returntype="void" output="no" hint="Set the project API key to use when POSTing data">
		<cfargument name="api_key" type="string" required="yes" hint="The API key">
		<cfset variables.instance.api_key = arguments.api_key>
	</cffunction>
	<cffunction name="getApiKey" access="public" returntype="string" output="no" hint="The configured project API key">
		<cfreturn variables.instance.api_key>
	</cffunction>

	<cffunction name="setEnvironment" access="public" returntype="void" output="no" hint="Set the name of the environment we're running in">
		<cfargument name="environment" type="string" required="yes" hint="The environment name">
		<cfset variables.instance.environment = arguments.environment>
	</cffunction>
	<cffunction name="getEnvironment" access="public" returntype="string" output="no" hint="The name of the configured environment">
		<cfreturn variables.instance.environment>
	</cffunction>

	<cffunction name="setUseSSL" access="public" returntype="void" output="no" hint="Should we use SSL encryption when POSTing?">
		<cfargument name="use_ssl" type="boolean" required="yes" hint="">
		<cfset variables.instance.use_ssl = arguments.use_ssl>
	</cffunction>
	<cffunction name="getUseSSL" access="public" returntype="boolean" output="no" hint="The SSL encryption status">
		<cfreturn variables.instance.use_ssl>
	</cffunction>
	<cffunction name="getEndpointURL" access="public" returntype="string" output="no" hint="Get the endpoint URL to POST to">
		<cfreturn iif(getUseSSL(), "variables.endpoint.secure", "variables.endpoint.default")>
	</cffunction>

	<cffunction name="send" access="public" returntype="struct" output="no" hint="Send an error notification">
		<cfargument name="error" type="any" required="yes" hint="The error structure to notify about">
		<cfargument name="session" type="struct" required="no" hint="Any additional session variables to report">
		<cfargument name="params" type="struct" required="no" hint="Any additional request params to report">
		<cfset var local = StructNew()>
		<cfset var jsonOut = "">
		
		<!--- we want to be dealing with a plain old structure here --->
		<cfif NOT isstruct(arguments.error)><cfset arguments.error = errorToStruct(arguments.error)></cfif>
		<!--- make sure we're looking at the error root --->
		<cfif structkeyexists(error, "RootCause")><cfset arguments.error = error["RootCause"]></cfif>
		
		<!--- default any messages we don't actually have but should do --->
		<cfif NOT structkeyexists(arguments.error, "type")><cfset arguments.error.type = "Unknown"></cfif>
		<cfif NOT structkeyexists(arguments.error, "message")><cfset arguments.error.message = ""></cfif>
		
		<!--- LOCAL should contain exception, application_environment, request, client --->
		<cfset StructInsert(local, "exception", StructNew(), 1)>
		<cfset StructInsert(local, "application_environment", StructNew(), 1)>
		<cfset StructInsert(local, "request", StructNew(), 1)>
		<cfset StructInsert(local, "client", StructNew(), 1)>

		<!--- create the backtrace --->
		<cfif structkeyexists(arguments.error, "stacktrace") AND isarray(arguments.error["stacktrace"])>
			<cfset StructInsert(local["exception"], "backtrace", build_backtrace(arguments.error["stacktrace"]))>
		<cfelseif structkeyexists(arguments.error, "stacktrace") AND NOT isarray(arguments.error["stacktrace"])>
			<cfset StructInsert(local["exception"], "backtrace", build_backtrace(ListToArray(arguments.error["stacktrace"]), Chr(10)))>
		<cfelse>
			<cfset StructInsert(local["exception"], "backtrace", "")>
		</cfif>
		
		<cfset StructInsert(local["application_environment"], "application_root_directory", expandpath("."))>
		<cfset StructInsert(local["application_environment"], "env", ArrayNew(1))>
		<cfset StructInsert(local["application_environment"], "framework", "cfml")>
		
		<cfset StructInsert(local["exception"], "occured_at", "#DateFormat(DateConvert("Local2UTC", Now()), "yyyy-mm-dd")#T#TimeFormat(DateConvert("Local2UTC", Now()), "HH:MM:SS")#+0")>
		<cfset StructInsert(local["exception"], "message", "#arguments.error.type#: #arguments.error.message#")>
		<cfset StructInsert(local["exception"], "exception_class", arguments.error.type)>
		
		<cfif Len(cgi.query_string)>
			<cfset StructInsert(local["request"], "url", getPageContext().getRequest().getRequestUrl() & "?" & cgi.query_string)>
		<cfelse>
			<cfset StructInsert(local["request"], "url", getPageContext().getRequest().getRequestUrl())>
		</cfif>
		<cfset StructInsert(local["request"], "request_method", GetHttpRequestData().method)>
		<cfset StructInsert(local["request"], "headers", GetHttpRequestData().headers)>
		<cfset StructInsert(local["request"], "action", ListLast(cgi.script_name, "/"))>
		<cfset StructInsert(local["request"], "remote_ip", cgi.remote_addr)>
		
		<cfif structkeyexists(arguments, "session")>
			<cfset StructInsert(local["request"], "session", arguments.session)>
		</cfif>
		
		<cfif StructCount(form)>
			<cfset StructInsert(local["request"], "parameters", form)>
		</cfif>
		
		<cfset StructInsert(local["client"], "name", "getexceptional-cfml-cfc")>
		<cfset StructInsert(local["client"], "version", "1.0")>
		<cfset StructInsert(local["client"], "protocol_version", variables.instance.protocol_version)>

		<cfset jsonOut=gzip(SerializeJSON(local))>
	
		<!--- send the error to Exceptional --->
		<cfhttp method="post" url="#getEndpointURL()#?api_key=#variables.instance.api_key#&protocol_version=#variables.instance.protocol_version#" timeout="0" result="local.http">
			<cfhttpparam type="HEADER" name="Content-Encoding" value="gzip">
			<cfhttpparam type="HEADER" name="Content-Length" value="#Len(jsonOut)#">
			<cfhttpparam type="header" name="Content-Type" value="text/json">
			<cfhttpparam type="header" name="User-Agent" value="#local.client.name# #local.client.version#">
			<cfhttpparam type="body" value="#jsonOut#">
		</cfhttp>
		
		<cfreturn local.http>
	</cffunction>

	<cffunction name="build_backtrace" access="private" returntype="array" output="no" hint="Cleans up the context array and pulls out the information required for the backtrace">
		<cfargument name="context" type="array" required="yes" hint="The context element of the error structure">
		<cfset var lines = []>
		<cfloop array="#arguments.context#" index="item">
			<cfset ArrayAppend(lines, item)>
		</cfloop>
		<cfreturn lines>
	</cffunction>

	<cffunction name="errorToStruct" access="private" returntype="struct" output="no" hint="Converts a CFCATCH to a proper structure (or just shallow-copies if it's already a structure)">
		<cfargument name="catch" type="any" required="yes" hint="The CFCATCH to convert">
		<cfset var error = {}>
		<cfset var key = "">
		<cfloop collection="#arguments.catch#" item="key">
			<cfset error[key] = arguments.catch[key]>
		</cfloop>
		<cfreturn error>
	</cffunction>
	
	<!---
	Compresses a string using the gzip algorithm; returns binary or a string of (base64|hex|uu).
	
	@param text      String to compress. (Required)
	@param format      binary,base64,hex, or uu. Defaults to binary. (Optional)
	@return Returns a string. 
	@author Oblio Leitch (oleitch@locustcreek.com) 
	@version 1, November 14, 2007 
	--->
	<cffunction name="gzip"
    returntype="any"
    displayname="gzip"
    hint="compresses a string using the gzip algorithm; returns binary or string(base64|hex|uu)"
    output="no">
    <!---
        Acknowledgements:
        Andrew Scott, original gzip compression routine
         - http://www.andyscott.id.au/index.cfm/2006/9/12/Proof-of-Concept
    --->
    <cfscript>
        var result="";
        var text=createObject("java","java.lang.String").init(arguments[1]);
        var dataStream=createObject("java","java.io.ByteArrayOutputStream").init();
        var compressDataStream=createObject("java","java.util.zip.GZIPOutputStream").init(dataStream);
        compressDataStream.write(text.getBytes());
        compressDataStream.finish();
        compressDataStream.close();

        if(arrayLen(arguments) gt 1){
            result=binaryEncode(dataStream.toByteArray(),arguments[2]);
        }else{
            result=dataStream.toByteArray();
        }
        return result;
    </cfscript>
	</cffunction>
	
</cfcomponent>