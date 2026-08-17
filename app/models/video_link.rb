# Value object over Exercise#reference_url.
#
# Practitioners paste whatever they have -- a YouTube watch link, a Shorts
# link, youtu.be, Vimeo, or something we cannot embed at all. This normalises
# those into "can I show a thumbnail", "can I embed it", and "where does it
# point", so views never parse URLs themselves.
class VideoLink
  YOUTUBE = %r{(?:youtube\.com/(?:watch\?(?:.*&)?v=|shorts/|embed/|live/)|youtu\.be/)([\w-]{11})}
  VIMEO   = %r{vimeo\.com/(?:video/)?(\d+)}

  attr_reader :url

  def initialize(url)
    @url = url.to_s.strip
  end

  def self.wrap(url) = url.present? ? new(url) : nil

  def provider
    return :youtube if youtube_id
    return :vimeo   if vimeo_id
    :other
  end

  def embeddable? = provider != :other

  # Privacy-preserving host: no cookie until the viewer actually plays.
  def embed_url
    case provider
    when :youtube then "https://www.youtube-nocookie.com/embed/#{youtube_id}?rel=0&autoplay=1"
    when :vimeo   then "https://player.vimeo.com/video/#{vimeo_id}?autoplay=1"
    end
  end

  # Vimeo thumbnails need an API round trip, so only YouTube gets one. Anything
  # else falls back to a plain card in the view.
  def thumbnail_url
    "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg" if youtube_id
  end

  def host
    URI.parse(url).host&.delete_prefix("www.")
  rescue URI::InvalidURIError
    nil
  end

  private

  def youtube_id = @youtube_id ||= url[YOUTUBE, 1]
  def vimeo_id   = @vimeo_id   ||= url[VIMEO, 1]
end
