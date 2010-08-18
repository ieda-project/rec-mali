Csps::Application.routes.draw do |map|
  resource :session, controller: 'session' do
    get :welcome
  end
  resources :users
  resources :queries do
    get :export, on: :member
  end

  resources :illnesses do
    get :classification, on: :member
  end

  resources :children do
    member do
      get :indices
    end
    collection do 
      post :temp
    end
    resources :diagnostics do
      member do
        get :treatments, :wait
        post :calculations
      end
    end
  end

  root to: 'children#index'
end
