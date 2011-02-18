<!--- Example Application.cfc

    Don't use an Application.cfc file? The Application.cfm/onerror.cfm
    combonation duplicates the functionality on this file. Use index.cfm
    to generate an exception.

    For this demo to work, remember to place the exceptional CFC
    in the same directory as the Application.cfc/cfm file.
--->

<cfcomponent>
    <cffunction name="onApplicationStart">
        <cfset application.exceptional = createobject("component", "exceptional").init(API_KEY)>
    </cffunction>
    <cffunction name="onError">
        <cfargument name="exception">

        <cfif arguments.exception.type eq "missinginclude">
            <cfcontent reset=true />
            <cfheader statuscode="404" statustext="Not Found">
            <h1>404 Not Found</h1>
        <cfelse>
            <cfheader statuscode="500" statustext="Internal server error">
        </cfif>

        <cfset application.exceptional.send(arguments.exception)>

        <!-- Error --></TD></TD></TD></TH></TH></TH></TR></TR></TR></TABLE></TABLE></TABLE></A></ABBREV></ACRONYM></ADDRESS></APPLET></AU></B></BANNER></BIG></BLINK></BLOCKQUOTE></BQ></CAPTION></CENTER></CITE></CODE></COMMENT></DEL></DFN></DIR></DIV></DL></EM></FIG></FN></FONT></FORM></FRAME></FRAMESET></H1></H2></H3></H4></H5></H6></HEAD></I></INS></KBD></LISTING></MAP></MARQUEE></MENU></MULTICOL></NOBR></NOFRAMES></NOSCRIPT></NOTE></OL></P></PARAM></PERSON></PLAINTEXT></PRE></Q></S></SAMP></SCRIPT></SELECT></SMALL></STRIKE></STRONG></SUB></SUP></TABLE></TD></TEXTAREA></TH></TITLE></TR></TT></U></UL></VAR></WBR></XMP>
        <div style="margin: 10px 10px; border: 1px solid Gray; background: Silver; padding: 6px 12px;">
                <h3 style="margin: 8px 0px;">Please accept our apologies. An error has occured.</h3>
                <div style="color: Gray;"><em><cfoutput>#arguments.exception.type#: #Left(arguments.exception.message, 36)#...</cfoutput></em></div>
                <h4 style="margin: 5px 0px;">Site administrators have been notified of the problem. Please try again later.</h4>
        </div>

    </cffunction>
</cfcomponent>
