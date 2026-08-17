# Value object over Exercise#reference_url.
#
# Practitioners paste whatever they have -- a YouTube watch link, a Shorts
# link, youtu.be, Vimeo, or something we cannot embed at all. This normalises
# those into "can I show a thumbnail", "can I embed it", and "where does it
# point", so views never parse URLs themselves.
class VideoLink
  YOUTUBE = %r{(?:youtube\.com/(?:watch\?(?:.*&)?v=|shorts/|embed/|live/)|youtu\.be/)([\w-]{11})}
  VIMEO   = %r{vimeo\.com/(?:video/)?(\d+)}
  # Cristian's current storage. Both the share link and the older open?id= form.
  DRIVE   = %r{drive\.google\.com/(?:file/d/([\w-]{10,})|open\?id=([\w-]{10,}))}
  # Legacy: he used iCloud before Drive. Those links cannot be embedded at all,
  # so they render as an honest link-out rather than a broken frame.
  ICLOUD  = %r{icloud\.com/}

  attr_reader :url

  def initialize(url)
    @url = url.to_s.strip
  end

  def self.wrap(url) = url.present? ? new(url) : nil

  def provider
    return :youtube if youtube_id
    return :vimeo   if vimeo_id
    return :drive   if drive_id
    return :icloud  if url.match?(ICLOUD)
    :other
  end

  # Derived from embed_url, not from provider: iCloud is a *recognised*
  # provider but has no embeddable form, and treating "known" as "embeddable"
  # would render an iframe with an empty src.
  def embeddable? = embed_url.present?

  # Privacy-preserving host: no cookie until the viewer actually plays.
  def embed_url
    case provider
    when :youtube then "https://www.youtube-nocookie.com/embed/#{youtube_id}?rel=0&autoplay=1"
    when :vimeo   then "https://player.vimeo.com/video/#{vimeo_id}?autoplay=1"
    when :drive   then "https://drive.google.com/file/d/#{drive_id}/preview"
    end
  end

  # Drive only renders for files shared as "anyone with the link". A restricted
  # file shows a Google sign-in prompt inside the frame instead of the video,
  # which is confusing rather than broken -- so the form warns about it.
  def sharing_caveat? = provider == :drive

  # Vimeo thumbnails need an API round trip, so only YouTube gets one. Anything
  # else falls back to a plain card in the view.
  def thumbnail_url
    return "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg" if youtube_id
    return "https://drive.google.com/thumbnail?id=#{drive_id}&sz=w640" if drive_id

    nil # Vimeo needs an API round trip; iCloud and others have none
  end

  def host
    URI.parse(url).host&.delete_prefix("www.")
  rescue URI::InvalidURIError
    nil
  end

  private

  def youtube_id = @youtube_id ||= url[YOUTUBE, 1]
  def vimeo_id   = @vimeo_id   ||= url[VIMEO, 1]

  def drive_id
    @drive_id ||= begin
      match = url.match(DRIVE)
      match && (match[1] || match[2])
    end
  end
end
