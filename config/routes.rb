Csps::Application.routes.draw do
  resource :session, controller: 'session' do
    get :welcome, :restore
  end
  resource :syncs
  resources :zones
  resources :users do
    get :logins, on: :member, to: :user_logins
    get :logins, :password, on: :collection
  end
  resources :queries do
    get :export, on: :member
  end

  resources :illnesses do
    post :classification, on: :member
  end

  resources :children do
    collection do
      get :calculations, :questionnaire
      post :temp
    end
    member do
      get :indices
    end
    resources :diagnostics do
      collection do
        get :questionnaire
      end
      member do
        get :treatments, :wait
        post :calculations
      end
    end
  end

  root to: 'children#index'
end
