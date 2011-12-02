class ConvertPngs < ActiveRecord::Migration
  def self.up
    Child.transaction do
      begin
        File.popen("find #{Rails.root}/public/repo/ -name '*_original.png'", 'r') do |pipe|
          pipe.each_line do |png|
            puts png
            png.chomp!
            puts "convert -quality 85 #{png} #{png.sub(/_original\.png$/, '.jpg')}"
            `convert -quality 85 #{png} #{png.sub(/_original\.png$/, '.jpg')}`
          end
        end

        Child.where(photo_content_type: 'image/png').each do |child|
          child.photo_content_type = 'image/jpeg'
          child.photo_file_name = 'photo.jpg'
          child.photo_file_size = (File.size(child.photo.path) rescue 0)
          child.save!
        end
      rescue
        system "find #{Rails.root}/public/repo/ -name '*.jpg' -exec rm -f {} +"
        raise
      end
    end
    system "find #{Rails.root}/public/repo/ -name '*.png' -exec rm -f {} +"
  end

  def self.down
  end
end
