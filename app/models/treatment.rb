class Treatment < ActiveRecord::Base
  belongs_to :classification
  has_many :prescriptions
  has_many :medicines, through: :prescriptions

  def html diag
    pres = prescriptions.includes(:medicine).hashize do |p|
      p.medicine.key
    end

    src = description.gsub(/{{med:(.+)}}/) do
      pres[$1].html(diag) rescue nil
    end

    helps = []
    src.gsub! /{{help:(.+)}}/ do
      if th = TreatmentHelp.find_by_key($1)
        helps << th
        %Q[(<a class="help" href="#tr_#{id}_#{$1}">#{th.title}</a>)]
      end
    end

    helps.each do |th|
      src += %Q(\n\n<div class="help" id="tr_#{id}_#{th.key}">\n#{th.textile}\n\n</div>)
    end
    RedCloth.new(src).to_html.gsub(/^\s*<li>\s*<\/li>\n*/m, '')
  end
end
