Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'landing#index'

  namespace 'about' do
    get 'welcome'
    get 'current_state_of_authentication'
    get 'non_profit'
    get 'identity'
    get 'privacy'
    get 'security'
    get 'trust'
    get 'technology'
  end

  get 'open', to: 'about#open', as: 'open'
  get 'data', to: 'about#data', as: 'data'

  namespace 'documentation' do
    get 'get_started'
    get 'well_known'
    get 'configuration'
  end

  get 'a/:client_id', to: 'authentication#login', as: 'login_with_relying_party', :constraints => { :client_id => /[^\/]+/ }
  get 'a', to: 'authentication#login', as: 'login_short'

  get 'login', to: 'authentication#login', as: 'login'
  delete 'logout', to: 'authentication#logout', as: 'logout'
  delete 'relogin', to: 'authentication#relogin', as: 'relogin'
  get 'confirm', to: 'authentication#confirm', as: 'confirm'
  post 'authenticate', to: 'authentication#authenticate', as: 'authenticate'
  get 'authenticate', to: 'authentication#login'
  post 'go_to', to: 'authentication#go_to', as: 'go_to'

  resource :password, only: [:new, :show, :create] do
    member do
      post :recover
      get :wait
    end
  end

  resources :keys do
    resources :recoveries
  end

  get 'me', to: 'humans#show', as: 'dashboard'
  get 'uniq', to: 'humans#uniq', as: 'uniq'


  scope path: '.well-known' do
    get 'jwks', to: 'well_knowns#jwks'
  end
end
