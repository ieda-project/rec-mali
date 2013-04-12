class ImportVersion < ActiveRecord::Base
  class << self
    def get key
      obj = find_by_key(key) and obj.version
    end
    alias [] get

    def set key, version
      if obj = find_by_key(key)
        obj.update_attribute :version, version
      else
        create key: key, version: version
      end
    end
    alias []= set

    class << DUMMY = Object.new
      def close; end
      def gets; end
      def read; end
      def each_line; end
      def size; 0; end
    end

    def process *fnames
      files, vers, go = [], {}, false
      fnames.each do |fn|
        raise "No such file: #{fn}" unless File.exist?(fn)
        f = if File.size(fn) > 0
          File.open fn, 'r'
        else
          DUMMY
        end
        files << f

        v = begin
          l = f.gets and l.chomp.scan(/^\$version (.+)$/).first.first
        rescue NoMethodError
          raise "Bad import file format: #{fn}"
        end

        if v && get(fn) != v
          go = true
          vers[fn] = v
        end
      end

      if go
        yield *files
        vers.each { |k,v| set(k, v) }
      end
    ensure
      files.each { |f| f.close rescue nil } if files
    end
  end
end
