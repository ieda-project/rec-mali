module Wopata::ActiveRecord
  module Pagination
    class OutOfBoundsError < Exception; end

    @default_window = 20
    class << self
      attr_accessor :default_window
    end

    class Page
      attr_reader :rel, :page, :window
      private :rel

      include Enumerable
      delegate :each, :to => :paged_rel

      def initialize rel, *args
        @rel, @opts = rel, args.extract_options!
        @window = @opts.delete(:window) || Pagination.default_window
        n = (args.shift || @opts.delete(:page)).to_i
        raise OutOfBoundsError, "Requested page #{n} of #{pages}" if n > pages
        @page = case n <=> 0
          when -1 then pages + 1 + n
          when 0 then 1
          when 1 then n
        end
      end

      def pages
        @pages ||= rel.count.fdiv(window).ceil
      end

      def total
        rel.count
      end

      def count
        # Any other way?
        paged_rel.all.size
      end
      alias size count
      alias length count

      def paginate *args
        Page.new rel, *args
      end

      def prev?; page > 1; end
      def next?; page < pages; end

      def prev; generate page-1; end
      def next; generate page+1; end
      alias pred prev
      alias succ next

      def prev!; replace page-1; end
      def next!; replace page+1; end
      alias pred! prev!
      alias succ! next!

      def inspect
        "#<#{self.class.name} ##{page}/#{pages} on #{rel.klass.name}>"
      end

      private

      def paged_rel
        @paged_rel ||= rel.limit(window).offset window * (page-1)
      end

      def replace p
        if p >= 1 && p <= pages
          @paged_rel, @pages, @page = nil, nil, p
        else
          raise OutOfBoundsError, "Tried to move to page #{p} of #{pages}"
        end
        self
      end

      def generate p
        paginate @opts.merge(:window => window, :page => p) if p >= 1 && p <= pages
      end
    end

    module Relation
      def paginate *args
        Page.new self, *args
      end
    end
  end
end
