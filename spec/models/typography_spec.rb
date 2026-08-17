require "rails_helper"

# Inter is self-hosted. If the font file goes missing the app still renders --
# it silently falls back to the system sans -- so nothing else in the suite
# would notice. These assertions are the only thing standing between a missing
# asset and a design that quietly degrades in production.
RSpec.describe "Typography" do
  let(:font_path) { Rails.root.join("app/assets/fonts/InterVariable.woff2") }
  let(:tailwind_css) { Rails.root.join("app/assets/tailwind/application.css").read }

  it "ships the Inter variable font" do
    expect(font_path).to exist,
      "missing app/assets/fonts/InterVariable.woff2 -- see the download step in the README"
  end

  it "ships a real woff2 rather than an error page" do
    skip "font not downloaded yet" unless font_path.exist?

    expect(font_path.size).to be > 50_000
    # woff2 files begin with the magic number "wOF2"
    expect(font_path.binread(4)).to eq("wOF2")
  end

  it "declares @font-face with the full variable weight range" do
    expect(tailwind_css).to include('font-family: "Inter"')
    expect(tailwind_css).to include("InterVariable.woff2")
    expect(tailwind_css).to match(/font-weight:\s*100\s+900/)
  end

  it "uses a relative url so Propshaft fingerprints it" do
    expect(tailwind_css).to include('url("InterVariable.woff2")')
    expect(tailwind_css).not_to match(%r{url\(["']/fonts/}),
      "an absolute path bypasses fingerprinting and breaks cache busting"
  end

  # The whole point of self-hosting: no third-party request at render time.
  it "requests no font from a third party in any view" do
    offenders = Dir.glob(Rails.root.join("app/views/**/*.erb")).select do |file|
      File.read(file).match?(/fonts\.(googleapis|gstatic)\.com/)
    end

    expect(offenders).to be_empty,
      "these views still fetch fonts from Google: #{offenders.map { |f| f.sub(Rails.root.to_s + "/", "") }.join(", ")}"
  end
end
