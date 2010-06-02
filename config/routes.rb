Csps::Application.routes.draw do |map|
  resource :session, :controller => 'session'

  resources :children do
    resources :diagnostics do
      member { post :calculations }
    end
  end

  root to: 'children#index'
end
