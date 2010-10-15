require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tmpdir'
require 'fileutils'

describe "Deploytool" do
  before(:each) do
    @dir = File.join(Dir.tmpdir, Time.now.strftime("%S%H%d"))
    FileUtils.mkdir_p(@dir)
  end
  
  it "runs a git deploy" do
    opts = { :destination => @dir, :repository => "git://github.com/jeremyd/rest_connection.git", :revision => "master" }
    deploy = Deploytool.new
    deploy.use_git(opts)
    deploy.run_solo
    File.exists?(File.join(@dir, "current", "Rakefile")).should == true 
  end

  it "runs an svn deploy" do
    opts = { :destination => @dir, :repository => "http://svn.apache.org/repos/asf/spamassassin/trunk" }
    deploy = Deploytool.new
    deploy.use_svn(opts)
    deploy.run_solo
    File.exists?(File.join(@dir, "current", "README")).should == true 
  end

  after(:each) do
    FileUtils.rm_rf(@dir)
  end
end
