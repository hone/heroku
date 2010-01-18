require 'rest_client'
# based on the Rails Plugin

module Heroku
	class Plugin
        HEROCUTTER_URL = "http://herocutter.heroku.com"

		class << self
			include Heroku::Helpers
		end

		attr_reader :name, :uri

		def self.directory
			"#{home_directory}/.heroku/plugins"
		end

		def self.list
			Dir["#{directory}/*"].map do |folder|
				File.basename(folder)
			end
		end

		def self.load!
			list.each do |plugin|
				folder = "#{self.directory}/#{plugin}"
				$: << "#{folder}/lib"    if File.directory? "#{folder}/lib"
				load "#{folder}/init.rb" if File.exists?    "#{folder}/init.rb"
			end
		end

		def initialize(uri)
			@uri = uri
			guess_name(uri)
		end

		def to_s
			name
		end

		def path
			"#{self.class.directory}/#{name}"
		end

		def install
			FileUtils.mkdir_p(path)
			Dir.chdir(path) do
				system("git init > /dev/null 2>&1")
				if !system("git pull --depth 1 #{fetch_git_uri(uri)}  > /dev/null 2>&1")
					FileUtils.rm_rf path
					return false
				end
			end
			true
		end

		def uninstall
			FileUtils.rm_r path if File.directory?(path)
		end

		private 
			def guess_name(url)
				@name = File.basename(url)
				@name = File.basename(File.dirname(url)) if @name.empty?
				@name.gsub!(/\.git$/, '') if @name =~ /\.git$/
			end

      # determine if they passed in a plugin name or uri
      # return the uri if found on herocutter
      def fetch_git_uri(name, herocutter_url = HEROCUTTER_URL)
        begin
          json = JSON.parse(RestClient.get("#{herocutter_url}/plugins/#{name}.json"))
        rescue
          return name
        end

        if json['error'].nil? and json['plugin']['uri']
          json['plugin']['uri']
        else
          name
        end
      end
	end
end
