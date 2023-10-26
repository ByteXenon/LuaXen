--[[
  Name: Tests.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-10-XX
  All Rights Reserved.
--]]

--* Dependencies *--
local TestsHelpers = require("tests/TestsHelpers")

--* Export library functions *--
local unpack = (unpack or table.unpack)
local insert = table.insert
local printTable = TestsHelpers.printTable
local tablesEqual = TestsHelpers.tablesEqual
local getTableDifferences = TestsHelpers.getTableDifferences
local printTableDifferences = TestsHelpers.printTableDifferences

--* Tests *--
local Tests = {}
function Tests:new(configurationFilePath)
  local TestsInstance = {}
  TestsInstance.temporaryStorage = {}
  TestsInstance.globalEvents = {}
  -- Load the file with information about tests
  TestsInstance.configurationData = require(configurationFilePath)

  -- Helper function to handle value retrieval based on its type
  function TestsInstance:getValueByType(valueTable)
    local valueType = valueTable.type or "lua"
    if valueType == "lua" then
      return valueTable
    elseif valueType == "storage" then
      return self.temporaryStorage[valueTable.key]
    elseif valueType == "function" then
      return valueTable.value(self)
    else
      error("[UNIT TESTS]: Unsupported value type: " .. tostring(valueType))
    end
  end

  -- Function to get a value from a table or directly if non-table values are allowed
  function TestsInstance:getValue(valueTable, nonTableValuesAllowed)
    if nonTableValuesAllowed and type(valueTable) ~= "table" then
      return valueTable
    end
    return self:getValueByType(valueTable)
  end

  -- Function to set a value in the temporary storage
  function TestsInstance:setValue(valueTable)
    local valueType = valueTable.type or "storage"
    if valueType == "storage" then
      self.temporaryStorage[valueTable.key] = self:getValue(valueTable.value)
    else
      error("[UNIT TESTS]: Unsupported value type: " .. tostring(valueType))
    end
  end

  -- Function to get values from a table or directly if non-table values are allowed
  function TestsInstance:getValues(values, nonTableValuesAllowed)
    if nonTableValuesAllowed and type(values) ~= "table" then
      return { values }
    elseif values.type then
      return { self:getValue(values) }
    end

    local actualValues = {}
    for _, valueTable in ipairs(values) do
      table.insert(actualValues, self:getValue(valueTable, true))
    end
    return actualValues
  end

  -- Function to set values in the temporary storage from a table of values
  function TestsInstance:setValues(values)
    for _, valueTable in ipairs(values) do
      self:setValue(valueTable)
    end
  end

  function TestsInstance:performStaticModuleTests()

  end

  -- Helper function to handle test events
  local function handleTestEvents(testEvents, eventType, moduleInstance, self)
    if testEvents and testEvents[eventType] then
      if type(testEvents[eventType]) == "function" then
        -- testEventseventType
      elseif type(testEvents[eventType]) == "string" then
        self.globalEvents[testEvents[eventType]](moduleInstance, self)
      else
        error("Invalid test event type: " .. type(testEvents[eventType]))
      end
    end
  end

  -- Helper function to execute the function under test
  local function executeFunctionUnderTest(functionValue, callWithoutSelf, functionParameters, moduleInstance)
    local pcallReturnValues;
    if callWithoutSelf then
      pcallReturnValues = {pcall(functionValue, unpack(functionParameters))}
    else
      pcallReturnValues = {pcall(functionValue, moduleInstance, unpack(functionParameters))}
    end
    return pcallReturnValues[1], { select(2, unpack(pcallReturnValues)) }
  end

  -- Main function to perform instance module tests
  function TestsInstance:performInstanceModuleTests()
    local configData = self.configurationData

    -- Load the new module
    local newModule = require(configData.moduleLocation)

    local newInstanceMethod = configData.newInstanceMethod
    local initializationParameters = self:getValues(configData.initializationParameters)

    -- Function to initialize a new instance of the module
    local function initializeModuleInstance()
      return newModule[newInstanceMethod or "new"](newModule, unpack(initializationParameters))
    end

    -- Initialize the first instance of the module
    local moduleInstance = initializeModuleInstance()

    -- Iterate over each unit test
    for _, testTable in ipairs(configData.unitTests) do
      if not testTable.skipTest then

        -- Re-initialize the module instance if required by the test case
        if testTable.requireNewInstance then moduleInstance = initializeModuleInstance() end

        -- Handle 'beforeTestStarts' event if it exists
        handleTestEvents(testTable.testEvents, 'beforeTestStarts', moduleInstance, self)

        -- Execute the function under test and get the return values
        local success, returnValues = executeFunctionUnderTest(
                                                                moduleInstance[testTable.functionUnderTest],
                                                                testTable.callWithoutSelf,
                                                                self:getValues(testTable.functionParameters, true),
                                                                moduleInstance
                                                              )

        -- If execution was not successful, throw an error with the returned message
        if not success then return error("[UNIT TESTS]: Error: " .. tostring(returnValues[1])) end

        -- Compare the returned values with the expected outcome
        local tableDifferences = getTableDifferences(returnValues, self:getValues(testTable.expectedOutcome, true))

        -- If there are differences between returned and expected values, print them out and mark the test as failed
        if tableDifferences and tableDifferences.areDifferent then
          print("[UNIT TESTS]: Test '" .. tostring(testTable.testName) .. "' return values differences:")
          printTableDifferences(tableDifferences)
          print("[UNIT TESTS]: Test: " .. tostring(testTable.testName) .. " fail")
        else
          -- If there are no differences in returned values but there are state checks to be made after the test,
          -- perform those checks and print out any discrepancies.
          if testTable.checkStateAfterTest then
            for _, value in pairs(testTable.checkStateAfterTest) do
              local key = value.key
              local expectedValue = self:getValue(value.expectedValue)
              if moduleInstance[key] ~= expectedValue then
                print(("[UNIT TESTS]: State index %s, expected: %s, got: %s")
                      :format(tostring(key), tostring(expectedValue), tostring(moduleInstance[key])))
              end
            end
          else
            -- If there are no discrepancies in returned values or state checks after the test,
            -- mark the test as passed.
            print("[UNIT TESTS]: Test: " .. tostring(testTable.testName) .. " pass")
          end
        end
      end
    end
  end

  function TestsInstance:performTests()
    -- Extract configuration data and initialize temporary storage if not present
    local configData = self.configurationData
    configData.temporaryStorage = configData.temporaryStorage or {}

    -- Assign test events to global events
    for index, func in pairs(configData.testEvents or {}) do
      self.globalEvents[index] = func
    end

    -- Perform tests based on the type of the test subject
    local testSubjectType = configData.testSubjectType
    if testSubjectType == "StaticModule" then
      return self:performStaticModuleTests()
    elseif testSubjectType == "InstanceModule" then
      return self:performInstanceModuleTests()
    elseif testSubjectType == "Function" then
       return self:performFunctionTests()
    else
      error("[UNIT TESTS]: Invalid testSubjectType: " .. tostring(testSubjectType))
    end
  end

  return TestsInstance
end

return Tests