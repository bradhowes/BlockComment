# BlockComment

Xcode 8 source editor extension for Swift editing that will insert a block comment, possibly with some tags.

The command does a rudimentary scan forward from the cursor, looking for something to comment. If it finds a
`func` or `init` expression, it will insert a block comment describing the function definition. It also has
tailored block comments for `struct`, `class`, `enum` and propertie expressions (`var` and `let`). Again, it is
really crude and basic. If it cannot make sense of anthing, it will just punt and insert a generic block
comment.

The block comments have Xcode tags (text delimited by '<#' and '#>') which allow one to tab to a tag and start
typing to replace the tag with text.

## Things To Do

- Improve type handling (e.g. function types)
- Position cursor at first tag (how?)


