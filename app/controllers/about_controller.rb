class AboutController < ApplicationController
  def welcome
  end

  def open
  end

  def comparison
    @providers = {
      'Promise' => {
        sso: true,
        private: true,
        pseudonymous: true,
        decentralised: true,
        centralised: true,
        non_profit: true,
        nothing_to_learn: true,
        open_source: true,
      },
      'OpenID' => {
        sso: true,
        private: false,
        pseudonymous: false,
        decentralised: true,
        centralised: true,
        non_profit: true,
        nothing_to_learn: false,
        open_source: true,
      },
      'SQRL' => {
        sso: true,
        private: true,
        pseudonymous: true,
        decentralised: true,
        centralised: false,
        non_profit: true,
        nothing_to_learn: false,
        open_source: true,
      },
      'Google' => {
        sso: true,
        private: false,
        pseudonymous: false,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: true,
        open_source: false,
      },
      'Facebook' => {
        sso: true,
        private: false,
        pseudonymous: false,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: true,
        open_source: false,
      },
      'Apple' => {
        sso: true,
        private: false,
        pseudonymous: true,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: true,
        open_source: false,
      },
      'Beyond Identity' => {
        sso: true,
        private: false,
        pseudonymous: nil,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: false,
        open_source: false,
      },
      'Trusona' => {
        sso: true,
        private: false,
        pseudonymous: nil,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: false,
        open_source: false,
      },
      'Auth0' => {
        sso: false,
        private: false,
        pseudonymous: true,
        decentralised: false,
        centralised: true,
        non_profit: false,
        nothing_to_learn: true,
        open_source: false,
      },
    }
    @order_of_providers = [
      "Promise",
      "OpenID",
      "SQRL",
      "Google",
      "Facebook",
      "Apple",
      "Beyond Identity",
      "Trusona",
      "Auth0",
    ]
    @order_of_attributes = %i[
      sso
      private
      nothing_to_learn
      non_profit
      pseudonymous
      open_source
      decentralised
      centralised
    ]
  end

  def data
    @email = 'test@example.com'
    @password = ENV.fetch('PROMISE_PASSWORD_FOR_TEST_USER') { 'secret' }
    @auth = Authentication::Services::Authenticate.new(
      email: @email,
      password: @password,
      relying_party_id: 'oase.app'
    )
    begin
      @auth.register!
    rescue Authentication::Email::AlreadyClaimed
      @auth.existing!
    end

    @id_token = Authentication::Services::GetIdToken.new(
      user_id: @auth.user_id, 
      relying_party_id: 'example.com',
      vault_key: @auth.vault_key,
    ).id_token

    @personal_data = Authentication::Vault.personal_data(@auth.user_id, @auth.vault_key)

    @vault_content = Authentication::VaultContent.find(@auth.user_id)

    @vault_key_for_recovery = Authentication::VaultKeysForRecovery.find(@auth.user_id)
  end
end
