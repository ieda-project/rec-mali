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

Paperclip.interpolates :uqid do |attachment, style_name|
  attachment.instance.uqid
end

Paperclip.interpolates :zone_name do |attachment, style_name|
  attachment.instance.zone_name
end

Haml::Template.options[:format] = :xhtml
