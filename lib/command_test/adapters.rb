require 'command_test/adapters/rspec' if Object.const_defined?(:Spec)
require 'command_test/adapters/test_unit' if Object.const_defined?(:Test) && Test.const_defined?(:Unit)
require 'command_test/adapters/mini_test' if Object.const_defined?(:MiniTest) && MiniTest.const_defined?(:Unit)
