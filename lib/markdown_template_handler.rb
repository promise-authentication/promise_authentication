class MarkdownTemplateHandler
  def call(template, source)
    compiled = ActionView::Template.registered_template_handler(:erb).call(template, source)
    "Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true)).render(begin;#{compiled};end).html_safe"
  end
end

ActionView::Template.register_template_handler(:md, MarkdownTemplateHandler.new)
