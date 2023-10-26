return {
  testSubjectType = "InstanceModule", -- or "StaticModule", "Function"
  moduleLocation = "VirtualMachine/VirtualMachine",
  newInstanceMethod = "new",
  initializationParameters = {
    {
      value = "hello, world!",
      type = "lua"
    },
    {
      -- This function will be provide a dynamic value
      value = function()
        return math.random(1, 100)
      end,
      type = "function"
    }
  },

  unitTests = {
    {
      testName = "Test1",
      functionUnderTest = "functionName1",
      callWithoutSelf = false, -- Call the function without "self", optional, default: false
      skipTest = false, -- Skip this test, optional, default: false
      requireNewInstance = false, -- Don't require new module class instance before test, optiona, default: false
      functionParameters = {
        {
          value = "hi!",
          type = "lua"
        },
        {
          key = "arg2",
          type = "storage"
        }
      },
      expectedOutcome = {
        {
          "expectedOutput1"
        }
      },
      modifyInternalStateBeforeTest = {
        {
          key = "internalKey1",
          value = {
            key = "newValue1",
            type = "storage"
          }
        }
      },
      modifyInternalStateAfterTest = {
        {
          key = "internalKey2",
          value = {
            value = "newValue2",
            type = "lua"
          }
        }
      },
      checkStateAfterTest = {
        key = "stateKey",
        expectedValue = {
          value = "expectedStateValue",
          type = "lua"
        }
      },
      -- Optional
      testEvents = {
        beforeTestStarts      = "beforeTestStartsEvent",
        afterSuccessfulTest   = "afterSuccessfulTestEvent",
        afterUnsuccessfulTest = "afterUnsuccessfulTestEvent",
        onError = function() end -- Functions are allowed too!
      }
    },
  },

  -- Optional
  testEvents = {
    beforeTestStartsEvent      = function() end,
    afterSuccessfulTestEvent   = function() end,
    afterUnsuccessfulTestEvent = function() end,
    onError                    = function() end
  },

  -- Optional, will be created automatically by default.
  temporaryStorage = {}
}