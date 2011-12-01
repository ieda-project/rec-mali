class ConvertPngs < ActiveRecord::Migration
  def self.up
    Child.transaction do
      begin
        File.popen("find #{Rails.root}/public/repo -name '*_original.png'", 'r') do |png|
          png.chomp!
          `convert -quality 85 #{png} #{png.sub!(/_original\.png$/, '.jpg')}`
        end

        Child.where(photo_content_type: 'image/png').each do |child|
          child.photo_content_type = 'image/jpeg'
          child.photo_file_name = 'photo.jpg'
          child.photo_file_size = (File.size(child.photo.path) rescue 0)
          child.save!
        end

      rescue
        raise "Convert fail."
        system "find #{Rails.root}/public/repo -name '*.jpg' -exec rm -f {}"
      end
    end
    system "find #{Rails.root}/public/repo -name '*.png' -exec rm -f {}"
  end

  def self.down
  end
end
