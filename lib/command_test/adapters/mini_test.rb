module CommandTest
  module Adapters
    module MiniTest
      module Assertions
        #
        # Passes if the block runs the given command.
        #
        #     assert_runs_command 'convert', 'evil.gif', 'good.png' do
        #       ...
        #     end
        #
        # Commands are matched according to CommandTest.match? .
        #
        def assert_runs_command(*expected, &block)
          result = Tests::RunsCommand.new(expected, &block)
          matches = result.matches?
          assert matches, result.positive_failure_message
        end

        def assert_catches_command(*expected, &block)
          result = Tests::RunsCommand.new(expected, true, &block)
          matches = result.matches?
          assert matches, result.positive_failure_message
        end

        #
        # Passes if the block does not run the given command.
        #
        #     assert_does_not_run_command 'convert', 'evil.gif', 'good.png' do
        #       ...
        #     end
        #
        # Commands are matched according to CommandTest.match? .
        #
        def assert_does_not_run_command(*expected, &block)
          result = Tests::RunsCommand.new(expected, &block)
          matches = result.matches?
          assert_block(matches ? result.negative_failure_message : nil) do
            !matches
          end
        end
      end

      ::MiniTest::Unit::TestCase.send :include, Assertions
    end
  end
end
