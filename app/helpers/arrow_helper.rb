module ArrowHelper
  def arrow_right(css_class: '')
    content_tag(:svg,
                class: "inline-block #{css_class}",
                style: 'width: 1em; height: 1em; margin-left: 0.25em; vertical-align: -0.2em;',
                viewBox: '0 0 16 16',
                fill: 'currentColor',
                'aria-hidden': 'true') do
      tag(:path, d: 'M3 8h10M10 5l3 3-3 3', stroke: 'currentColor', fill: 'none', 'stroke-width': '1.8',
                 'stroke-linecap': 'round', 'stroke-linejoin': 'round')
    end.html_safe
  end

  def arrow_left(css_class: '')
    content_tag(:svg,
                class: "inline-block #{css_class}",
                style: 'width: 1em; height: 1em; margin-right: 0.25em; vertical-align: -0.2em;',
                viewBox: '0 0 16 16',
                fill: 'currentColor',
                'aria-hidden': 'true') do
      tag(:path, d: 'M13 8H3M6 11L3 8l3-3', stroke: 'currentColor', fill: 'none', 'stroke-width': '1.8',
                 'stroke-linecap': 'round', 'stroke-linejoin': 'round')
    end.html_safe
  end
end

