# BlockComment

Xcode 8 source editor extension for Swift editing that will insert a block comment, possibly with some tags.

![](screenshot.gif)

The command does a rudimentary scan forward from the cursor, looking for something to comment. If it finds a
`func` or `init` expression, it will insert a block comment describing the function definition. It also has
tailored block comments for `struct`, `class`, `enum` and propertie expressions (`var` and `let`). Again, it is
really crude and basic. If it cannot make sense of anthing, it will just punt and insert a generic block
comment.

The block comments have Xcode tags (text delimited by '<#' and '#>') which allow one to tab to a tag and start
typing to replace the tag with text.

# To Use

Build the main `BlockCommentApp`. This will also build the `BlockCommentCommand.appex` extension. Run the app,
and you should now have the extension installed. May need a restart of Xcode before the extension appears.

![](menu.png)

Place cursor before the entity to document, then select the `Insert` menu command (or assign a key shortcut in
Xcode preferences

## Things To Do

- Improve type handling (e.g. function types)
- Position cursor at first tag (how?)
- Honor tab vs. spaces preference setting
- A 'document entire file' command?
- Update comment when function prototype changes? (merge)
