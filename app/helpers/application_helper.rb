module ApplicationHelper
  def name
    'Promise'.html_safe
  end

  def navigation_link(*args, &block)
    is_active = current_page?(args[0]) || current_page?(args[1])
    classes = "#{ is_active ? 'font-black text-gray-900' : 'font-medium text-gray-700 tracking-wide'}"

    content_tag(:li, class: classes) do
      link_to *args, class: 'pr-12 md:px-2 lg:px-4 py-2 md:pb-4 md:pt-5 inline-block whitespace-no-wrap ', &block
    end
  end
end
