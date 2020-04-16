Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root 'authentication#login'

  constraints subdomain: '' do
    get '/', to: 'about#welcome'

    get 'me', to: 'humans#show', as: 'dashboard'

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

    get ':aud/login', to: 'authentication#login', as: 'login_with_relying_party', :constraints => { :aud => /[^\/]+/ }

    scope path: '.well-known' do
      get 'jwks', to: 'well_knowns#jwks'
    end
  end

  constraints subdomain: 'auth' do
    get '/', to: 'authentication#login'
  end

  get 'login', to: 'authentication#login', as: 'login'
  get 'logout', to: 'authentication#logout', as: 'logout'
  get 'relogin', to: 'authentication#relogin', as: 'relogin'
  get 'confirm', to: 'authentication#confirm', as: 'confirm'
  post 'authenticate', to: 'authentication#authenticate', as: 'authenticate'
  get 'go_to', to: 'authentication#go_to', as: 'go_to'
end
