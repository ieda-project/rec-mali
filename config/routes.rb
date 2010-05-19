Csps::Application.routes.draw do |map|
  resource :session, :controller => 'session'

  resources :children do
    resources :diagnostics do
    end
  end

  root to: 'children#index'
end
