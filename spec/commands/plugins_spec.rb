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

    describe "when updating all plugins" do
      before(:each) do
        @plugin.stub!(:name).and_return("heroku plugin0")
        @plugin1 = mock('heroku plugin1', :name => "heroku plugin1")
        @plugin2 = mock('heroku plugin2', :name => 'heroku plugin2')
        @sandbox = "/tmp/heroku_plugins_spec_#{Process.pid}"
        @plugin_path = @sandbox + "/heroku_plugin"
        @plugin_path1 = @sandbox + "/heroku_plugin1"
        @plugin_path2 = @sandbox + "/heroku_plugin2"

        Heroku::Plugin.stub!(:list).and_return([@plugin_path, @plugin_path1, @plugin_path2])
        Heroku::Plugin.list.each_with_index do |path, index|
          FileUtils.mkdir_p(path)
          `cd #{path} && git init && git remote add origin git@foo.com:heroku_plugin#{index}.git`

        end
        Heroku::Plugin.stub!(:new).with("git@foo.com:heroku_plugin0.git").and_return(@plugin)
        Heroku::Plugin.stub!(:new).with("git@foo.com:heroku_plugin1.git").and_return(@plugin1)
        Heroku::Plugin.stub!(:new).with("git@foo.com:heroku_plugin2.git").and_return(@plugin2)
        @command.stub!(:args).and_return([])
      end

      after(:each) do
        FileUtils.rm_rf(@sandbox)
      end

      it "should update each plugin" do
        @plugin.should_receive(:update)
        @plugin1.should_receive(:update)
        @plugin2.should_receive(:update)

        @command.update
      end

      it "should print update statuses" do
        `cd #{@plugin_path} && git remote rm origin`
        @plugin1.stub!(:update).and_return(true)
        @plugin2.stub!(:update).and_return(false)
        @command.should_receive(:display).with("Please reinstall, no remote for #{@plugin_path}")
        @command.should_receive(:display).with("Successfully updated: heroku plugin1")
        @command.should_receive(:display).with("Could not update: heroku plugin2")

        @command.update
      end
    end
  end
end
