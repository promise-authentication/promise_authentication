Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'landing#index'

  namespace 'about' do
    get 'motivation', as: 'motivation'
    get 'open', as: 'open'
    get 'data', as: 'data'
    get 'pricing', as: 'pricing'
  end

  # This is also the getting started part
  namespace 'admin' do
    resources :relying_parties, constraints: { id: /[^\/]+/ }, only: [:show, :index] do
      resources :emails, only: [:create, :destroy]
    end
  end

  namespace 'root' do
    get '/', to: "relying_parties#index"
    resources :relying_parties, constraints: { id: /[^\/]+/ }, only: [:index]
  end

  # Paths for basic login functionality
  get    'a/:client_id', to: 'authentication#login', as: 'login_with_relying_party', constraints: { client_id: /[^\/]+/ }
  get    'a', to: 'authentication#login', as: 'login_short'
  get    'login', to: 'authentication#login', as: 'login'
  delete 'logout', to: 'authentication#logout', as: 'logout'
  delete 'relogin', to: 'authentication#relogin', as: 'relogin'
  get    'confirm', to: 'authentication#confirm', as: 'confirm'
  post   'authenticate', to: 'authentication#authenticate', as: 'authenticate'
  get    'authenticate', to: 'authentication#login'
  post   'go_to', to: 'authentication#go_to', as: 'go_to'

  resource :password, only: [:new, :show, :create] do
    member do
      post :recover
      get :wait
    end
  end

  resources :tokens do
    resources :recoveries
  end

  get 'me', to: 'humans#show', as: 'dashboard'
  get 'uniq', to: 'humans#uniq', as: 'uniq'

  scope path: '.well-known' do
    get 'jwks', to: 'well_knowns#jwks'
  end
end
