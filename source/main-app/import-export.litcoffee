
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Menu items for wiki import/export

Add menu items for importing from a wiki on the same server, and exporting
to it as well:

    window.groupMenuItems.wikiimport =
        text : 'Import from wiki...'
        context : 'file'
        onclick : ->
            if appIsRunningOnGitHub() then return
            pageName = prompt 'Give the name of the page to import (case
                sensitive)', 'Main Page'
            if pageName is null then return
            tinymce.activeEditor.MediaWiki.importPage pageName,
                ( document, metadata ) ->
                    if metadata?
                        tinymce.activeEditor.Settings.document.metadata =
                            metadata
    window.groupMenuItems.wikiexport =
        text : 'Export to wiki'
        context : 'file'
        onclick : ->
            if appIsRunningOnGitHub() then return
            pageName = tinymce.activeEditor.Settings.document.get \
                'wiki_title'
            if not pageName?
                tinymce.activeEditor.Dialogs.alert
                    title : 'Page Title not set'
                    message : '<p>You have not yet set the title under
                        which this document should be published on the wiki.
                        See the document settings on the File menu.</p>'
                return
            username = tinymce.activeEditor.Settings.application.get \
                'wiki_username'
            password = tinymce.activeEditor.Settings.application.get \
                'wiki_password'
            if not username? or not password?
                tinymce.activeEditor.Dialogs.alert
                    title : 'No Wiki Credentials'
                    message : '<p>You have not given your wiki username
                        and password to the application settings.  See the
                        application settings on the File menu.</p>'
                return
            postCallback = ( result, error ) ->
                if error
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Posting Error'
                        message : "<p>Error when posting to the wiki:</p>
                            <p>#{error}</p>"
                    return
                match = /^[^/]+\/\/[^/]+\//.exec window.location.href
                url = window.location.href[...match[0].length] + \
                    'wiki/index.php?title=' + encodeURIComponent pageName
                tinymce.activeEditor.Dialogs.alert
                    title : 'Document Posted'
                    message : "<p>Posting succeeded.</p>
                        <p><a href='#{url}' target='_blank'>Visit posted
                        page.</a></p>"
            loginCallback = ( result, error ) ->
                if error
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Wiki Login Error'
                        message : "<p>Error when logging into the wiki:</p>
                            <p>#{error}</p>"
                    return
                content = tinymce.activeEditor.Storage.embedMetadata \
                    tinymce.activeEditor.getContent(),
                    tinymce.activeEditor.Settings.document.metadata
                tinymce.activeEditor.MediaWiki.exportPage pageName,
                    content, postCallback
            tinymce.activeEditor.MediaWiki.login username, password,
                loginCallback

## Import/export on startup

Now, a few actions to take after the editor has been initialized.

If the query string told us to load a page from the wiki, or a page fully
embedded in a (possibly enormous) URL, do so.  Note that the way we handle
the enormous URLs is by storing them in the browser's `localStorage`, then
reloading the page without the query string, and then pulling the data from
`localStorage`.

    window.afterEditorReadyArray.push ( editor ) ->
        queryString = window.location.search
        postAfter = null
        if match = /^\?post-after-autoload=(.*)/.exec queryString
            postAfter = ->
                editor.Storage.waitForMetaData ( metadata ) ->
                    window.parent.postMessage
                        type : 'metadata loaded'
                        metadata : metadata
                    , '*'
            queryString = "?autoload=#{match[1]}"
        editor.MediaWiki.setIndexPage '/wiki/index.php'
        editor.MediaWiki.setAPIPage '/wiki/api.php'
        if match = /\?wikipage=(.*)/.exec queryString
            editor.MediaWiki.importPage decodeURIComponent match[1],
                ( document, metadata ) ->
                    if metadata? then editor.Storage.loadMetaData metadata
        autoLoadName = 'auto-load'
        if match = /\?autoload=(.*)/.exec queryString
            autoLoadName = decodeURIComponent match[1]
        if toAutoLoad = localStorage.getItem autoLoadName
            try
                [ metadata, document ] = JSON.parse toAutoLoad
                setTimeout ->
                    localStorage.removeItem autoLoadName
                    shorthandRE = /^\s*<shorthand>(.*)<\/shorthand>\s*$/
                    document = document.replace /\n|\cJ/g, ' '
                    if m = shorthandRE.exec document
                        filename = "dependency-for-#{autoLoadName}"
                        translateShorthandIntoEditor editor, document,
                            ( replace ) ->
                                if replace
                                    metadata ?= { }
                                    metadata.dependencies = [
                                        address : filename
                                        data : replace.exports
                                        date : new Date
                                    ]
                                editor.Storage.loadMetaData metadata
                                postAfter?()
                        , filename
                    else
                        editor.setContent document
                        editor.Storage.loadMetaData metadata
                        postAfter?()
                , 100
        if match = /\?document([0-9]*)=(.*)/.exec queryString
            html = decodeURIComponent match[2]
            { metadata, document } = editor.Storage.extractMetadata html
            localStorage.setItem 'auto-load' + match[1],
                JSON.stringify [ metadata, document ]
            window.location.href = window.location.href.split( '?' )[0] +
                '?autoload=auto-load' + match[1]

## GitHub check

The following function is just to ensure that functionality that depends on
a wiki installation doesn't break when the app is served from GitHub.
Instead of breaking, the app will clearly state that...well, you can read
the message below for yourself.

    appIsRunningOnGitHub = ->
        result = /nathancarter\.github\.io/.test window.location.href
        if result
            tinymce.activeEditor.Dialogs.alert
                title : 'Not Available Here'
                message : '<p>That functionality requires MediaWiki to be
                    running on the server from which you\'re accessing this
                    web app.</p>
                    <p>On GitHub, we cannot run a MediaWiki server, so the
                    functionality is disabled.</p>
                    <p>The menu items remain for use in developer testing,
                    as we prepare for a dedicated server that will have
                    MediaWiki and the ability to publish documents to that
                    wiki with a single click, or edit them in Lurch with a
                    single click.</p>
                    <p>Try back soon!</p>'
        result

## Lurch shorthand

Lurch Shorthand solves two problems that would arise from exposing to
authors of raw HTML (or something related, such as Markdown) the HTML form
used by the main webLurch application.
 1. the HTML form can have large chunks of encoded binary data in it, making
    it very difficult for humans to read and edit, and
 2. those large chunks of encoded binary data also make the raw HTML form
    very lengthy.

Authors of web pages and blogs usually want their HTML (or Markdown) source
to be human-readable.  This is especially important if the author is writing
documentation that will be compiled, and thus will be committing it to a
revision control repository.

Lurch Shorthand is defined as HTML plus the following new tags.
 * Any element `<e>...</e>` indicates a Lurch expression.  These can be
   nested.
 * You can make an expression represent an attribute embedded in its
   immediate parent by giving its open tag an attribute with key `at`, whose
   value is the key for which the expression attribute, and the expression
   itself serves as the corresponding value.
    * Example:  In `<e>Foo<e at='size'>large</e></e>` we have an expression
      `<e>Foo</e>` with embedded (hidden) expression attribute whose key is
      "size" and whose value is "large".
 * You can give an expression a unique ID, so that you can refer to it from
   other expressions (in order to connect them) by giving its open tag an
   attribute with key `n` and any non-negative integer as the value.
    * Example:  `<e n='5'>my element number five</e>`
    * You may not include both the `n` and `at` attributes, because hidden
      expressions cannot be the targets of connections.
    * These unique IDs are used only in the shorthand notation, and do not
      show up in the actual document constructed from the shorthand.
 * You can form a connection from an expression to another expression by
   giving the source expression's open tag the attribute with key `to` and
   with value a comma-separated list of the integer IDs for the targets to
   which this expression should be connected.
    * Example: `<e to='5,6'>this expression connects to the one in the
      previous example, plus another</e>`
    * The IDs in the comma-separated list are those that appear in the `n`
      attribute of other expressions in this same block of shorthand.
    * Translation behavior is undefined when a cyclic set of connections is
      described in this way.  It may result in an empty document, a
      different document, an invalid document, etc.; no guarantees are made.
 * To form an external attribute, use both the `at='key'` and `to='target'`
   forms together.

The following function takes a string of Lurch Shorthand code and converts
it to the corresponding raw HTML for use by the main webLurch application,
places it into the active TinyMCE editor, then forms the necessary Group
instances and connections among them.  It also clears the undo/redo stack,
so that this action cannot be undone, as if the document were just opened
from a file.

If a callback is provided, this function asynchronously calls it with the
metadata embedded in the shorthand, if there was any, or null if there was
not.  In order to process dependency information in shorthand (which will
make up the metadata) we must have a unique file into which we can save a
dependency temporarily.  Pass that filename as the fourth parameter.

    translateShorthandIntoEditor =
    ( editor, shorthand, callback, filename ) ->

Create a temporary DIV in which to reconstruct the given HTML as DOM
elements, then initialize several variables that will be populated by the
recursive routine below, which will traverse that DIV's internal DOM
hierarchy.

        doc = editor.getDoc()
        div = doc.createElement 'div'
        div.innerHTML = shorthand
        nToId = { }
        idToN = { }
        connections = { }
        idToKey = { }
        nextId = 0
        dependencyContent = null

Recursively transform the DOM hierarchy inside the DIV (which was created
from the shorthand HTML in the parameter) into HTML text that can be placed
into the editor.  This involves translating all `<e>...</e>` patterns into
open-close grouper pairs.

It also stores into the variables above data about which elements are hidden
attributes, and which are connected to one another, so that after this
routine has been run, and its contents placed into the editor, we can use
routines in the Groups module to embed attributes and make other
connections.

We also ensure that the order in which we assign IDs numbers parents lower
than their children.  This will be important when we embed attributes, in
code later in this same function.

        recur = ( element ) ->
            if element.tagName is 'DEPENDENCY'
                dependencyContent =
                    "<shorthand>#{element.innerHTML}</shorthand>"
                return ''
            if element.tagName is 'E' then thisId = nextId++
            translatedChildren =
                ( recur child for child in element.childNodes )
            if element.tagName is 'E'
                if element.hasAttribute 'n'
                    n = element.getAttribute 'n'
                    nToId[n] = thisId
                    idToN[thisId] = n
                if element.hasAttribute 'at'
                    idToKey[thisId] = element.getAttribute 'at'
                if element.hasAttribute 'to'
                    connections[thisId] = ( Number i \
                        for i in element.getAttribute( 'to' ).split ',' )
                grouperHTML( 'expression', 'open', thisId, no, '' ) +
                    translatedChildren.join( '' ) +
                    grouperHTML( 'expression', 'close', thisId, no, '' )
            else
                copy = element.cloneNode no
                copy.innerHTML = translatedChildren.join ''
                copy.outerHTML ? copy.textContent

Run the recursive routine, fill the editor with it, and instruct the editor
to update the data in the Groups package based on all the new content just
inserted.  (We rely on that scanning in the functions we call in the Groups
package immediately thereafter.)

        editor.setContent recur div
        editor.Groups.scanDocument()

Find every group that was, in the original shorthand notation in the input,
marked as an embedded attribute in its parent group.  Do the embedding,
taking care to respect the situation when there are multiple attributes in
the same parent with the same key, which must then form a list of values
under that key.

We work from the end of the document toward the beginning, because child
elements have been numbered with higher IDs than their parents, so if there
are nested attribute embeddings, we will therefore handle the innermost ones
first.

        for id in [nextId..0]
            if id of idToKey
                continue unless group = editor.Groups[id]
                if not group.parent
                    group.set 'key', idToKey[id]
                    group.set 'keyposition', 'arrow'
                    continue
                internalKey = OM.encodeAsIdentifier idToKey[id]
                internalValue =
                    m : group.completeForm().encode()
                    v : LZString.compress group.groupAsHTML no
                if already = group.parent.get internalKey
                    expression = OM.decode already.m
                    if expression.children[0]?.equals Group::listSymbol
                        already.m = ( OM.app expression.children[0],
                            OM.decode( internalValue.m ),
                            expression.children[1]... ).encode()
                    else
                        already.m = ( OM.app Group::listSymbol, expression,
                            OM.decode internalValue.m ).encode()
                    already.v = internalValue.v + already.v
                    internalValue = already
                group.parent.set internalKey, internalValue
                group.remove()

For every connection mentioned in the original shorthand code, ask the two
groups to connect themselves now, using the `connect` method of the Group
class.

        for sourceId, targetNs of connections
            continue unless source = editor.Groups[sourceId]
            for n in targetNs
                if target = editor.Groups[nToId[n]]
                    source.connect target

Clear the editor's undo/redo stack, so that its current contents act as if
they are a newly opened document.  (We do not want users to be able to undo
any portion of the document setup procedure just executed.)

        editor.undoManager.clear()

Now, if there is no dependency content, call the callback with null
metadata.

        if callback?
            if dependencyContent is null then return callback null

Otherwise, we must create a hidden Lurch app instance and load the
dependency content into it so that we can then extract its exports data, for
use in this app.

            localStorage.setItem filename,
                JSON.stringify [ null, dependencyContent ]
            otherLurch = document.createElement 'iframe'
            handler = ( message ) ->
                if message.data.type is 'metadata loaded'
                    window.removeEventListener 'message', handler
                    callback message.data.metadata
                    document.body.removeChild otherLurch
            window.addEventListener 'message', handler, no
            otherLurch.setAttribute 'src',
                window.location.href.split( '?' )[0] +
                '?post-after-autoload=' + filename
            otherLurch.style.display = 'none'
            document.body.appendChild otherLurch
