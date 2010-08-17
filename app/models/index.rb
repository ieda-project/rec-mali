class Index < ActiveRecord::Base
  enum :name, %w{weight-age height-age weight-height}
  
  validates_presence_of :name, :x, :y, :for_boys
  validates_numericality_of :x, :y
  
  NAMES.each_with_index do |name, i|
    scope name.gsub('-', '_'), :conditions => {:name => i}
  end

  scope :boys, :conditions => {:for_boys => true}
  scope :girls, :conditions => {:for_boys => false}
  scope :gender, lambda{|gender| {:conditions => {:for_boys => gender}}}
    
  def self.near arg
    find(:first, :order => "abs(x - #{arg.to_f})")
  end
end
