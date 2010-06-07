module Wopata::ActionController::Statuses
  for s,n in { 404 => :not_found, 401 => :denied, 402 => :unpaid, 403 => :forbidden, 422 => :unprocessable } do
    module_eval "
      def #{n} opts={}
        respond_to do |wants|
          wants.html do
            if opts[:action]
              render opts.merge(status: #{s})
            else
              render opts.merge(template: 'shared/#{s}', status: #{s}, layout: 'lobby')
            end
          end
          wants.any  { render opts.merge(template: 'shared/#{s}', status: #{s}) }
        end
        false
      end", __FILE__, __LINE__
  end

  for s,n in { 301 => :moved, 307 => :moved_temporarily, 303 => :see_other } do
    module_eval "
      def #{n} where
        redirect_to where, status: #{s}
      end", __FILE__, __LINE__
  end
end
