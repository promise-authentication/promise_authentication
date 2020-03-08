module ApplicationHelper
  def name
    'PROMISE'
  end

  def navigation_link(*args, &block)
    is_active = current_page?(args[0]) || current_page?(args[1])
    classes = "#{ is_active ? 'text-black underline' : ''}"


    content_tag(:li, class: classes) do
      link_to *args, class: 'py-2 px-1 inline-block', &block
    end
  end

  def external_icon
    '<svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>'.html_safe
  end
end
