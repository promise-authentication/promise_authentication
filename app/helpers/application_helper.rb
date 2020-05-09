module ApplicationHelper
  def name
    'Promise'.html_safe
  end

  def navigation_link(*args, &block)
    is_active = current_page?(args[0]) || current_page?(args[1])
    classes = "#{ is_active ? 'text-gray-900 font-bold' : 'text-gray-800 font-normal'}"


    content_tag(:li, class: classes) do
      link_to *args, class: 'py-1 px-2 inline-block whitespace-no-wrap', &block
    end
  end

  def external_icon
    '<svg class="external_icon" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>'.html_safe
  end

  def internal_icon
    '<svg class="internal_icon" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M13.8284 10.1716C12.2663 8.60948 9.73367 8.60948 8.17157 10.1716L4.17157 14.1716C2.60948 15.7337 2.60948 18.2663 4.17157 19.8284C5.73367 21.3905 8.26633 21.3905 9.82843 19.8284L10.93 18.7269M10.1716 13.8284C11.7337 15.3905 14.2663 15.3905 15.8284 13.8284L19.8284 9.82843C21.3905 8.26633 21.3905 5.73367 19.8284 4.17157C18.2663 2.60948 15.7337 2.60948 14.1716 4.17157L13.072 5.27118" stroke="#4A5568" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>'.html_safe
  end
end
