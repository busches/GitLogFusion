﻿<cfparam name="URL.start" default="0" />
<cfparam name="URL.end" default="0" />
<cfset gitCounts = application.git.commitCounts(url.start, url.end) />

<div>
	<table class="table table-bordered">
		<thead>
		<tr>
			<th>Author</th>
			<th>Count</th>
		</tr>
		</thead>
		<tbody>
			<cfloop collection="#gitCounts#" item="author">
				<tr>
					<td><cfoutput>#author#</cfoutput></td>
					<td><cfoutput>#gitCounts[author]#</cfoutput></td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</div>

<div>
	<cfchart format="png" backgroundcolor="##272B30">
		<cfchartseries type="pie">
			<cfloop from="1" to="#structCount(gitCounts)#" index="i">
				<cfchartdata item="#gitCounts[i]['author']#" value="#gitCounts[i]['count']#" />
			</cfloop>
		</cfchartseries>
	</cfchart>
</div>