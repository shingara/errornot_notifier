require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'cucumber/rake/task'

desc 'Default: run unit tests.'
task :default => [:test, :cucumber]

desc 'Test the errornot_notifier gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Run ginger tests'
task :ginger do
  $LOAD_PATH << File.join(*%w[vendor ginger lib])
  ARGV.clear
  ARGV << 'test'
  load File.join(*%w[vendor ginger bin ginger])
end

namespace :changeling do
  desc "Bumps the version by a minor or patch version, depending on what was passed in."
  task :bump, :part do |t, args|
    # Thanks, Jeweler!
    if ErrornotNotifier::VERSION  =~ /^(\d+)\.(\d+)\.(\d+)(?:\.(.*?))?$/
      major = $1.to_i
      minor = $2.to_i
      patch = $3.to_i
      build = $4
    else
      abort
    end

    case args[:part]
    when /minor/
      minor += 1
      patch = 0
    when /patch/
      patch += 1
    else
      abort
    end

    version = [major, minor, patch, build].compact.join('.')

    File.open(File.join("lib", "errornot_notifier", "version.rb"), "w") do |f|
      f.write <<EOF
module ErrornotNotifier
  VERSION = "#{version}".freeze
end
EOF
    end
  end

  desc "Writes out the new CHANGELOG and prepares the release"
  task :change do
    load 'lib/errornot_notifier/version.rb'
    file    = "CHANGELOG"
    old     = File.read(file)
    version = ErrornotNotifier::VERSION
    message = "Bumping to version #{version}"

    File.open(file, "w") do |f|
      f.write <<EOF
Version #{version} - #{Date.today}
===============================================================================

#{`git log $(git tag | tail -1)..HEAD | git shortlog`}
#{old}
EOF
    end

    exec ["#{ENV["EDITOR"]} #{file}",
          "git commit -aqm '#{message}'",
          "git tag -a -m '#{message}' v#{version}",
          "echo '\n\n\033[32mMarked v#{version} /' `git show-ref -s refs/heads/master` 'for release. Run: rake changeling:push\033[0m\n\n'"].join(' && ')
  end

  desc "Bump by a minor version (1.2.3 => 1.3.0)"
  task :minor do |t|
    Rake::Task['changeling:bump'].invoke(t.name)
    Rake::Task['changeling:change'].invoke
  end

  desc "Bump by a patch version, (1.2.3 => 1.2.4)"
  task :patch do |t|
    Rake::Task['changeling:bump'].invoke(t.name)
    Rake::Task['changeling:change'].invoke
  end

  desc "Push the latest version and tags"
  task :push do |t|
    system("git push origin master")
    system("git push origin $(git tag | tail -1)")
  end
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', 'TESTING.rdoc']
  end
rescue LoadError
end

GEM_ROOT     = File.dirname(__FILE__).freeze
VERSION_FILE = File.join(GEM_ROOT, 'lib', 'errornot_notifier', 'version')

require VERSION_FILE

gemspec = Gem::Specification.new do |s|
  s.name        = %q{errornot_notifier}
  s.version     = ErrornotNotifier::VERSION
  s.summary     = %q{Send your application errors to a hosted service and reclaim your inbox.}

  s.files        = FileList['[A-Z]*', 'generators/**/*.*', 'lib/**/*.rb',
                            'test/**/*.rb', 'rails/**/*.rb', 'script/*',
                            'lib/templates/*.erb']
  s.require_path = 'lib'
  s.test_files   = Dir[*['test/**/*_test.rb']]

  s.has_rdoc         = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options = ['--line-numbers', "--main", "README.rdoc"]

  s.add_runtime_dependency("activesupport")
  s.add_development_dependency("activerecord")
  s.add_development_dependency("actionpack")
  s.add_development_dependency("jferris-mocha")
  s.add_development_dependency("nokogiri")
  s.add_development_dependency("shoulda")

  s.authors = ["thoughtbot, inc, Cyril Mougel"]
  s.email   = %q{cyril.mougel@gmail.com}
  s.homepage = "http://github.com/shingara/errornot_notifier"

  s.platform = Gem::Platform::RUBY
end

Rake::GemPackageTask.new gemspec do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc "Clean files generated by rake tasks"
task :clobber => [:clobber_rdoc, :clobber_package]

desc "Generate a gemspec file"
task :gemspec do
  File.open("#{gemspec.name}.gemspec", 'w') do |f|
    f.write gemspec.to_ruby
  end
end

LOCAL_GEM_ROOT = File.join(GEM_ROOT, 'tmp', 'local_gems').freeze
RAILS_VERSIONS = IO.read('SUPPORTED_RAILS_VERSIONS').strip.split("\n")
LOCAL_GEMS = [['sham_rack', nil], ['capistrano', nil], ['sqlite3-ruby', nil], ['sinatra', nil]] +
  RAILS_VERSIONS.collect { |version| ['rails', version] }

task :vendor_test_gems do
  old_gem_path = ENV['GEM_PATH']
  old_gem_home = ENV['GEM_HOME']
  ENV['GEM_PATH'] = LOCAL_GEM_ROOT
  ENV['GEM_HOME'] = LOCAL_GEM_ROOT
  LOCAL_GEMS.each do |gem_name, version|
    gem_file_pattern = [gem_name, version || '*'].compact.join('-')
    version_option = version ? "-v #{version}" : ''
    pattern = File.join(LOCAL_GEM_ROOT, 'gems', "#{gem_file_pattern}")
    existing = Dir.glob(pattern).first
    unless existing
      command = "gem install -i #{LOCAL_GEM_ROOT} --no-ri --no-rdoc --backtrace #{version_option} #{gem_name}"
      puts "Vendoring #{gem_file_pattern}..."
      unless system("#{command} 2>&1")
        puts "Command failed: #{command}"
        exit(1)
      end
    end
  end
  ENV['GEM_PATH'] = old_gem_path
  ENV['GEM_HOME'] = old_gem_home
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.fork = true
  t.cucumber_opts = ['--format', (ENV['CUCUMBER_FORMAT'] || 'progress')]
end

task :cucumber => [:gemspec, :vendor_test_gems]

def define_rails_cucumber_tasks(additional_cucumber_args = '')
  namespace :rails do
    RAILS_VERSIONS.each do |version|
      desc "Test integration of the gem with Rails #{version}"
      task version => [:gemspec, :vendor_test_gems] do
        puts "Testing Rails #{version}"
        ENV['RAILS_VERSION'] = version
        system("cucumber --format #{ENV['CUCUMBER_FORMAT'] || 'progress'} #{additional_cucumber_args} features/rails.feature features/rails_with_js_notifier.feature")
      end
    end

    desc "Test integration of the gem with all Rails versions"
    task :all => RAILS_VERSIONS
  end
end

namespace :cucumber do
  namespace :wip do
    define_rails_cucumber_tasks('--tags @wip')
  end

  define_rails_cucumber_tasks
end

