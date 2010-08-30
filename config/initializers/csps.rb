load 'monkey_patches.rb'

module Csps
  class << self
    def site
      @site ||= Zone.csps.try(:name).freeze
    end
  end
end
