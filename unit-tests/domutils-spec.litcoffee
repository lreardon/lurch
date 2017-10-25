
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage,
      pageExpectsError } = require './phantom-utils'

## address member function of Node class

The tests in this section test the `address` member function in the `Node`
prototype. [See its definition here.](domutils.litcoffee.html#address).

    phantomDescribe 'address member function of Node class',
    './app/app.html', ->

### should be defined

First, just verify that it's present.

        it 'should be defined', inPage ->
            pageExpects -> Node::address

### should give null on corner cases

        it 'should give null on corner cases', inPage ->

The corner cases to be tested here are these:
 * The address of a DOM node within one of its children.
 * The address of a DOM node within one of its siblings.

Although there are others we could test, these are enough for now.

            pageDo ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
            pageExpects ( -> pardiv.address( chidiv1 ) ), 'toBeNull'
            pageExpects ( -> pardiv.address( chidiv2 ) ), 'toBeNull'
            pageExpects ( -> chidiv1.address( chidiv2 ) ), 'toBeNull'
            pageExpects ( -> chidiv2.address( chidiv1 ) ), 'toBeNull'

### should be empty when argument is this

        it 'should be empty when argument is this', inPage ->

We will test a few cases where the argument is the node it's being called
on, for various nodes.

            pageDo ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
            pageExpects ( -> pardiv.address( pardiv ) ), 'toEqual', [ ]
            pageExpects ( -> chidiv1.address( chidiv1 ) ), 'toEqual', [ ]
            pageExpects ( -> chidiv2.address( chidiv2 ) ), 'toEqual', [ ]
            pageExpects ( -> document.address( document ) ), 'toEqual', [ ]
            pageExpects ( -> document.body.address document.body ),
                'toEqual', [ ]

### should be empty for top-level,null

        it 'should be empty for top-level,null', inPage ->

The simplest way to test this is to compute the address of the document, and
expect it to be the empty array.  But we also make the document create an
empty div and not put it inside any other node, and we expect that its
address will also be the empty array.

            pageExpects ( -> document.address() ), 'toEqual', [ ]
            pageExpects ( ->
                document.createElement( 'div' ).address() ), 'toEqual', [ ]

### should be length-1 for a child

        it 'should be length-1 for a child', inPage ->

Run a baseline test to be sure we know the size of the document now.  It
should have five children: the empty text in the document body by default,
the DIV containing the editor, the original TEXTAREA from which the editor
was create (now invisible), plus two IFRAMEs added by the Google web API for
URL shortening.

            pageExpects ( -> document.body.childNodes.length ), 'toEqual', 5

First, add some structure to the document. We will need to run tests on a
variety of parent-child pairs of nodes, so we need to create such pairs as
structures in the document first.

            pageDo ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2

Next, create some structure *outside* the document. We want to verify that
our routines work outside the page's document as well.

                window.outer = document.createElement 'div'
                window.inner = document.createElement 'span'
                outer.appendChild inner

We call the `address` function in several different ways, but each time we
call it on an immediate child of the argument (or an immediate child of the
document, with no argument).  Sometimes we compute the same result in both
of those ways to verify that they are equal.

            pageExpects ( ->
                document.childNodes[0].address document ), 'toEqual', [ 0 ]
            pageExpects ( -> document.childNodes[0].address() ),
                'toEqual', [ 0 ]
            pageExpects ( -> chidiv1.address pardiv ), 'toEqual', [ 0 ]
            pageExpects ( -> chidiv2.address pardiv ), 'toEqual', [ 1 ]
            pageExpects ( -> document.body.childNodes.length ),
                'toEqual', 6
            pageExpects ( -> pardiv.address document.body ),
                'toEqual', [ 5 ]
            pageExpects ( -> inner.address outer ), 'toEqual', [ 0 ]

### should work for grandchildren, etc.

        it 'should work for grandchildren, etc.', inPage ->

First, we construct a hierarchy with several levels so that we can ask
questions across those various levels.  This also ensures that we know
exactly what the child indices are, because we designed the hierarchy in the
first place.

            pageDo ->
                hierarchy = '''
                    <span id="test-0">foo</span>
                    <span id="test-1">bar</span>
                    <div id="test-2">
                        <span id="test-3">baz</span>
                        <div id="test-4">
                            <div id="test-5">
                                <span id="test-6">
                                    f(<i>x</i>)
                                </span>
                                <span id="test-7">
                                    f(<i>x</i>)
                                </span>
                            </div>
                            <div id="test-8">
                            </div>
                        </div>
                    </div>
                    '''

In order to ensure that we do not insert any text nodes that would change
the expected indices of the elements in the HTML code above, we remove
whitespace between tags before creating a DOM structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy
                window.elts = ( document.getElementById \
                    "test-#{i}" for i in [0..8] )

We check the address of each test element inside the div we just created, as
well as its address relative to the div with id `test-2`.

First, check all descendants of the main div.

            pageExpects ( -> elts[0].address div ), 'toEqual', [ 0 ]
            pageExpects ( -> elts[1].address div ), 'toEqual', [ 1 ]
            pageExpects ( -> elts[2].address div ), 'toEqual', [ 2 ]
            pageExpects ( -> elts[3].address div ), 'toEqual', [ 2, 0 ]
            pageExpects ( -> elts[4].address div ), 'toEqual', [ 2, 1 ]
            pageExpects ( -> elts[5].address div ), 'toEqual', [ 2, 1, 0 ]
            pageExpects ( -> elts[6].address div ),
                'toEqual', [ 2, 1, 0, 0 ]
            pageExpects ( -> elts[7].address div ),
                'toEqual', [ 2, 1, 0, 1 ]
            pageExpects ( -> elts[8].address div ), 'toEqual', [ 2, 1, 1 ]

Next, check the descendants of the element with id `test-2` for their
addresses relative to that element.

            pageExpects ( -> elts[2].address elts[2] ), 'toEqual', [ ]
            pageExpects ( -> elts[3].address elts[2] ), 'toEqual', [ 0 ]
            pageExpects ( -> elts[4].address elts[2] ), 'toEqual', [ 1 ]
            pageExpects ( -> elts[5].address elts[2] ), 'toEqual', [ 1, 0 ]
            pageExpects ( -> elts[6].address elts[2] ),
                'toEqual', [ 1, 0, 0 ]
            pageExpects ( -> elts[7].address elts[2] ),
                'toEqual', [ 1, 0, 1 ]
            pageExpects ( -> elts[8].address elts[2] ), 'toEqual', [ 1, 1 ]

### should work in the iframe also

We repeat a small subset of the above tests inside the TinyMCE editor's
iframe, to ensure that the tools are working there as well.

        it 'should work in the iframe also', inPage ->
            pageExpects -> tinymce.activeEditor.getWin().Node::address
            pageExpects ( -> tinymce.activeEditor.getDoc().address() ),
                'toEqual', [ ]
            pageExpects ->
                tinymce.activeEditor.getDoc().childNodes[0].address \
                    tinymce.activeEditor.getDoc()
            , 'toEqual', [ 0 ]

## index member function of Node class

The tests in this section test the `index` member function in the `Node`
prototype.  This function is like the inverse of `address`. [See its
definition here.](domutils.litcoffee.html#index).

    phantomDescribe 'index member function of Node class',
    './app/app.html', ->

### should be defined

        it 'should be defined', inPage ->
            pageExpects -> Node::index

### should give errors for non-arrays

        it 'should give errors for non-arrays', inPage ->

Verify that calls to the function throw errors if anything but an array is
passed as the argument, and that the error messages contain the relevant
portion of the expected error message.

            pageExpectsError ( -> document.index 0 ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index 0: 0 ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index document ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index -> ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index '[0,0]' ),
                'toMatch', /requires an array/

### should yield itself for []

        it 'should yield itself for []', inPage ->

Verify that `N.index []` yields `N`, for any node `N`. We test a variety of
type of nodes, including the document, the body, some DIVs and SPANs inside,
as well as some DIVs and SPANs that are not part of the document.

            pageDo ->
                window.divInPage = document.createElement 'div'
                document.body.appendChild divInPage
                window.spanInPage = document.createElement 'span'
                document.body.appendChild spanInPage
                window.divOutside = document.createElement 'div'
                window.spanOutside = document.createElement 'span'
            pageExpects -> divInPage is divInPage.index []
            pageExpects -> spanInPage is spanInPage.index []
            pageExpects -> divOutside is divOutside.index []
            pageExpects -> spanOutside is spanOutside.index []
            pageExpects -> document is document.index []
            pageExpects -> document.body is document.body.index []

### should work for descendant indices

        it 'should work for descendant indices', inPage ->

Here we re-use the same hierarchy from [a test
above](#should-work-for-grandchildren-etc-), for the same reasons.

            pageDo ->
                hierarchy = '''
                    <span id="test-0">foo</span>
                    <span id="test-1">bar</span>
                    <div id="test-2">
                        <span id="test-3">baz</span>
                        <div id="test-4">
                            <div id="test-5">
                                <span id="test-6">
                                    f(<i>x</i>)
                                </span>
                                <span id="test-7">
                                    f(<i>x</i>)
                                </span>
                            </div>
                            <div id="test-8">
                            </div>
                        </div>
                    </div>
                    '''

For the same reasons as above, we remove whitespace between tags before
creating a DOM structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Look up a lot of addresses, and verify their ids (if they are elements with
ids) or their text content (if they are text nodes).

            pageExpects ( -> div.index( [ 0 ] ).id ), 'toEqual', 'test-0'
            pageExpects ( -> div.index( [ 1 ] ).id ), 'toEqual', 'test-1'
            pageExpects ( -> div.index( [ 2 ] ).id ), 'toEqual', 'test-2'
            pageExpects ( -> div.index( [ 0, 0 ] ).textContent ),
                'toEqual', 'foo'
            pageExpects ( -> div.index( [ 1, 0 ] ).textContent ),
                'toEqual', 'bar'
            pageExpects ( -> div.index( [ 2, 0 ] ).id ), 'toEqual', 'test-3'
            pageExpects ( -> div.index( [ 2, 0, 0 ] ).textContent ),
                'toEqual', 'baz'
            pageExpects ( -> div.index( [ 2, 1 ] ).id ), 'toEqual', 'test-4'
            pageExpects ( -> div.index( [ 2, 1, 0 ] ).id ),
                'toEqual', 'test-5'
            pageExpects ( -> div.index( [ 2, 1, 0, 0 ] ).id ),
                'toEqual', 'test-6'
            pageExpects ( -> div.index( [ 2, 1, 0, 0, 1 ] ).textContent ),
                'toEqual', 'x'
            pageExpects ( -> div.index( [ 2, 1, 0, 1 ] ).id ),
                'toEqual', 'test-7'
            pageExpects ( -> div.index( [ 2, 1, 1 ] ).id ),
                'toEqual', 'test-8'

### should give undefined for bad indices

        it 'should give undefined for bad indices', inPage ->

Verify that calls to the function return undefined if any step in the
address array is invalid.  There are many ways for this to happen (entry
less than zero, entry larger than number of children at that level, entry
not an integer, entry not a number at all). We test each of these cases
below.

First we re-create the same hierarchy from [a test
above](#should-work-for-grandchildren-etc-), for the same reasons.

            pageDo ->
                hierarchy = '''
                    <span id="test-0">foo</span>
                    <span id="test-1">bar</span>
                    <div id="test-2">
                        <span id="test-3">baz</span>
                        <div id="test-4">
                            <div id="test-5">
                                <span id="test-6">
                                    f(<i>x</i>)
                                </span>
                                <span id="test-7">
                                    f(<i>x</i>)
                                </span>
                            </div>
                            <div id="test-8">
                            </div>
                        </div>
                    </div>
                    '''

For the same reasons as above, we remove whitespace between tags before
creating a DOM structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Now call `div.index` with addresses that contain each of the erroneous steps
mentioned above.  Here we call `typeof` on each of the return values,
because we expect that they will be undefined in each case, and we wish to
populate our array with that information in string form, so that it can be
returned from the page as valid JSON.

            pageExpects ( -> typeof div.index [ -1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 3 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 300000 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0.2 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 'something' ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 'childNodes' ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ [ 0 ] ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ [ ] ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ { } ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ div ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, -1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, 1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, 'ponies' ] ),
                'toEqual', 'undefined'

### should work in the iframe also

We repeat a small subset of the above tests inside the TinyMCE editor's
iframe, to ensure that the tools are working there as well.

        it 'should work in the iframe also', inPage ->
            pageExpects -> tinymce.activeEditor.getWin().Node::index
            pageExpects ->
                tinymce.activeEditor.getDoc() is \
                    tinymce.activeEditor.getDoc().index []
            pageExpects ->
                tinymce.activeEditor.getDoc().childNodes[0] is \
                    tinymce.activeEditor.getDoc().index [ 0 ]

## Node toJSON conversion

The tests in this section test the `toJSON` member function in the `Node`
prototype. [See its definition here.](domutils.litcoffee.html#serialization)

    phantomDescribe 'Node toJSON conversion',
    './app/app.html', ->

### should be defined

        it 'should be defined', inPage ->

First, just verify that the function itself is present.

            pageExpects -> Node::toJSON

### should convert text nodes to strings

        it 'should convert text nodes to strings', inPage ->

HTML text nodes should serialize as ordinary strings. We test a variety of
ways they might occur.

            pageDo ->
                window.textNode = document.createTextNode 'foo'
                window.div = document.createElement 'div'
                div.innerHTML = '<i>italic</i> not italic'
            pageExpects ( -> textNode.toJSON() ), 'toEqual', 'foo'
            pageExpects ( -> div.childNodes[0].childNodes[0].toJSON() ),
                'toEqual', 'italic'
            pageExpects ( -> div.childNodes[1].toJSON() ),
                'toEqual', ' not italic'

### should convert comment nodes to objects

        it 'should convert comment nodes to objects', inPage ->

HTML comment nodes should serialize as objects with the comment flag and the
comment's text content as well.

            pageExpects ( ->
                comment = document.createComment 'comment content'
                comment.toJSON() ), 'toEqual',
                comment : yes, content : 'comment content'
            pageExpects ( ->
                comment = document.createComment ''
                comment.toJSON() ), 'toEqual',
                comment : yes, content : ''

### should handle other no-children elements

        it 'should handle other no-children elements', inPage ->

Other no-children elements include images, horizontal rules, and line
breaks.  We verify that in each case the object is encoded with the correct
tag name and attributes, but no children.

            pageDo ->
                window.div = document.createElement 'div'
                div.innerHTML = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC" width="31" height="24"><hr><br>'
            pageExpects ( -> div.childNodes[0].toJSON() ), 'toEqual',
                tagName : 'IMG'
                attributes :
                    width : '31'
                    height : '24'
                    src : 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC'
            pageExpects ( -> div.childNodes[1].toJSON() ),
                'toEqual', tagName : 'HR'
            pageExpects ( -> div.childNodes[2].toJSON() ),
                'toEqual', tagName : 'BR'

### should handle spans correctly

        it 'should handle spans correctly', inPage ->

Must correctly convert things of the form `<span>text</span>` or
`<i>text</i>` or any other simple, non-nested tag.  Three simple tests are
done, plus one with two different attributes.

First, a span created by appending a text node child to a new span element.

            pageExpects ( ->
                span1 = document.createElement 'span'
                span1.appendChild document.createTextNode 'hello'
                span1.toJSON() ), 'toEqual',
                    tagName : 'SPAN'
                    children : [ 'hello' ]

Next, a span created by assigning to the innerHTML property of a new span
element.

            pageExpects ( ->
                span2 = document.createElement 'span'
                span2.innerHTML = 'world'
                span2.toJSON() ), 'toEqual',
                    tagName : 'SPAN'
                    children : [ 'world' ]

Next, an italic element lifted out of a div, where it was created using the
innerHTML property of the div.

            pageExpects ( ->
                div1 = document.createElement 'div'
                div1.innerHTML = '<i>The Great Gatsby</i>'
                div1.childNodes[0].toJSON() ), 'toEqual',
                    tagName : 'I'
                    children : [ 'The Great Gatsby' ]

Same as the previous, but this time with some attributes on the element.

            pageExpects ( ->
                div2 = document.createElement 'div'
                div2.innerHTML = '<i class="X" id="Y">Z</i>'
                div2.childNodes[0].toJSON() ), 'toEqual',
                    tagName : 'I'
                    attributes : class : 'X', id : 'Y'
                    children : [ 'Z' ]

### should handle hierarchies correctly

        it 'should handle hierarchies correctly', inPage ->

The above tests cover simple situations, either DOM trees of height 1 or 2.
Now we consider situations in which there are many levels to the Node tree.
I choose three examples, and mix in a diversity of depths, attributes, tag
names, comments, etc.

            pageDo ->
                window.div1 = document.createElement 'div'
                div1.innerHTML = '<span class="outermost" id=0>' +
                                 '<span class="middleman" id=1>' +
                                 '<span class="innermost" id=2>' +
                                 'finally, the text' +
                                 '</span></span></span>'
                document.body.appendChild div1
                window.div2 = document.createElement 'div'
                div2.innerHTML = '<p>Some paragraph.</p>' +
                                 '<p>Another paragraph, this ' +
                                 'one with some ' +
                                 '<b>force!</b></p>' +
                                 '<table border=1>' +
                                 '<tr><td width=50%>Name</td>' +
                                 '<!--random comment-->' +
                                 '</td><td width=50%>Age</td>' +
                                 '</tr></table>'
                document.body.appendChild div2
                window.div3 = document.createElement 'div'
                div3.innerHTML = 'start with a text node' +
                                 '<!-- then a comment -->' +
                                 '<p>then <i>MORE</i></p>'
                document.body.appendChild div3
            pageExpects ( -> div1.toJSON() ), 'toEqual',
                tagName : 'DIV'
                children : [
                    tagName : 'SPAN'
                    attributes : class : 'outermost', id : '0'
                    children : [
                        tagName : 'SPAN'
                        attributes : class : 'middleman', id : '1'
                        children : [
                            tagName : 'SPAN'
                            attributes : class : 'innermost', id : '2'
                            children : [ 'finally, the text' ]
                        ]
                    ]
                ]
            pageExpects ( -> div2.toJSON() ), 'toEqual',
                tagName : 'DIV'
                children : [
                    tagName : 'P'
                    children : [ 'Some paragraph.' ]
                ,
                    tagName : 'P'
                    children : [
                        'Another paragraph, this one with some '
                        tagName : 'B', children : [ 'force!' ]
                    ]
                ,
                    tagName : 'TABLE'
                    attributes : border : '1'
                    children : [
                        tagName : 'TBODY'
                        children : [
                            tagName : 'TR'
                            children : [
                                tagName : 'TD'
                                attributes : width : '50%'
                                children : [ 'Name' ]
                            ,
                                comment : yes
                                content : 'random comment'
                            ,
                                tagName : 'TD'
                                attributes : width : '50%'
                                children : [ 'Age' ]
                            ]
                        ]
                    ]
                ]
            pageExpects ( -> div3.toJSON() ), 'toEqual',
                tagName : 'DIV'
                children : [
                    'start with a text node'
                ,
                    comment : yes
                    content : ' then a comment '
                ,
                    tagName : 'P'
                    children : [
                        'then '
                        tagName : 'I', children : [ 'MORE' ]
                    ]
                ]

### should respect verbosity setting

        it 'should respect verbosity setting', inPage ->

The verbosity setting of the serializer defaults to true, and gives results
like those shown in the tests above, whose object keys are human-readable.
If verbosity is disabled, as in the tests below, then each key is shrunk to
a unique one-letter abbreviation, as documented [in the module where the
serialization is implemented]( domutils.litcoffee.html#serialization).

Here we do only one, brief test of each of the types tested above.

            pageExpects ( ->
                node = document.createTextNode 'text node'
                node.toJSON no ), 'toEqual', 'text node'
            pageExpects ( ->
                node = document.createComment 'swish'
                node.toJSON no ), 'toEqual',
                    m : yes
                    n : 'swish'
            pageExpects ( ->
                node = document.createElement 'hr'
                node.toJSON no ), 'toEqual', t : 'HR'
            pageDo ->
                window.div = document.createElement 'div'
                div.innerHTML = '<p align="left">paragraph</p>' +
                                '<p><span id="foo">bar</span>' +
                                ' <i class="baz">quux</i></p>'
            pageExpects ( ->
                node = div.childNodes[0]
                node.toJSON no ), 'toEqual',
                    t : 'P'
                    a : align : 'left'
                    c : [ 'paragraph' ]
            pageExpects ( ->
                node = div.childNodes[1]
                node.toJSON no ), 'toEqual',
                    t : 'P'
                    c : [
                        t : 'SPAN'
                        a : id : 'foo'
                        c : [ 'bar' ]
                    ,
                        ' '
                    ,
                        t : 'I'
                        a : class : 'baz'
                        c : [ 'quux' ]
                    ]

### should work in the iframe also

We repeat a small subset of the above tests inside the TinyMCE editor's
iframe, to ensure that the tools are working there as well.

        it 'should work in the iframe also', inPage ->
            pageExpects -> tinymce.activeEditor.getWin().Node::toJSON
            pageDo ->
                window.textNode =
                    tinymce.activeEditor.getDoc().createTextNode 'foo'
                window.div =
                    tinymce.activeEditor.getDoc().createElement 'div'
                div.innerHTML = '<i>italic</i> not italic'
            pageExpects ( -> textNode.toJSON() ), 'toEqual', 'foo'
            pageExpects ( -> div.toJSON() ), 'toEqual',
                tagName : 'DIV'
                children : [
                    tagName : 'I'
                    children : [ 'italic' ]
                ,
                    ' not italic'
                ]

## Node fromJSON conversion

The tests in this section test the `fromJSON` member function in the `Node`
object. [See its definition here.](
domutils.litcoffee.html#from-objects-to-dom-nodes)

    phantomDescribe 'Node fromJSON conversion',
    './app/app.html', ->

### should be defined

        it 'should be defined', inPage ->

First, just verify that the function itself is present.

            pageExpects -> Node.fromJSON

### should convert strings to text nodes

        it 'should convert strings to text nodes', inPage ->

This test is simply the inverse of the analogous test earlier. It verifies
that two strings, one empty and one nonempty, both get converted correctly
into `Text` instances with the appropriate content.

            pageDo ->
                window.node1 = Node.fromJSON 'just a string'
                window.node2 = Node.fromJSON ''
            pageExpects -> node1 instanceof Node
            pageExpects -> node1 instanceof Text
            pageExpects -> node1 not instanceof Comment
            pageExpects -> node1 not instanceof Element
            pageExpects ( -> node1.textContent ), 'toEqual', 'just a string'
            pageExpects -> node2 instanceof Node
            pageExpects -> node2 instanceof Text
            pageExpects -> node2 not instanceof Comment
            pageExpects -> node2 not instanceof Element
            pageExpects ( -> node2.textContent ), 'toEqual', ''

### should handle comment objects

        it 'should handle comment objects', inPage ->

This test is simply the inverse of the analogous test earlier. It verifies
that two objects, one in verbose and one in non-verbose notation, one empty
and one nonempty, both get converted correctly into `Comment` instances with
the appropriate content.

            pageDo ->
                window.node1 = Node.fromJSON m : yes, n : 'some comment'
                window.node2 = Node.fromJSON comment : yes, content : ''
            pageExpects -> node1 instanceof Node
            pageExpects -> node1 not instanceof Text
            pageExpects -> node1 instanceof Comment
            pageExpects -> node1 not instanceof Element
            pageExpects ( -> node1.textContent ), 'toEqual', 'some comment'
            pageExpects -> node2 instanceof Node
            pageExpects -> node2 not instanceof Text
            pageExpects -> node2 instanceof Comment
            pageExpects -> node2 not instanceof Element
            pageExpects ( -> node2.textContent ), 'toEqual', ''

### should be able to create empty elements

        it 'should be able to create empty elements', inPage ->

This test is simply the inverse of the analogous test earlier. It verifies
that two objects, one in verbose and one in non-verbose notation, both get
converted correctly into `Element` instances with no children but the
appropriate tags and attributes.

            pageDo ->
                window.node1 = Node.fromJSON \
                    tagName : 'hr',
                    attributes : class : 'y', whatever : 'dude'
                window.node2 = Node.fromJSON t : 'br', a : id : '24601'
            pageExpects -> node1 instanceof Node
            pageExpects -> node1 not instanceof Text
            pageExpects -> node1 not instanceof Comment
            pageExpects -> node1 instanceof Element
            pageExpects ( -> node1.tagName ), 'toEqual', 'HR'
            pageExpects ( -> node1.childNodes.length ), 'toEqual', 0
            pageExpects ( -> node1.attributes.length ), 'toEqual', 2
            pageExpects ( -> node1.attributes[0].name ), 'toEqual', 'class'
            pageExpects ( -> node1.attributes[0].value ), 'toEqual', 'y'
            pageExpects ( -> node1.attributes[1].name ),
                'toEqual', 'whatever'
            pageExpects ( -> node1.attributes[1].value ), 'toEqual', 'dude'
            pageExpects -> node2 instanceof Node
            pageExpects -> node2 not instanceof Text
            pageExpects -> node2 not instanceof Comment
            pageExpects -> node2 instanceof Element
            pageExpects ( -> node2.tagName ), 'toEqual', 'BR'
            pageExpects ( -> node2.childNodes.length ), 'toEqual', 0
            pageExpects ( -> node2.attributes.length ), 'toEqual', 1
            pageExpects ( -> node2.attributes[0].name ), 'toEqual', 'id'
            pageExpects ( -> node2.attributes[0].value ), 'toEqual', '24601'

### should build depth-one DOM trees

        it 'should build depth-one DOM trees', inPage ->

This test is simply the inverse of the analogous test earlier. Depth-one
trees are those that are objects with a children array, no child of which
has any children itself.  We test with one that uses verbose notation and
one using non-verbose.  In each case, some of the parts have attributes and
some don't.

            pageExpects ( ->
                node = Node.fromJSON
                    t : 'I'
                    c : [
                        'non-bold stuff, followed by '
                    ,
                        t : 'B'
                        a : class : 'C', id : '123'
                        c : 'bold stuff'
                    ]
                node.outerHTML
            ), 'toEqual',
                '<i>non-bold stuff, followed by ' +
                '<b class="C" id="123">bold stuff</b></i>'
            pageExpects ( ->
                node = Node.fromJSON {
                    tagName : 'p'
                    attributes :
                        style : 'border: 1px solid gray;'
                        width : '100%'
                    children : [
                        tagName : 'span'
                        children : [ 'some text' ]
                    ,
                        tagName : 'span'
                        children : [ 'yup, more text' ]
                    ]
                }
                node.outerHTML
            ), 'toEqual',
                '<p style="border: 1px solid gray;" width="100%">' +
                '<span>some text</span><span>yup, more text</span></p>'

### should build deep DOM trees

        it 'should build deep DOM trees', inPage ->

This test is simply the inverse of the analogous test earlier. The routines
for building DOM trees from JSON objects should be able to create
many-level, nested structures.  Here I mix verbose and non-verbose notation
in one, large test, to be sure that this works.

            pageExpects ( ->
                node = Node.fromJSON
                    t : 'div'
                    a : class : 'navigation', width : '600'
                    c : [
                        t : 'div'
                        a : id : 'paragraph1'
                        c : [
                            t : 'span', c : [ 'Start paragraph 1.' ]
                        ,
                            t : 'span', c : [ 'Middle paragraph 1.' ]
                        ,
                            t : 'span', c : [ 'End paragraph 1.' ]
                        ]
                    ,
                        tagName : 'div'
                        attributes :
                            id : 'paragraph2', style : 'padding : 5px;'
                        children : [
                            tagName : 'span'
                            children : [ t : 'span', c : [ 'way inside' ] ]
                        ]
                    ]
                node.outerHTML
            ), 'toEqual',
                '<div class="navigation" width="600">' +
                '<div id="paragraph1">' +
                '<span>Start paragraph 1.</span>' +
                '<span>Middle paragraph 1.</span>' +
                '<span>End paragraph 1.</span></div>' +
                '<div id="paragraph2" ' +
                'style="padding : 5px;"><span><span>' +
                'way inside</span></span></div></div>'

### should work in the iframe also

We repeat a small subset of the above tests inside the TinyMCE editor's
iframe, to ensure that the tools are working there as well.

        it 'should work in the iframe also', inPage ->
            pageExpects -> tinymce.activeEditor.getWin().Node.fromJSON
            pageDo -> window.node = Node.fromJSON 'just a string'
            pageExpects -> node instanceof Node
            pageExpects -> node instanceof Text
            pageExpects -> node not instanceof Comment
            pageExpects -> node not instanceof Element
            pageExpects ( -> node.textContent ), 'toEqual', 'just a string'

## leaf navigation in Node class

The tests in this section test the `nextLeaf` and `previousLeaf` member
functions in the `Node` prototype. [See their definition here.](
domutils.litcoffee.html#next-and-previous-leaves).

    phantomDescribe 'leaf navigation in Node class',
    './app/app.html', ->

### should be defined

First, just verify that both functions are present.

        it 'should be defined', inPage ->
            pageExpects -> Node::nextLeaf
            pageExpects -> Node::previousLeaf

### should work among sibling leaves

        it 'should work among sibling leaves', inPage ->

We test the simplest case, when we call the functions on leaf nodes who have
immediate sibling nodes that are also leaves, and thus which should be
returned by the functions.  We work within the following environment.

            pageDo ->
                window.div =
                    tinymce.activeEditor.getDoc().createElement 'div'
                div.innerHTML = 'A section of text.
                                 <br><hr>Yet more text.'

First, verify that these tests are being run where we think they are.

            pageExpects ->
                div.ownerDocument is tinymce.activeEditor.getDoc()
            pageExpects ->
                div instanceof tinymce.activeEditor.getWin().Element

Within the div we find just four leaf nodes.  Let's ensure that the
functions work correctly among those four.

            pageExpects -> div.childNodes[0].nextLeaf() is div.childNodes[1]
            pageExpects -> div.childNodes[1].nextLeaf() is div.childNodes[2]
            pageExpects -> div.childNodes[2].nextLeaf() is div.childNodes[3]
            pageExpects -> div.childNodes[3].nextLeaf() is null
            pageExpects -> div.childNodes[0].previousLeaf() is null
            pageExpects ->
                div.childNodes[1].previousLeaf() is div.childNodes[0]
            pageExpects ->
                div.childNodes[2].previousLeaf() is div.childNodes[1]
            pageExpects ->
                div.childNodes[3].previousLeaf() is div.childNodes[2]

### should work in larger hierarchies

        it 'should work in larger hierarchies', inPage ->

We test a few more advanced example cases here, where the navigation is not
merely among sibling leaves.  We work with the following DOM structure.

            pageDo ->
                window.div =
                    tinymce.activeEditor.getDoc().createElement 'div'
                div.innerHTML = '<span>Text in a span</span>' + \
                                '<span>Text <i>italic</i></span>' + \
                                '<span><span>Nested</span>' + \
                                      '<span>spans</span></span>'

Within the div we select several leaves and give them natural names for
convenience in comparison.

            pageDo ->
                window.textInASpan = div.childNodes[0].childNodes[0]
                window.text = div.childNodes[1].childNodes[0]
                window.italic =
                    div.childNodes[1].childNodes[1].childNodes[0]
                window.nested =
                    div.childNodes[2].childNodes[0].childNodes[0]
                window.spans = div.childNodes[2].childNodes[1].childNodes[0]

Next, verify that these tests are being run where we think they are.

            pageExpects ->
                div.ownerDocument is tinymce.activeEditor.getDoc()
            pageExpects ->
                div instanceof tinymce.activeEditor.getWin().Element
            pageExpects ->
                text instanceof tinymce.activeEditor.getWin().Text

Now verify that moving among those leaves works as expected.

            pageExpects -> textInASpan.nextLeaf() is text
            pageExpects -> text.nextLeaf() is italic
            pageExpects -> italic.nextLeaf() is nested
            pageExpects -> nested.nextLeaf() is spans
            pageExpects -> spans.nextLeaf() is null
            pageExpects -> spans.previousLeaf() is nested
            pageExpects -> nested.previousLeaf() is italic
            pageExpects -> italic.previousLeaf() is text
            pageExpects -> text.previousLeaf() is textInASpan

Give names to some of their parents and grandparents, and check leaf
navigation from those higher-level nodes as well.

            pageDo ->
                window.outerSpan1 = textInASpan.parentNode
                window.outerSpan2 = text.parentNode
                window.innerSpan1 = nested.parentNode
                window.innerSpan2 = spans.parentNode
                window.outerSpan3 = innerSpan1.parentNode
            pageExpects -> outerSpan1.previousLeaf() is null
            pageExpects -> outerSpan1.nextLeaf() is text
            pageExpects -> outerSpan2.previousLeaf() is textInASpan
            pageExpects -> outerSpan2.nextLeaf() is nested
            pageExpects -> outerSpan3.previousLeaf() is italic
            pageExpects -> outerSpan3.nextLeaf() is null
            pageExpects -> innerSpan1.previousLeaf() is italic
            pageExpects -> innerSpan1.nextLeaf() is spans
            pageExpects -> innerSpan2.previousLeaf() is nested
            pageExpects -> innerSpan2.nextLeaf() is null

## This Unit Test Incomplete

We need to add here unit tests for the following functions:

 * `Node.remove()`
 * `Element::hasClass()`
 * `Element::addClass()`
 * `Element::removeClass()`

Alternately, we need to simply rely on jQuery for those features, and
remove from the codebase all reference to the versions defined in
[the DOMUtils module](../src/domutils.litcoffee).
