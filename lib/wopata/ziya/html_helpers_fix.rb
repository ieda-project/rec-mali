module Wopata
  module Ziya
    module HtmlHelpersFix
      def tag(name, options = nil, open = false, escape = true)
        "<#{name}#{tag_options(options, escape) if options}#{open ? ">" : " />"}".html_safe
      end
    end
  end
end
