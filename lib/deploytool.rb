class Deploytool

  # Configure Chef-solo
  def initialize
    if `gem list|grep chef`.empty?
      STDERR.puts "WARNING: you don't appear to have chef installed"
    end
  end

  #  Many customization options are available!!!
  #  SEE: http://wiki.opscode.com/display/chef/Deploy+Resource
  # Configure the cookbook to use svn with no extra 'shared' files (generic)
  # ~<opts> is the options hash usually populated by trollop's command line opts
  def use_svn(opts)
    #  The Deploy resources assumes you have already created the 'shared' directories
    FileUtils.mkdir_p File.join(opts[:destination], 'shared', 'log')

    # setup the optional action and revision
    rev = ""
    rev = "revision \"#{opts[:revision]}\"" if opts[:revision]
    action = ""
    action = "action :rollback" if opts[:rollback]
    action = "action :force_deploy" if opts[:force]

    # setup optional auth
    suser = ""
    suser = "svn_username #{ENV['OPT_SVN_USERNAME']}" if ENV['OPT_SVN_USERNAME']
    spass = ""
    spass = "svn_password #{ENV['OPT_SVN_USERNAME']}" if ENV['OPT_SVN_USERNAME']

    @cookbook =<<EOBOOK
      deploy_revision "#{opts[:destination]}" do
        repo "#{opts[:repository]}"
        #{rev}
        symlinks Hash.new
        symlink_before_migrate Hash.new
        create_dirs_before_symlink Array.new
        purge_before_symlink Array.new
        scm_provider Chef::Provider::Subversion
        #{suser}
        #{spass}
        #{action}
      end
EOBOOK
  end

  #  Many customization options are available!!!
  #  SEE: http://wiki.opscode.com/display/chef/Deploy+Resource
  # Configure the cookbook to use git with no extra 'shared' files (generic)
  # ~<opts> is the options hash usually populated by trollop's command line opts
  def use_git(opts)
    #  The Deploy resources assumes you have already created the 'shared' directories
    FileUtils.mkdir_p File.join(opts[:destination], 'shared', 'log')

    # setup the optional action and revision
    rev = ""
    rev = "revision \"#{opts[:revision]}\"" if opts[:revision]
    action = ""
    action = "action :rollback" if opts[:rollback]
    action = "action :force_deploy" if opts[:force]

    @cookbook =<<EOBOOK
      deploy_revision "#{opts[:destination]}" do
        repo "#{opts[:repository]}"
        #{rev}
        shallow_clone true
        symlinks Hash.new
        symlink_before_migrate Hash.new
        create_dirs_before_symlink Array.new
        purge_before_symlink Array.new
        #{action}
      end
EOBOOK
  end

  # Run chef-solo; do the deploy.
  def run_solo
    gempath = `gem env`.grep(/EXECUTABLE DIRECTORY/).first.split(/:/).last.chomp
    @solo = File.join(gempath, "chef-solo")
    @solo_config_path = File.join(File.expand_path("~"), "chef-solo")
    FileUtils.mkdir_p(@solo_config_path)
    solo_config =<<EOSOLO
      file_cache_path "#{@solo_config_path}"
      cookbook_path "#{@solo_config_path}/cookbooks"
EOSOLO
    File.open("#{@solo_config_path}/chef-solo.conf", "w") { |f| f.write solo_config }

    FileUtils.mkdir_p("#{@solo_config_path}/cookbooks/app_code/recipes")
    File.open("#{@solo_config_path}/cookbooks/app_code/recipes/deploy.rb", "w") { |f| f.write @cookbook }
    runlist = '{ "run_list": "app_code::deploy" }'
    File.open("#{@solo_config_path}/deploy_runlist.js", "w") { |f| f.write runlist }
# Run chef-solo to deploy your code!
    puts "Running chef-solo"
    puts `#{@solo} -c #{@solo_config_path}/chef-solo.conf -j #{@solo_config_path}/deploy_runlist.js`
    exit(1) unless $?.success?
  end

end
