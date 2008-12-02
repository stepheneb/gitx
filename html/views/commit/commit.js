var showNewFile = function(file)
{
	$('title').innerHTML = "New file: " + file.path;

	var contents = IndexController.unstagedChangesForFile_(file);
	if (!contents) {
		notify("Can not display changes (Binary file?)", -1);
		return;
	}

	diff.innerHTML = contents.escapeHTML();
	diff.style.display = '';
}

var hideState = function() {
	$("state").style.display = "none";
}

var setState = function(state) {
	$("state").style.display = "";
	$("diff").style.display = "none";
	$("state").innerHTML = state.escapeHTML();
}

var showFileChanges = function(file, cached) {
	if (!file)
		return;

	hideNotification();
	hideState();

	if (file.status == 0) // New file?
		return showNewFile(file);

	var changes;
	if (cached) {
		$("title").innerHTML = "Staged changes for " + file.path;
		changes = IndexController.stagedChangesForFile_(file);
	}
	else {
		$("title").innerHTML = "Unstaged changes for " + file.path;
		changes = IndexController.unstagedChangesForFile_(file);
	}

	if (changes == "") {
		notify("This file has no more changes", 1);
		return;
	}

	displayDiff(changes, cached);
}

var diffHeader;
var originalDiff;

var displayDiff = function(diff, cached)
{
	diffHeader = diff.split("\n").slice(0,4).join("\n");
	originalDiff = diff;

	$("diff").style.display = "";
	highlightDiff(diff, $("diff"));
	hunkHeaders = $("diff").getElementsByClassName("hunkheader");

	for (i = 0; i < hunkHeaders.length; ++i) {
		var header = hunkHeaders[i];
		if (cached)
			header.innerHTML = "<a href='#' class='stagebutton' onclick='addHunk(this, true); return false'>Unstage</a>" + header.innerHTML;
		else
			header.innerHTML = "<a href='#' class='stagebutton' onclick='addHunk(this, false); return false'>Stage</a>" + header.innerHTML;
	}
}

var addHunk = function(hunk, reverse)
{
	hunkHeader = hunk.nextSibling.data.split("\n")[0];
	if (m = hunkHeader.match(/@@.*@@/))
		hunkHeader = m;

	start = originalDiff.indexOf(hunkHeader);
	end = originalDiff.indexOf("\n@@", start + 1);
	end2 = originalDiff.indexOf("\ndiff", start + 1);
	if (end2 < end && end2 > 0)
		end = end2;

	if (end == -1)
		end = originalDiff.length;

	hunkText = originalDiff.substring(start, end);
	hunkText = diffHeader + "\n" + hunkText + "\n";

	if (Controller.stageHunk_reverse_)
		Controller.stageHunk_reverse_(hunkText, reverse);
	else
		alert(hunkText);
}
