require 'logger'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

task default: :spec

# Copied from Sequel's docs
# http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html#label-Running+migrations+from+a+Rake+task
namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_, args|
    require 'sequel/core'
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    url = ENV.fetch('DATABASE_URL')
    Sequel.connect(url, logger: Logger.new($stderr)) do |db|
      Sequel::Migrator.run(db, 'db/migrations', target: version)
    end
  end
end

task :proto do
  sh 'protoc --ruby_out=. --twirp_ruby_out=. --doc_out=doc/ --doc_opt=html,index.html app/service/service.proto'
end
