Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'landing#index'

  namespace 'about' do
    get 'motivation', as: 'motivation'
    get 'organisation', as: 'organisation'
    get 'open', as: 'open'
    get 'data', as: 'data'
    get 'pricing', as: 'pricing'
    get 'comparison', as: 'comparison'
  end

  # This is also the getting started part
  namespace 'admin' do
    resources :relying_parties, constraints: { id: %r{[^/]+} }, only: %i[show index] do
      resources :emails, only: %i[create destroy]
    end
  end

  namespace 'root' do
    get '/', to: 'relying_parties#index'
    resources :relying_parties, constraints: { id: %r{[^/]+} }, only: [:index]
  end

  # Paths for basic login functionality
  get    'a/:client_id', to: 'registrations#new', as: 'login_with_relying_party', constraints: { client_id: %r{[^/]+} }
  get    'a', to: 'registrations#new', as: 'login_short'
  get    'login', to: 'registrations#new', as: 'login'
  get    'verify_password', to: 'authentication#verify_password', as: 'verify_password'
  delete 'logout', to: 'authentication#logout', as: 'logout'
  get    'logout', to: 'authentication#logout'
  delete 'relogin', to: 'authentication#relogin', as: 'relogin'
  get    'confirm', to: 'authentication#confirm', as: 'confirm'
  post   'authenticate', to: 'authentication#authenticate', as: 'authenticate'
  get    'authenticate', to: 'registrations#new' # Here for legacy reasons
  post   'go_to', to: 'authentication#go_to', as: 'go_to'


  resources :registrations, only: %i[new create] do
    collection do
      get :verify_human
      post :verify_human
      get :verify_email
      post :verify_email
      get :create_password
      post :create_password
    end
  end

  resource :password, only: %i[new edit show create] do
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
