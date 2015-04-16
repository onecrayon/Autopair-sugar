/**
 * smart-semicolon.js
 * 
 * Automatically moves the cursor outside matched braces before inserting a semicolon.
 * 
 * Optionally leaves the cursor where it is and inserts an indented linebreak
 * (while also sticking the semicolon outside) if you add <forceLinebreak>yes</forceLinebreak>
 * to the setup.
 */

action.canPerformWithContext = function(context, outError) {
	var sel = context.selectedRanges[0],
		prevChar = '',
		nextChar = '';
	if (sel.length > 0) {
		return false;
	}
	if (sel.location > 0) {
		prevChar = context.substringWithRange(new Range(sel.location - 1, 1));
	}
	if (sel.location + sel.length < context.string.length) {
		nextChar = context.substringWithRange(new Range(sel.location + sel.length, 1));
	}
	var proceed = (prevChar === '[' && nextChar === ']') || (prevChar === '{' && nextChar === '}') || (prevChar === '(' && nextChar === ')');
	if (proceed) {
		// Ensure that we're at the end of the line
		var lineRange = context.lineStorage.lineRangeForIndex(sel.location);
		nextChar = context.substringWithRange(new Range(sel.location, lineRange.location + lineRange.length - sel.location));
		proceed = /^[)}\]]+(?:[\r\n]+)?$/.test(nextChar);
	}	
	return proceed;
};

action.performWithContext = function(context, outError) {
	var sel = context.selectedRanges[0],
		lineRange = context.lineStorage.lineRangeForIndex(sel.location),
		charsLen = lineRange.location + lineRange.length - sel.location,
		nextChars = context.substringWithRange(new Range(sel.location, charsLen)),
		snippet;
	if (/[\r\n]+$/.test(nextChars)) {
		nextChars = nextChars.replace(/^([^\r\n]+)[\r\n]+$/, '$1');
	}
	if (action.setup.forceLinebreak === 'yes') {
		snippet = new CETextSnippet('\n\t$0\n' + nextChars + ';')
	} else {
		snippet = new CETextSnippet(nextChars + ';$0');
	}
	context.selectedRanges = [new Range(sel.location, nextChars.length)];
	return context.insertTextSnippet(snippet, CETextOptionNormalizeIndentationLevel | CETextOptionNormalizeLineEndingCharacters | CETextOptionNormalizeIndentationCharacters);
};
