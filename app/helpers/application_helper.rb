module ApplicationHelper
  def markdown(string)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(string).html_safe
  end
end
