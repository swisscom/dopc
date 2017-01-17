source 'https://rubygems.org'

gem 'rails', '~> 5.0.0'
gem 'puma', '~> 3.0'
gem 'sqlite3', '~> 1.3.11'
gem 'delayed_job_active_record', '~> 4.1.1'
gem 'daemons', '~> 1.2.4'

gem 'dop_common',
  :git => 'https://gitlab.swisscloud.io/puppet-dop/dop_common.git',
  :tag => 'v0.11.3'
gem 'dopv',
  :git => 'https://gitlab.swisscloud.io/puppet-dop/dopv.git',
  :tag => 'v0.7.3'
gem 'dopi',
  :git => 'https://gitlab.swisscloud.io/puppet-dop/dopi.git',
  :tag => 'v0.15.2'
#gem 'dop_common', :path => '../dop_common'
#gem 'dopv', :path => '../dopv'
#gem 'dopi', :path => '../dopv'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'mocha', '~> 1.1.0'
  gem 'pry'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
