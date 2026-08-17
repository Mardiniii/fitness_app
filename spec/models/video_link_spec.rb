require "rails_helper"

RSpec.describe VideoLink do
  describe "provider detection" do
    {
      "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view?usp=sharing" => :drive,
      "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view?usp=drive_link" => :drive,
      "https://drive.google.com/open?id=1A2b3C4d5E6f7G8h9I0jK" => :drive,
      "https://www.icloud.com/iclouddrive/0abCdEfGhIjK" => :icloud,
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => :youtube,
      "https://youtu.be/dQw4w9WgXcQ" => :youtube,
      "https://www.youtube.com/shorts/dQw4w9WgXcQ" => :youtube,
      "https://www.youtube.com/watch?list=PL1&v=dQw4w9WgXcQ" => :youtube,
      "https://vimeo.com/123456789" => :vimeo,
      "https://www.instagram.com/reel/Cabc123/" => :other
    }.each do |url, provider|
      it "recognises #{provider} in #{url[0, 46]}" do
        expect(described_class.new(url).provider).to eq(provider)
      end
    end
  end

  describe "#embeddable?" do
    it "is true for Drive, since /preview renders in an iframe" do
      link = described_class.new("https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view")
      expect(link).to be_embeddable
      expect(link.embed_url).to eq("https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/preview")
    end

    # iCloud is a *recognised* provider with no embeddable form. Deriving
    # embeddable? from provider rather than embed_url would render an iframe
    # with an empty src.
    it "is false for iCloud even though the provider is known" do
      link = described_class.new("https://www.icloud.com/iclouddrive/0abCdEfGhIjK")
      expect(link.provider).to eq(:icloud)
      expect(link).not_to be_embeddable
      expect(link.embed_url).to be_nil
    end
  end

  describe "#sharing_caveat?" do
    it "flags Drive, whose files default to restricted" do
      expect(described_class.new("https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view"))
        .to be_sharing_caveat
      expect(described_class.new("https://youtu.be/dQw4w9WgXcQ")).not_to be_sharing_caveat
    end
  end

  it "returns nil rather than a blank object for no URL" do
    expect(described_class.wrap(nil)).to be_nil
    expect(described_class.wrap("")).to be_nil
  end
end
