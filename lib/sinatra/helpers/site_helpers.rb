module SiteHelpers
  def sections
    @sections ||= @sitemap
      .top_level_entries(@route || '/')
      .select { |route, entry| !!entry[:directory] }
  end

  def site_pages
    @site_pages ||= @sitemap
      .top_level_entries(@route || '/')
      .select { |route, entry| !entry[:directory] }
  end

  def breadcrumbs
    @breadcrumbs ||= @sitemap.ancestry_for(@route || '/')
      .reject { |crumb| crumb.keys.first.end_with?('/') }
  end
end
