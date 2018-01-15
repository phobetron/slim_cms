module TextHelpers
  def titleize(text)
    text.to_s.gsub(/_+/, ' ').gsub(/\b('?[a-z])/) { $1.capitalize }
  end
end
