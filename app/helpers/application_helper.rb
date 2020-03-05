module ApplicationHelper
  def name
    'PROMISE'
  end

  def navigation_link(*args, &block)
    is_active = current_page?(args[0]) || current_page?(args[1])
    classes = "px-1 #{ is_active ? 'text-black underline' : ''}"

    content_tag(:li, class: classes) do
      link_to *args, &block
    end
  end
end
