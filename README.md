# Swocks -- Swift Block Comments

Xcode 8+ source editor extension for Swift editing that will insert a block comment, possibly with some tags.

> **NOTE**: I know about Xcode's own `Add Documentation` command which does the same thing, but with more
> knowledge about the code being commented on. This was more of a learning exercise. I also like my style of
> comments over Xcode's use of '///' everywhere.

![](https://github.com/bradhowes/BlockComment/blob/main/images/screenshot.gif?raw=true)

The command does a rudimentary scan forward from the cursor, looking for something to comment. If it finds a
`func` or `init` expression, it will insert a block comment describing the function definition. It also has
tailored block comments for `struct`, `class`, `enum` and property expressions (`var` and `let`). Again, it is
really crude and basic. If it cannot make sense of anything, it will just punt and insert a generic block
comment.

The block comments have Xcode tags (text delimited by '<#' and '#>') which allow one to tab to a tag and start
typing to replace the tag with text.

# Note on Version 3

Version 3 includes a completely rewritten parser that is primarily functional in design. It is based on ideas discussed in the
excellent videos put out by the [POINT•FREE](https://www.pointfree.co) team. You can see the playgrounds they discuss on 
their [Github repo](https://github.com/pointfreeco/episode-code-samples) -- in particular see playgrounds 0056 - 0064.

I used their fundamental design but retooled it to work outside of a playground, and I extended it to of course handle Swift 
parsing. Be aware that when I say it parses Swift,
it only does so in the most basic way to uncover the interesting features to include in a block comment. It would take quite 
some effort to accurately parse the Swift language.

# To Use

Build the main `BlockCommentApp`. This will also build the `BlockComment.appex` extension. Run the app,
and follow the instructions presented to you. 

![](https://github.com/bradhowes/BlockComment/blob/main/images/app.png?raw=true)

Extension should be available after a restart of Xcode.  NOTE: if you are reinstalling or upgrading, probably best to remove the old version 
*first* by moving to trash and then emptying the trash.

![](https://github.com/bradhowes/BlockComment/blob/main/images/menu.png?raw=true)

Place cursor before the entity to document, then select the `Block Comment` menu command (or assign a key shortcut in
Xcode preferences. There is also a dumb `Mark Comment` that just inserts

```
// MARK: - <#Description#>
```

to insert a horizontal divider and title in the pop-down list of interesting items.

![](https://github.com/bradhowes/BlockComment/blob/main/images/mark.png?raw=true)


# Code

The code parsing takes place in
[BlockCommentExtension/SwiftParsing.swift](https://github.com/bradhowes/BlockComment/blob/main/BlockCommentExtension/SwiftParsing.swift). The code starts with the
fundamental bits and builds on them primarily via the `zip` and `first` functions.
The processing of the request from Xcode happens in
[BlockCommentExtension/BlockCommentCommand.swift](https://github.com/bradhowes/BlockComment/blob/main/BlockCommentExtension/BlockCommentCommand.swift). More general parsing
functions are found in [BlockCommentExtension/Parse.swift](https://github.com/bradhowes/BlockComment/blob/main/BlockCommentExtension/Parse.swift) and
the Parser generic struct is found in [BlockCommentExtension/Parser.swift](https://github.com/bradhowes/BlockComment/blob/main/BlockCommentExtension/Parser.swift).

