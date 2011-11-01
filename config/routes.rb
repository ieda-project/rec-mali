Csps::Application.routes.draw do
  resource :session, controller: 'session' do
    get :welcome, :restore
  end
  resource :syncs
  resources :users
  resources :queries do
    get :export, on: :member
  end

  resources :illnesses do
    post :classification, on: :member
  end

  resources :children do
    collection do
      get :calculations, :hors_zone, :birthdate
    end
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
