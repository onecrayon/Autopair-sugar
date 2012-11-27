# Autopair.sugar

Autopair.sugar adds automatic character pairing for [Espresso](http://macrabbit.com/espresso/). This means that in many contexts you can type a character like `[` and have a closing `]` automatically inserted. It will also automatically skip over closing characters if you type a duplicate (requires characters to be balanced throughout the document).

After installing Autopair.sugar, you can choose how you want it to behave in the advanced preferences:

* **Autopair characters based on context** (default): If you choose this method of autopairing, then autopaired characters will only be inserted if the text following the cursor is optional whitespace followed by a punctuation character, or optional whitespace followed by a newline. This more conservative approach to autopairing is best for people who generally find autopairing frustrating.
* **Autopair characters always**: If you enable this method, then valid characters will always be autopaired when you type them, regardless of context. This may be preferable for people used to other editors that provide autopairing.

Installing this Sugar will enable autopairing for the programming languages that are bundled with Espresso, but by default it will not work in third-party languages unless their Sugar explicitly opts into it (more information on how to do this lower down).

## Installation

**Requires Espresso 2.0**

1. [Download Autopair.sugar](https://github.com/downloads/onecrayon/Autopair-sugar/Autopair.sugar.zip)
2. Unzip the downloaded file (if your browser doesn't do it for you)
3. Double click the Autopair.sugar file to install it

You **cannot** install this Sugar by cloning the git repository or using the "zip" button at the top of this page, because it is written in Objective-C and has to be compiled.

## Exceptions to autopairing

If there is a selection, the Espresso actions system will not trigger the autopairing action; for instance, if you are working in Javascript and type `else` CodeSense will fill in `else if` so when you type `{` the character will replace the selected `if` instead of autopairing. This is a shortcoming of how Espresso implements actions, and there is no short-term workaround.

For those coming from TextMate (and derivatives), please note that Autopair.sugar will not wrap selected text when you type a pairing character. To wrap text, you should instead use the built-in **Actions&rarr;Text&rarr;Wrap With...** action (`command apostrophe` for keyboard junkies).

## Enabling autopairing for third-party languages

To enable autopairing in a third-party Sugar, you will need to create a [ContextualSettings](http://wiki.macrabbit.com/index/ContextualSettings/) folder in the root of the Sugar, and add an XML file to it with the following contents:

    <?xml version="1.0" encoding="UTF-8"?>
    <settings>
        <setting name="autopair-opt-in">
            <language-context>java</language-context>
            <value>[]{}()''""</value>
        </setting>
    </settings>

You can use either `<syntax-context>` or `<language-context>` to define where the setting is valid (see the [Espresso Sugar wiki](http://wiki.macrabbit.com/index/ActionXML/#actions) for documentation), and the `<value>` element should contain a string specifying which characters you want to be autopaired in that context. Autopair.sugar currently supports ASCII quotation marks (`'` or `"`) and braces (`(`, `[`, or `{`) out of the box.

You can also add support for arbitrary contexts by creating a custom Sugar and defining your own ContextualSettings inside of it; Autopair.sugar does not care where the settings are defined.

### Enabling autopairing for arbitrary characters

If you want to autopair something other than ASCII quotation marks and braces, you can do so by adding the custom characters to your ContextualSettings (described above) and then adding a TextActions XML file to your Sugar. For instance, if you wanted to pair angle brackets in HTML you might setup a Sugar with the following files:

    AutopairAngleBrackets.sugar/
        ContextualSettings/
            Autopairing.xml
        TextActions/
            AngleBrackets.xml

**ContextualSettings/Autopairing.xml** is identical to the one above, except that it specifies pairing of angle brackets for HTML and XML:

    <?xml version="1.0" encoding="UTF-8"?>
    <settings>
        <setting name="autopair-opt-in">
            <syntax-context>language-root.html, language-root.xml, tag > punctuation.begin, tag > punctuation.end</syntax-context>
            <value>&lt;></value>
        </setting>
    </settings>

(The "less than" bracket has to be specified either with an entity, as per above, or within a CDATA block; otherwise it will invalidate your XML.)

**TextActions/AngleBrackets.xml** contains the action definitions that enable angle brackets and auto-closing capture (this is necessary to trigger the action in the first place; the autopair-opt-in setting then configures in what contexts the action should take over that character):

    <?xml version="1.0"?>
    <action-recipes>
        <action id="com.mydomain.sugar.autopair.angle-bracket" category="autopair.menu">
            <class>OCAutopair</class>
            <text-trigger key-equivalent="&lt;"></text-trigger>
            <setup>
                <character>&lt;</character>
            </setup>
        </action>
        
        <action id="com.mydomain.sugar.autopair.angle-bracket.autoclose" category="hidden">
            <class>OCAutoclose</class>
            <text-trigger key-equivalent=">"></text-trigger>
            <setup>
                <character>></character>
            </setup>
        </action>
    </action-recipes>

For more information about Sugar development and exactly how these XML files work, see the [Espresso Sugar wiki](http://wiki.macrabbit.com/).

**Please note** that autopairing arbitrary characters can sometimes interact with the system in strange ways; for instance, autopairing angle brackets in HTML as described above will interact poorly with Espresso's built-in automatic tag closing (which is why something like that is not supported by Autopair.sugar by default).

## MIT License

Copyright (c) 2011-2012 Ian Beck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
