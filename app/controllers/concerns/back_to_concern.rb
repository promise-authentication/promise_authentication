module BackToConcern
  extend ActiveSupport::Concern

  included do
    before_action :move_back
    helper_method :back_to
  end

  def back_to(params)
    with_back = params.merge(back: true)
    url = yield with_back if block_given?
    helpers.link_to '&larr; '.html_safe + t('.cancel'), url, class: 'text-secondary pr-3'
  end

  def move_back
    return unless params[:back]

    flash[:slide_class] = 'a-slide-in-from-left'
    redirect_to url_for(params.clone.permit!.except(:back).merge(only_path: true))
  end
end
