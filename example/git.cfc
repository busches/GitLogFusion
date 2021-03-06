﻿component output="false" extends="execgit" accessors="true" {
	property name="gitPath" type="string";
	property name="repoPath" type="string";
	property name="issueTrackingPath" type="string";
	property name="issueTrackingRegex" type="string";

	/**
	* @hint init function for persistence
	*/
	public git function init(string gitPath='', string repoPath='', string issueTrackingPath='', string issueTrackingRegex='') {
		setGitPath(arguments.gitPath);
		setRepoPath(arguments.repoPath);
		setIssueTrackingPath(arguments.issueTrackingPath);
		setIssueTrackingRegex(arguments.issueTrackingRegex);

		return this;
	}

	/**
	* @hint grabs the git log
	*/
	public string function log(string logType='', string start='', numeric limit=0, string author='') {
		local.argList = '';

		if (len(arguments.start)) {
			local.argList = local.argList & '--since="' & arguments.start & '"';
		}

		if (arguments.logType == 'xml') {
			local.argList = local.argList & ' --date=short --pretty=format:"<entry><author>%an</author><commitDate>%cd</commitDate><messageBody>%s</messageBody><id>%H</id></entry>"';
		}

		if (arguments.logType == 'piped') {
			local.argList = local.argList & ' --date=short --pretty=format:"%an||%cd||%s||%H"';
		}

		if (val(arguments.limit)) {
			local.argList = local.argList & " -n " & arguments.limit;
		}

		if(len(trim(arguments.author))) {
			local.argList = local.argList & ' --author="' & arguments.author & '"';
		}

		return execGit('log', local.argList, arguments.logType);
	}

	/**
	* @hint commit counts, by author
	*/
	public struct function commitCounts (string begin='', string end='') {
		local.argList = ' --format=format:"%an"';
		local.authorCounts = structNew();

		if (len(arguments.begin) && isDate(arguments.begin)) {
			local.argList = local.argList & ' --after="' & arguments.begin & '"';
		}

		if (len(arguments.end) && isDate(arguments.end)) {
			local.argList = local.argList & ' --before="' & arguments.end & '"';
		}

		local.returnData = execGit("log", local.argList);
		// turn the text string into a list for parsing
		local.returnData = listToArray(local.returnData, chr(10));

		for (local.author in local.returnData) {
			if (!structKeyExists(local.authorCounts, local.author)) {
				local.authorCounts[local.author] = 0;
			}
			local.authorCounts[local.author]++;
		}

		return local.authorCounts;
	}

/*
	Helper Funcs
*/

	/**
	* @hint retrieves the list of files modified for a specific commit id
	*/
	public string function commitFileList (string commitId='') {
		local.argList = ' --no-commit-id --name-only -r ' & arguments.commitId;
		local.return = execGit("diff-tree", local.argList);

		if (!len(local.return)) {
			local.return = 'No files associated with this action.';
		}

		return local.return;
	}

	/**
	* @hint converts the git returned text to valid XML
	*/
	private string function gitLogXML (string gitLog='') {
		try {
			//replace special characters with spaces
			local.gitLogTmp = replaceNoCase(arguments.gitLog, '&', ' and ', 'all');
			local.gitLogTmp = replaceNoCase(arguments.gitLog, "'", ' ', 'all');
			local.gitLogTmp = replaceNoCase(arguments.gitLog, '"', '  ', 'all');

			savecontent variable="local.gitLogXML" {writeOutput('<?xml version="1.0" encoding="UTF-8"?><GitLog>#local.gitLogTmp#</GitLog>');}
		} catch (any exception) {
			savecontent variable="local.gitLogXML" {writeOutput('Error - #exception#');}
		}

		return local.gitLogXML;
	}

	/**
	* @hint provides an array of every author that exists in the repository
	*/
	public array function gitLogAuthorList() {
		local.rawAuthor 	= execGit("shortlog", ' -s -n --all');
		local.commitArr 	= arrayNew(1);
		local.commitList 	= replaceNoCase(local.rawAuthor, chr(10), ',', 'all');

		for (local.i=1; local.i <= listLen(local.commitList); local.i++) {
			local.commitArr[i] = listGetAt(listGetAt(local.commitList, local.i), 2, chr(9));
		}

		return commitArr;
	}

	/**
	* @hint injects a link in the commit message to the issue tracker based on the regex (i.e. rm## it would link rm#100, it goes until the first space).
	*/
	public string function gitIssueTrackingLink(gitMsg='') {
		var tmpId 	= 0;
		var i		= 1;
		var rmFlags = reMatchNoCase("\b" & getissueTrackingRegex() & "\b[^\s]+", gitMsg);

		if (len(trim(getissueTrackingRegex()))) {
			for (i=1; i <= arrayLen(rmFlags); i++) {
				gitMsg = replaceNoCase(gitMsg, rmFlags[i], '<a href="' & getissueTrackingPath() & replaceNoCase(rmFlags[i], getissueTrackingRegex(), '', 'all') & '" target="_blank">' & #rmFlags[i]# & '</a>');
			}
		}

		return gitMsg;
	}
}