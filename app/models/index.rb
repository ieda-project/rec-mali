class Index < ActiveRecord::Base
  enum :name, %w{weight-age height-age weight-height}
  
  WARNING = {'weight_age' => 80, 'height_age' => 90, 'weight_height' => 80}
  ALERT = {'weight_age' => 60, 'height_age' => 85, 'weight_height' => 70}
  
  validates_presence_of :name, :x, :y
  validates_numericality_of :x, :y
  
  NAMES.each_with_index do |name, i|
    scope name.gsub('-', '_'), :conditions => {:name => i}
  end

  scope :boys, conditions: { for_boys: true }
  scope :girls, conditions: { for_boys: false }
  scope :gender, ->(gender) {{ conditions: { for_boys: gender }}}
  scope :age_in_months, ->(months) {{ conditions: ['above_2yrs IS NULL OR above_2yrs = ?', (months >= 24)]}}
    
  def self.near arg
    order("abs(x - #{arg.to_f})").first
  end
  
  def for_girls?
    not for_boys?
  end
end

Index.new.inspect

=begin
This last line prevents some weird lazy load issue, which I cannot fathom.
To reproduce, remove this line, start a console and do the following:


> Diagnostic.first.wfa

It will fail with an exception. Then do these:

> Index.new.inspect
> Diagnostic.first.wfa

It will work. In fact you can inspect any Index instance for the effect.
=end
