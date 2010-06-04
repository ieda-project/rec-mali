Csps::Application.routes.draw do |map|
  resource :session, controller: 'session'

  resources :children do
    post :temp, on: :collection
    resources :diagnostics do
      post :calculations, on: :member
    end
  end

  root to: 'children#index'
end
