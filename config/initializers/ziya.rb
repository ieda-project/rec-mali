require 'ziya'

Ziya.initialize( 
  :logger      => RAILS_DEFAULT_LOGGER,
  :helpers_dir => File.join(File.dirname(__FILE__), %w[.. .. app helpers ziya] ),
  :themes_dir  => File.join(File.dirname(__FILE__), %w[.. .. public charts themes]))
