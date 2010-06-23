# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'
Csps::Application.initialize!
