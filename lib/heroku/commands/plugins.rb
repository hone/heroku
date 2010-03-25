module Heroku::Command
  class Plugins < Base
    def list
      ::Heroku::Plugin.list.each do |plugin|
        display plugin
      end
    end
    alias :index :list

    def install
      plugin = Heroku::Plugin.new(args.shift)
      if plugin.install
        display "#{plugin} installed"
      else
        error "Could not install #{plugin}. Please check the URL and try again"
      end
    end

    def uninstall
      plugin = Heroku::Plugin.new(args.shift)
      plugin.uninstall
      display "#{plugin} uninstalled"
    end

    def update
      ::Heroku::Plugin.list.each do |plugin_path|
        md = /URL: (.+)$/.match(`cd #{plugin_path} && git remote show origin -n | grep URL`)

        if md[1] != "origin" # means there isn't an origin
          plugin = Heroku::Plugin.new(md[1])
          if plugin.update
            display "Successfully updated: #{plugin.name}"
          else
            display "Could not update: #{plugin.name}"
          end
        else
          display "Please reinstall, no remote for #{plugin_path}"
        end
      end
    end
  end
end
