Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'about#welcome'
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

  namespace 'documentation' do
    get 'get_started'
    get 'well_known'
    get 'configuration'
  end

  get 'login', to: 'humans#login', as: 'login'
  post 'authenticate', to: 'humans#authenticate', as: 'authenticate'

  get 'me', to: 'humans#show', as: 'dashboard'

  get ':relying_party_id/login', to: 'humans#login', as: 'login_with_relying_party', :constraints => { :relying_party_id => /[^\/]+/ }

  resources :relying_parties, :id => /.*/ do
    member do
      post 'setup'
    end
  end
end
