module Heroku
  class RackConsoleEnvironment
    def create_binding
      # handle any loading errors
      begin
        load 'config.ru'
      rescue
        $stderr.puts $!
      end

      Kernel.binding
    end
  end

  class RailsConsoleEnvironment
    def create_binding
      # handle any loading errors
      begin
        require 'config/boot'
        require 'config/environment'
      rescue
        $stderr.puts $!
      end

      Kernel.binding
    end
  end
end
