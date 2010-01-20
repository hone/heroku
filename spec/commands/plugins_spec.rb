require File.dirname(__FILE__) + '/../base'

module Heroku::Command
	include SandboxHelper

	describe Plugins do
		before do
			@command = prepare_command(Plugins)
			@plugin  = mock('heroku plugin')
		end

		it "installs plugins" do
			@command.stub!(:args).and_return(['git://github.com/heroku/plugin.git'])
			Heroku::Plugin.should_receive(:new).with('git://github.com/heroku/plugin.git').and_return(@plugin)
			@plugin.should_receive(:install).and_return(true)
			@command.install
		end

		it "uninstalls plugins" do
			@command.stub!(:args).and_return(['plugin'])
			Heroku::Plugin.should_receive(:new).with('plugin').and_return(@plugin)
			@plugin.should_receive(:uninstall)
			@command.uninstall
		end

    describe "push" do
      before(:each) do
        RestClient.stub!(:post)
      end

      describe "has no api_key " do
        before(:each) do
          @command.stub!(:args).and_return([])
        end

        describe "file does not exist" do
          before(:each) do
            YAML.stub!(:load_file).and_raise(Errno::ENOENT)
          end

          it "should display an error" do
            @command.should_receive(:error)
            @command.push
          end
        end

        describe "api_key not in the file" do
          before(:each) do
            YAML.stub!(:load_file).and_return(Hash.new)
          end

          it "should display an error" do
            @command.should_receive(:error)
            @command.push
          end
        end
      end

      describe "has a api_key" do
        before(:each) do
          YAML.stub!(:load_file).and_return({'api_key' => '4e169e406114f5ea13264de966a11d8a' })
        end

        describe "using origin remote" do
          describe "origin remote exists" do
            before(:each) do
              @command.stub!(:git_remote_show_origin).and_return("  URL: git@github.com:hone/heroku.git\n")
              RestClient.stub!(:post).and_return("{}")
            end

            it "should rewrite the github url to not use the private url" do
              @command.push.should == "git://github.com/hone/heroku.git"
            end

            it "should post to url" do
              RestClient.should_receive(:post)
              @command.push
            end

            describe "response was successful" do
              before(:each) do
                RestClient.stub!(:post).and_return("{}")
              end

              it "should display a message" do
                @command.should_receive(:display)
                @command.push
              end
            end

            describe "response was unsuccessful" do
              before(:each) do
                RestClient.stub!(:post).and_return('{"error":"Plugin create error."}')
              end

              it "should display error" do
                @command.should_receive(:error)
                @command.push
              end
            end
          end

          describe "origin remote doesn't exist" do
            before(:each) do
              @command.stub!(:git_remote_show_origin).and_return("")
            end

            describe "does not pass in uri" do
              before(:each) do
                @command.stub!(:error)
              end

              it "should not post to url" do
                RestClient.should_not_receive(:post)
                @command.push
              end

              it "should display an error" do
                @command.should_receive(:error)
                @command.push
              end
            end

            describe "passes in uri" do
              before(:each) do
                @command.stub!(:args).and_return(["git@github.com:hone/heroku.git"])
              end

              it "should post to url" do
                RestClient.should_receive(:post).and_return("{}")
                @command.push
              end
            end
          end
        end
      end
    end
	end
end
