load 'monkey_patches.rb'

module Csps
  class << self
    def site
      @site ||= Village.csps.freeze rescue nil
    end
  end
end
