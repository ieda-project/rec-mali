class ConvertPngs < ActiveRecord::Migration
  def self.up
    Child.transaction do
      begin
        if File.directory? "#{Rails.root}/public/repo"
          File.popen("find #{Rails.root}/public/repo/ -name '*_original.png'", 'r') do |pipe|
            pipe.each_line do |png|
              png.chomp!
              `convert -quality 85 #{png} #{png.sub(/_original\.png$/, '.jpg')}`
            end
          end
        end

        Child.where(photo_content_type: 'image/png').each do |child|
          child.photo_content_type = 'image/jpeg'
          child.photo_file_name = 'photo.jpg'
          child.photo_file_size = (File.size(child.photo.path) rescue 0)
          child.save!
        end
      rescue
        if File.directory? "#{Rails.root}/public/repo"
          system "find #{Rails.root}/public/repo/ -name '*.jpg' -exec rm -f {} +"
        end
        raise
      end
    end
    if File.directory? "#{Rails.root}/public/repo"
      system "find #{Rails.root}/public/repo/ -name '*.png' -exec rm -f {} +"
    end
  end

  def self.down
  end
end
