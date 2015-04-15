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
	return (prevChar === '[' && nextChar === ']') || (prevChar === '{' && nextChar === '}') || (prevChar === '(' && nextChar === ')');
};

action.performWithContext = function(context, outError) {
	var sel = context.selectedRanges[0],
		nextChar = context.substringWithRange(new Range(sel.location + sel.length, 1));
	var snippet;
	if (action.setup.forceLinebreak === 'yes') {
		snippet = new CETextSnippet('\n\t$0\n' + nextChar + ';')
	} else {
		snippet = new CETextSnippet(nextChar + ';$0');
	}
	context.selectedRanges = [new Range(sel.location, 1)];
	return context.insertTextSnippet(snippet, CETextOptionNormalizeIndentationLevel | CETextOptionNormalizeLineEndingCharacters | CETextOptionNormalizeIndentationCharacters);
};
