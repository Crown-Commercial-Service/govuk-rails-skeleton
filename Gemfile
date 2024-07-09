source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 6.4'

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem 'cssbundling-rails', '~> 1.4'

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem 'jsbundling-rails', '~> 1.3'

gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.12'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'geocoder', '>= 1.6.1'
gem 'activerecord-postgis-adapter', '>= 6.0.3'
gem 'uk_postcode'
gem 'rubyzip', '>= 1.2.1'
gem 'caxlsx', '>= 3.2.0'
gem 'caxlsx_rails', '>= 0.6.3'
gem 'virtus'

gem 'rollbar', '~> 3.5.2'

# for dfe sign in
gem 'omniauth', '~> 2.1.2'
gem 'omniauth-oauth2', '~> 1.8.0'

# for authentication
gem 'devise', '~> 4.9.4'

# for timing out when session expires
gem 'auto-session-timeout', '~> 1.1'

# for cognito
gem 'aws-sdk-cognitoidentityprovider', '~> 1.97.0'

# for pagination
gem 'kaminari', '~> 1.2.2'

# aws s3 bucket access for postcode data
gem 'aws-sdk-s3', '~> 1'

# handles spreadsheets
gem 'roo', '~> 2.10.1'

# state machine
gem 'aasm', '~> 5.5'
gem 'after_commit_everywhere', '~> 1.4'

# for running background jobs
gem 'sidekiq', '~> 7.3.0'
gem 'sinatra', '~> 4.0.0', require: false
gem 'slim', '~> 5.2.1'
gem 'sidekiq-cron'

# for authorization
gem 'cancancan', '~> 3.6.1'

gem 'role_model', '~> 0.8.2'

gem 'smarter_csv'

# for date layout and validation
gem 'gov_uk_date_fields', '>= 4.2.0'
gem 'date_validator', '>= 0.12.0'

# for clamav
gem 'ratonvirus', '>= 0.3.2'
gem 'ratonvirus-clamby', '>= 0.3.0'
# for active storage validation
gem 'active_storage_validations', '>= 1.0.3'
# gem for  bulk inserts
gem 'activerecord-import', '~> 1.7.0'
# gov notify
gem 'notifications-ruby-client'
# DOCX generation
gem 'caracal-rails', '>= 1.0.2'

# duplicating procurements
gem 'amoeba', '>= 3.2.0'

# For validating emails
gem 'email_validator', require: 'email_validator/strict'

# for cloud storage of assets
gem 'asset_sync', '>= 2.19.1'
gem 'fog-aws', '>= 3.14.0'

# Use CCS Frontend Helpers
gem 'ccs-frontend_helpers', '~> 1.1.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails', '>= 2.8.1'
  gem 'factory_bot_rails', '>= 6.2.0'
  gem 'pry-rails'
  gem 'rails-controller-testing', '>= 1.0.5'
  gem 'rspec-rails', '>= 6.0.1'
  gem 'shoulda-matchers', '>= 5.1.0'
  gem 'rubocop', '>= 1.11.0'
  gem 'rubocop-rspec', '>= 2.2.0'
  gem 'rubocop-rails', '>= 2.18.0', require: false
  gem 'rubocop-capybara', '>= 2.20.0', require: false
  gem 'rubocop-factory_bot', '>= 2.25.1', require: false
  gem 'rubocop-rspec_rails', '>= 2.28.3', require: false
  gem 'rubyXL', '>= 3.4.23'
  gem 'i18n-tasks', '>= 1.0.12'
  gem 'poltergeist', '>= 1.18.1'
  gem 'wdm', '>= 0.1.0', platforms: %i[x64_mingw]
  gem 'tzinfo-data', platforms: %i[x64_mingw]
  gem 'bullet', require: true
  gem 'faker', '~> 3.4.1'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.10'
  gem 'pry-byebug'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'webmock', '>= 3.12.1'
  gem 'simplecov', '>= 0.16.1', require: false
  gem 'selenium-webdriver', '>= 3.142.3'
  gem 'cucumber-rails', '>= 2.6.1', require: false
  gem 'capybara', '>= 3.38.0'
  gem 'database_cleaner', '>= 2.0.1'
  gem 'site_prism', '>= 3.7.3'
  gem 'axe-core-capybara', '>= 4.2.1'
  gem 'axe-core-cucumber', '>= 4.2.1'
  gem 'show_me_the_cookies', '>= 6.0.0'
end
