return {
  testSubjectType = "InstanceModule",
  moduleLocation = "test2",
  initializationParameters = {
    "print('hello')"
  },

  unitTests = {
    {
      testName = "BASIC_CHECK_001",
      functionUnderTest = "b",
      functionParameters = { "h", "e" },
      expectedOutcome = { {
          { Value = "print", TYPE = "Identifier" },
          { Value = "(",     TYPE = "Character"  },
          { Value = "hello", TYPE = "String"     },
          { Value = ")",     TYPE = "Character"  },
      }
      }
    },
  },

  -- Optional, events don't override control flow of the testing module
  testEvents = {
    beforeTestStartsEvent      = function() end,
    afterSuccessfulTestEvent   = function() end,
    afterUnsuccessfulTestEvent = function() end,
    onError                    = function() end
  },

  -- Optional, will be created automatically by default.
  temporaryStorage = {}
}