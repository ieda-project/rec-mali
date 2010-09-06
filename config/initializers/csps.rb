load 'monkey_patches.rb'

module Csps
  class << self
    def site
      @site ||= Zone.csps.try(:name).freeze
    end

    def point?
      @point = Zone.csps.try(:point?) if @point.nil?
      @point
    end
  end
end
