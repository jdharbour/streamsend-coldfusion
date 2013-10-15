<cfcomponent hint="utilities for managing people or subscribers to SendMail" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="Company">
		<cfscript>
			//variables put in the variables scope to try keep them static.
			variables.username = ""; // StreamSend API username
			variables.password = ""; // API password
			variables.apiRoot = "https://app.streamsend.com"; // API root address
			variables.audienceID = 1; // API only allows one audienceID currently
		</cfscript>
		
		<cfreturn this>
	</cffunction>
	
	
	<cffunction name="getUsername" access="package" output="false" returntype="String">
		<cfreturn variables.username>
	</cffunction>
	
	
	<cffunction name="getPassword" access="package" output="false" returntype="String">
		<cfreturn variables.password>
	</cffunction>
	
	
	<cffunction name="getAPIRoot" access="package" output="false" returntype="String">
		<cfreturn variables.apiRoot>
	</cffunction>
	
	
	<cffunction name="getaudienceID" access="package" output="false" returntype="numeric">
		<cfreturn variables.audienceID>
	</cffunction>	

	
</cfcomponent>