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
        if CommandTest.record_command(*args)
          system_without_command_test('true', &block)
        else
          system_without_command_test(*args, &block)
        end
      end

      def backtick_with_command_test(*args, &block)
        if command = args.first and
          CommandTest.record_interpreted_command(command)
          backtick_without_command_test('true', &block)
        else
          backtick_without_command_test(*args, &block)
        end
      end

      def open_with_command_test(*args, &block)
        if (command = args.first) && command =~ /\A\|/ and
          CommandTest.record_interpreted_command($')
          open_without_command_test('|true', &block)
        else
          open_without_command_test(*args, &block)
        end
      end

      def spawn_with_command_test(*args, &block)
        if CommandTest.record_command(*args)
          spawn_without_command_test('true', &block)
        else
          spawn_without_command_test(*args, &block)
        end
      end
    end

    define_included_hook(Kernel, :system, :open, :spawn, :'`' => :backtick)
    ::Kernel.send :include, Kernel
    ::Kernel.send :extend, Kernel

    module IO
      def popen_with_command_test(*args, &block)
        if command = args.first and
          CommandTest.record_interpreted_command(command)
          popen_without_command_test('true', &block)
        else
          popen_without_command_test(*args, &block)
        end
      end
    end

    define_included_hook(IO, :popen)
    ::IO.send :extend, IO
  end
end
