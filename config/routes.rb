Csps::Application.routes.draw do |map|
  resource :session, controller: 'session'
  resources :illnesses do
    get :classification, on: :member
  end

  resources :children do
    post :temp, on: :collection
    resources :diagnostics do
      member do
        get :treatments, :wait
        post :calculations
      end
    end
  end

  root to: 'children#index'
end
