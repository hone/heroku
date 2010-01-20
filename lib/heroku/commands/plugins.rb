require 'restclient'
require 'yaml'

module Heroku::Command
	class Plugins < Base
    HEROCUTTER_URL = "http://herocutter.heroku.com"

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

    def push
      begin
        yaml = YAML.load_file(herocutter_file)
      rescue Errno::ENOENT
        api_key_error
        return
      end

      if yaml['api_key'].nil?
        api_key_error
        return
      end
      uri = args[0]
      name = args[1]

      if uri.nil?
        uri = prepare_uri_from_git_origin
        github_uri_rewrite!(uri)
      end
      if uri and not uri.empty?
        response = JSON.parse(RestClient.post("#{HEROCUTTER_URL}/plugins", :api_key => yaml['api_key'], :plugin => {:uri => uri, :name => name}, :format => 'json'))
        if response and response['error']
          push_plugin_error
        else
          display "pushed plugin with uri: #{uri}"
        end
      else
        push_plugin_error
        return
      end

      uri
    end

    private
    def herocutter_file
      "#{home_directory}/.heroku/herocutter"
    end

    def api_key_error
      error "Could not find file #{herocutter_file}. Please check http://herocutter.heroku.com/profile"
    end

    def push_plugin_error
      error "Could not push plugin, check your API key.  See http://herocutter.heroku.com/profile for more info"
    end

    def git_remote_show_origin
      `git remote show origin | grep URL`
    end

    def github_uri_rewrite!(uri)
      if /git@github.com/.match(uri)
        uri.sub!("git@github.com:", "git://github.com/")
      end
    end

    def prepare_uri_from_git_origin
      uri = git_remote_show_origin
      if uri and /URL: /.match(uri)
        uri = uri.split("URL: ").last.chomp
      end

      uri
    end
	end
end
