--[[
  InternalMethods.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-11-XX

  This module provides internal methods for manipulating AST nodes.
--]]

-- Import necessary functions from the Lua standard library
local insert = table.insert
local remove = table.remove
local concat = table.concat

-- Create a table to store the internal methods
local InternalMethods = {}

-- Retrieve the internal data of a node
function InternalMethods:getInternals(node, _internal)
  return _internal
end

-- Retrieve a specific internal field of a node
function InternalMethods:getInternalField(node, _internal, field)
  return _internal[field]
end

-- Set the value of a specific internal field of a node
function InternalMethods:setInternalField(node, _internal, field, value)
  _internal[field] = value
end

-- Get parent of a node
function InternalMethods:getParent(node, _internal)
  return _internal.parent
end

-- Set parent of a node
function InternalMethods:setParent(node, _internal, parent)
  _internal.parent = parent
end

-- Get index of a node
function InternalMethods:getIndex(node, _internal)
  return _internal.index
end

-- Set index of a node
function InternalMethods:setIndex(node, _internal, index)
  _internal.index = index
end

-- Get the path of a node in the tree structure
function InternalMethods:getPath(node, _internal)
  local path = {}
  local currentNode = node

  -- Traverse the tree structure from the current node to the root
  while currentNode do
    local parent = currentNode._methods:getInternalField("parent")
    local index = currentNode._methods:getInternalField("index")

    -- If the current node has a parent, add it to the path
    if parent then
      insert(path, parent.TYPE .. "[" .. tostring(index) .. "]")
    else break end

    -- Move to the parent node
    currentNode = parent
  end

  -- Concatenate the path elements into a string representation
  return concat(path, "->")
end

-- Get the children of a node
function InternalMethods:getChildren(node, _internal)
  local children = {}
  local fieldTypeFunctions = {}

  -- Function to handle Node type fields
  fieldTypeFunctions.Node = function(node, index)
    insert(children, node)
  end

  -- Node lists are also considered as nodes, so we need to add them to the children list
  fieldTypeFunctions.NodeList = function(node, index)
    insert(children, node)
  end

  -- Traverse the node and call the appropriate field type function
  self:traverseNode(node, fieldTypeFunctions)

  return children
end

-- Get the descendants of a node
function InternalMethods:getDescendants(node, _internal)
  local descendants = {}
  local fieldTypeFunctions = {}

  -- Function to handle Node type fields
  fieldTypeFunctions.Node = function(node, index)
    insert(descendants, node)

    -- Recursively traverse the descendants of the current node
    self:traverseNode(node, fieldTypeFunctions)
  end

  -- Node lists are also considered as nodes, so we need to add them to the descendants list
  fieldTypeFunctions.NodeList = function(node, index)
    insert(descendants, node)

    -- Recursively traverse the descendants of the current node list
    self:traverseNode(node, fieldTypeFunctions)
  end

  -- Traverse the node and call the appropriate field type function
  self:traverseNode(node, fieldTypeFunctions)

  return descendants
end

-- Traverse ancestors of a node with a custom function
-- It stops traversing when the function returns "false"
function InternalMethods:traverseParents(node, func)
  local currentNode = node
  local results = {}

  while currentNode do
    local result = func(currentNode)
    if result then
      insert(results, result)
    elseif result == false then
      break
    end
    currentNode = currentNode._methods:getInternalField("parent")
  end

  return results
end

-- Return the InternalMethods table
return InternalMethods