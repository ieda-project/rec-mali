if Rails.env == 'production'
	Rails::Application.middleware.use SassOnHeroku
end
