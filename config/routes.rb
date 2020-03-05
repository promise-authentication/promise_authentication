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
    get 'integration'
  end

  resources :relying_parties, :id => /.*/ do
    member do
      post 'setup'
    end
  end
end
