# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_csps_session',
  :secret => '0eb4f8c2fcd1c812bbd88eecc5e5f9997d556b877b2ff869c64bcd8b53ec83847ad1c3acc0ffb4ed522fc3cbacaa8968154d05ae8f185a96e66aa3c4c60e002a'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
