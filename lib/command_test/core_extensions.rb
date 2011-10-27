require 'open3'

module CommandTest
  module CoreExtensions
    def self.define_included_hook(mod, *methods) # :nodoc:
      name_map = methods.last.is_a?(Hash) ? methods.pop : {}
      methods.each{|m| name_map[m] = m}
      aliasings = name_map.map do |name, massaged|
        <<-EOS
          unless method_defined?(:#{massaged}_without_command_test)
            alias #{massaged}_without_command_test #{name}
            alias #{name} #{massaged}_with_command_test
          end
        EOS
      end.join("\n")

      mod.module_eval <<-EOS
        def self.included(base)
          base.module_eval do
            #{aliasings}
          end
        end

        def self.extended(base)
          included((class << base; self; end))
        end
      EOS
    end

    module Kernel
      def system_with_command_test(*args, &block)
        continue, match, success = CommandTest.record_command(*args)
        if continue
          success.call if match
          system_without_command_test(*args, &block)
        else
          system_without_command_test('true', &block)
        end
      end

      def backtick_with_command_test(*args, &block)
        if command = args.first
          continue, match, success = CommandTest.record_interpreted_command(command)
        end
        if continue
          success.call if match
          backtick_without_command_test(*args, &block)
        else
          backtick_without_command_test('true', &block)
        end
      end

      def open_with_command_test(*args, &block)
        if (command = args.first) && command =~ /\A\|/
          continue, match, success = CommandTest.record_interpreted_command($')
          if !continue
            success.call if match
            return open_without_command_test('|true', &block)
          end
        end
        open_without_command_test(*args, &block)
      end

      def spawn_with_command_test(*args, &block)
        continue, match, success = CommandTest.record_command(*args)
        if continue
          spawn_without_command_test(*args, &block)
        else
          success.call if match
          spawn_without_command_test('true', &block)
        end
      end
    end

    define_included_hook(Kernel, :system, :open, :spawn, :'`' => :backtick)
    ::Kernel.send :include, Kernel
    ::Kernel.send :extend, Kernel

    module IO
      def popen_with_command_test(*args, &block)
        if command = args.first
          continue, match, success = CommandTest.record_interpreted_command(command)
        end
        if continue
          popen_without_command_test(*args, &block)
        else
          success.call if match
          popen_without_command_test('true', &block)
        end
      end
    end

    define_included_hook(IO, :popen)
    ::IO.send :extend, IO
  end
end
