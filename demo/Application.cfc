<!--- Example Application.cfc --->
<cfcomponent>
    <cffunction name="onApplicationStart">
        <cfset application.exceptional = createobject("component", "exceptional").init(API_KEY)>
    </cffunction>
    <cffunction name="onError">
        <cfargument name="exception">
        <cfset application.exceptional.send(arguments.exception)>
    </cffunction>
</cfcomponent>
