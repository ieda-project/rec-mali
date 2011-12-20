source 'http://gemcutter.org'

gem 'rails', '<3.1', '>=3'
gem 'haml'
gem 'sass'

gem 'bcrypt-ruby', require: 'bcrypt'
gem 'builder'
gem 'faker'
gem 'RedCloth', require: 'redcloth'
gem 'spreadsheet'
gem 'ziya'
gem 'color'
gem 'logging'
gem 'paperclip'
gem 'state_machine'

group :development, :test, :production do
  gem 'thin'
  gem 'sqlite3'
end

group :heroku do
  gem 'pg'
  gem 'hassle', git: 'http://github.com/Papipo/hassle.git'
end

group :test do
  gem 'shoulda'
end
