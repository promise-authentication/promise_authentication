class Admin::EmailsController < ApplicationController
  before_action :authenticate_relying_party

  def create
    begin
      Authentication::RelyingPartyEmail.create(
        relying_party_id: params[:relying_party_id],
        hashed_email: hashed_email
      )
    rescue ActiveRecord::RecordNotUnique
    end

    head :created
  end

  def destroy
    Authentication::RelyingPartyEmail.where(
      relying_party_id: params[:relying_party_id],
      hashed_email: hashed_email
    ).delete_all

    head :ok
  end

  private

  def authenticate_relying_party
    unless params[:secret_key] == relying_party.secret_key_base64
      head :forbidden
    end
  end

  def relying_party
    @relying_party ||= Authentication::RelyingParty.new(id: params[:relying_party_id])
  end

  def hashed_email
    Authentication::HashedEmail.from_cleartext(params[:email])
  end

end
