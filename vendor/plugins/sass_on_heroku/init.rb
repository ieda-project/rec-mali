if Rails.env == 'heroku'
	Rails::Application.middleware.use SassOnHeroku
end
