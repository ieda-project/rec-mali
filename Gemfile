source 'http://gemcutter.org'

if Object.const_defined? :HEROKU_ROOT
  gem 'rails', '3.0.0.beta4'
  gem 'haml', '3.0.12'
  gem 'pg'
else
  gem 'rails', '3.0.0.beta3'
  gem 'haml', '3.0.4'
  if RUBY_PLATFORM =~ /darwin/
    gem 'pg'
  else
    gem 'sqlite3-ruby', :require => 'sqlite3'
  end
end

gem 'faker'
