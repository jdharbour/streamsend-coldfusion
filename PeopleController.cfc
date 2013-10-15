<!---
	TODO: check the statuscode being returned to tell if there is an error in the response or not.
--->

<cfcomponent hint="utilities for managing people or subscribers to SendMail" output="true">

	<cffunction name="init" access="public" output="false" returntype="PeopleController">
		<cfscript>
			this.myComp = new Company().init();
			setAudienceID(this.myComp.getAudienceID());
		</cfscript>
		
		<cfreturn this>
	</cffunction>
	
	
	<cffunction name="getAudienceID" access="public" output="false" returntype="numeric">
		<cfreturn this.audienceID />
	</cffunction>


	<cffunction name="setAudienceID" access="public" output="false" returntype="void">
		<cfargument name="audienceID" type="numeric" required="true" />
		<cfset this.audienceID = arguments.audienceID />
		<cfreturn />
	</cffunction>


	<!--- addPerson must be sent in a struct with a key of email-address --->
	<cffunction name="addPerson" access="public" output="false" returntype="any">
		<cfargument name="person" type="struct" required="true">
		<cfset var myResults = "">
		
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people.xml"
			port="80"
			method="POST"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">
		
			<!--- specify the XML to be included, if any---> 
			<cfhttpparam type="XML" value="#structToPersonXml(arguments.person)#" />		
		</cfhttp>
		
		<cfreturn />
	</cffunction>
	
	
	<cffunction name="update" access="public" output="false" returntype="any">
		<cfargument name="person" type="struct" required="true">
		<cfargument name="personID" type="numeric" required="false" default="0">
		<cfset var myResults = "">
		<!--- check if personID was given if not look it up 
			if there is none found for that email then return an error
			can only look up based on email so if email isn't in it then we can't ... hmmm
		--->
		<cfif arguments.personID EQ 0>
			<cfif structKeyExists(arguments.person, "email")>
				<!--- find the id based on the email --->
				<cfset arguments.personID = getPersonID(arguments.person.email)>
				<cfif isStruct(arguments.personID)>
					<!--- if this is a structure then there was a problem --->
					<cfreturn arguments.personID>
				</cfif>
			<cfelse>
				<!--- return an error that the email was not included or not found among the subscribers --->
				<cfset myResults = {
					"error" = "Either the email for the person was not passed in or the email was not found among the subscribers."
				}>
				<cfreturn myResults>
			</cfif>	
		</cfif>
		
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people/#arguments.personID#.xml"
			port="80"
			method="PUT"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">
			
			<cfhttpparam type="XML" value="#structToPersonXml(arguments.person)#" />			
		</cfhttp>
		
		<cfreturn myResults/>
	</cffunction>
	
	
	
	<cffunction name="getPersonID" access="public" output="false" returntype="any">
		<cfargument name="email" type="string" required="true">
		<cfset var myResults = "">
		<cfset var xmlResults = "">
		
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people.xml?email_address=#arguments.email#"
			port="80"
			method="GET"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">					
		</cfhttp>
		
		
		<cfset xmlResults = xmlParse(myResults.fileContent)>
		<cftry>
			<cfset myResults = xmlResults.people.person.id.xmlText>
			<cfcatch type="any">
				<cfset myResults = {
					"error" = "The email was not found among the subscribers."
				}>
				<cfreturn myResults>
			</cfcatch>
		</cftry>
		
		<cfreturn myResults/>
	</cffunction>
	
	
	<!--- get all the info for a person by id or email--->
	<cffunction name="getPerson" access="public" output="false" returntype="any">
		<cfargument name="personKey" type="any" required="false" default="0" 
			hint="personKey can either be the personID or email address">
		<cfset var myResults = "">
		<cfset var xmlResults = "">
		<cfset var personID = 0>		
		
		<cfif arguments.personKey EQ 0>
			<cfset myResults = {
				"error" = "Either the personID or email must be passed in to use this function."
			}>
			<cfreturn myResults>
		</cfif>		
		
		<cfif NOT isNumeric(arguments.personKey)>
			<!--- find the id based on the email --->
			<cfset personID = getPersonID(arguments.personKey)>
			<cfif isStruct(personID)>				
				<cfreturn myResults>
			</cfif>
		<cfelse>
			<cfset personID = arguments.personKey>
		</cfif>
		
		<!--- arguments.personID should have a valid id in it if it got this far so use that to get the info --->
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people/#personID#.xml"
			port="80"
			method="GET"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">					
		</cfhttp>
		
		<cfset myResults = xmlParse(myResults.fileContent)>
		
		<cfreturn myResults/>
	</cffunction>
	
	
	<cffunction name="isSubscribed" access="public" output="false" returntype="boolean" hint="a false can be unusbscribed or not found in the subscribers at all">
		<cfargument name="personKey" type="any" required="false" default="0" 
			hint="personKey can either be the personID or email address">
		<cfset var xmlResults = "">	
		<cfset var isSubscriber = false>		
		
		<cfset xmlResults = getPerson(arguments.personKey)>
		
		<cftry>
			<cfif xmlResults.person["opt-status"].xmlText EQ "active">
				<cfreturn true>
			</cfif>
			
			<cfcatch type="any"><!--- do nothing and false will be returned ---></cfcatch>
		</cftry>		
		
		<cfreturn isSubscriber/>
	</cffunction>
	
	
	<cffunction name="unsubscribe" access="public" output="false" returntype="any">
		<cfargument name="personKey" type="any" required="false" default="0" 
			hint="personKey can either be the personID or email address">
		<cfset var myResults = "">
		<cfset var xmlResults = "">
		<cfset var personID = 0>		
		
		<cfif arguments.personKey EQ 0>
			<cfset myResults = {
				"error" = "Either the personID or email must be passed in to use this function."
			}>
			<cfreturn myResults>
		</cfif>		
		
		<cfif NOT isNumeric(arguments.personKey)>
			<!--- find the id based on the email --->
			<cfset personID = getPersonID(arguments.personKey)>
			<cfif isStruct(personID)>				
				<cfreturn myResults>
			</cfif>
		<cfelse>
			<cfset personID = arguments.personKey>
		</cfif>
		
		<!--- arguments.personID should have a valid id in it if it got this far so use that to get the info --->
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people/#personID#/unsubscribe.xml"
			port="80"
			method="POST"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">
			
			<cfhttpparam type="XML" value="" />			
		</cfhttp>
		
		<cfset myResults = myResults.statusCode>
		
		<cfreturn myResults/>
	</cffunction>
	
	
	
	<cffunction name="getUnsubscribes" access="public" output="false" returntype="any">
		<cfargument name="emailBlastID" type="any" required="false" default="0" 
			hint="personKey can either be the personID or email address">
		<cfset var myResults = "">
		<cfset var xmlResults = "">
		<cfset var personID = 0>		
		
		<cfif arguments.personKey EQ 0>
			<cfset myResults = {
				"error" = "Either the personID or email must be passed in to use this function."
			}>
			<cfreturn myResults>
		</cfif>		
		
		<cfif NOT isNumeric(arguments.personKey)>
			<!--- find the id based on the email --->
			<cfset personID = getPersonID(arguments.personKey)>
			<cfif isStruct(personID)>				
				<cfreturn myResults>
			</cfif>
		<cfelse>
			<cfset personID = arguments.personKey>
		</cfif>
		
		<!--- arguments.personID should have a valid id in it if it got this far so use that to get the info --->
		<cfhttp
			url="#this.myComp.getAPIRoot()#/audiences/#this.myComp.getAudienceID()#/people/#personID#/unsubscribe.xml"
			port="80"
			method="POST"
			username="#this.myComp.getUsername()#"
			password="#this.myComp.getPassword()#"
			result="myResults">
			
			<cfhttpparam type="XML" value="" />			
		</cfhttp>
		
		<cfset myResults = myResults.statusCode>
		
		<cfreturn myResults/>
	</cffunction>
	
	
		
	
	
	<cffunction name="structToPersonXml" access="public" returntype="xml">
		<cfargument name="myStruct" required="true" type="struct">
		<cfset var structKeyArr = structKeyArray(arguments.myStruct)>
		<cfset var i = 1>
		<cfset var myXml = xmlNew()>
		<cfset myXml.xmlRoot = xmlElemNew(myXml, "person")>
		
		<!--- we have the array of keys now we just need to turn those into an xml object --->
		<cfloop from="1" to="#arrayLen(structKeyArr)#" index="i">
			<cfset myXml.person.xmlChildren[i] = xmlElemNew(myXml, lCase(structKeyArr[i]))>
			<cfset myXml.person.xmlChildren[i].xmlText =  xmlFormat(myStruct[structKeyArr[i]], true)>
		</cfloop>
	
		<cfreturn myXml>
	</cffunction>
</cfcomponent>