require 'sass'
require 'slim'

module RenderHelpers
  def render_view(path)
    slim clean_view_path(path).to_sym
  end

  def render_style(path)
    scss path.to_sym, views: 'assets/stylesheets', style: :compressed
  end

  private

  def clean_view_path(path)
    path
      .sub("#{settings.views.split('/').last}/", '')
      .sub('.slim', '')
  end
end
