class TreatmentHelp < ActiveRecord::Base
  def textile
    if image?
      "!/images/help/#{key}.jpg!\n#{content}"
    else
      content
    end
  end
end
