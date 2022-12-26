-- @module Syntax
-- @moduleCommentStart
-- Syntax for Nutscript documentation.
-- @moduleCommentEnd

-- @type command module
-- @typeCommentStart
-- The !@module rule is used to declare the module name. This should be placed at the top of a file.
-- @typeCommentEnd
-- @string Title Required. Module title.
-- @usageStart
-- !@module Syntax
-- @usageEnd
module (string Title) 

--[[
@type command moduleComment
@typeCommentStart
The !@moduleCommentStart and !@moduleCommentEnd commands declare the beginning and end of the module comment.
They should contain all comment material between the commands, not on the same line. This should only be used once per file.
@typeCommentEnd
@string Comment Required. Module comment.
@usageStart
!@moduleCommentStart
Syntax for Nutscript documentation.
!@moduleCommentEnd
@usageEnd
]]
moduleCommentStart 
(string Comment)
moduleCommentEnd 

--[[
@type command classmod
@typeCommentStart
The !@classmod declares a type is part of a named class. This overrides the pages !@module declaration.
Additionally, this will categorize the type into the class category, rather than the category corresponding to the !@module declaration.
@typeCommentEnd
@string Title Required. Module title.
@usageStart
!@classmod Character
@usageEnd
]]
classmod (string Title)

--[[
@type command type
@typeCommentStart
The !@type command declares a datatype (e.g., 'function', 'method', 'table' etc.) and a name (e.g., nut.item.get(params)).
It is critical that this is the first declaration in naming a function (i.e., all other data specific to the type should follow.).
@typeCommentEnd
@string Datatype Required. Data type: function, method, table etc.
@string Name Required. The function or method name: nut.item.get(); Character:get().
@usageStart
!@type function nut.item.isItem(object)
@usageEnd
]]
type (string Datatype) (string Name)

--[[
@type command typeComment
@typeCommentStart
The !@typeCommentStart and !@typeCommentEnd commands are used to declare a type comment. This works in the same way as the moduleComment commands.
The type comment should be declared sometime after a !@type declaration.
@typeCommentEnd
@string Comment Required. Type comment.
@usageStart
!@typeCommentStart
Returns whether input is an item object or not.
!@typeCommentEnd
@usageEnd
]]
typeCommentStart 
(string Comment) 
typeCommentEnd

--[[
@type command realm
@typeCommentStart
The !@realm command is used to declare a realm type, (e.g., shared, server, or client).
@typeCommentEnd
@string Realm Required. Realm type.
@usageStart
!@realm shared
@usageEnd
]]
realm (string Realm)

--[[
@type command internal
@typeCommentStart
The !@internal command is used to specify an internal function, method, or table.
The command is not necessary if the item is not internal.
@typeCommentEnd
@usageStart
!@internal
@usageEnd
]]
internal

--[[
@type command param
@typeCommentStart
Any string which has '!@' in front of it and is not written on this page will be treated as a parameter.
Parameters can be given a default value using the [default=<value>] command.
@typeCommentEnd
@string Param Required. Param type (e.g., string, table, int).
@string default Optional. Param default value.
@string Label Required. Param label.
@string Description Required. Param description.
@usageStart
!@string path Path of the item file.
!@table object Object to check
!@int[default=1] number Number value.
!@bool[default=false] isBaseItem Whether the item is a base item
@usageEnd
]]
Param[default=DEFAULT] (string Label) (string Description)

--[[
@type command treturn
@typeCommentStart
The !@treturn command is used to specify a return value.
@typeCommentEnd
@string Label Required. Return label.
@string Description Required. Return description.
@usageStart
!@treturn item Item table
@usageEnd
]]
treturn (string Label) (string Description)

--[[
@type command usage
@typeCommentStart
The !@usageStart and !@usageEnd commands are used to specify a block of example code.
This works in the same way as the moduleComment and typeComment commands. This is an optional command.
@typeCommentEnd
@string Example Optional. Example code.
@usageStart
!@usageStart
nut.item.register("example", "base_food", false, "sh_example.lua", false)
!@usageEnd
@usageEnd
]]
usageStart 
(string Example) 
usageEnd