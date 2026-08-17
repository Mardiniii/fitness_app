# Structural checks on rendered HTML.
#
# These exist because of a real bug: a `button_to` (which renders its own
# <form>) was nested inside a `form_with`. Nested forms are invalid HTML, so
# browsers discard the inner tag and its hidden _method=delete field is
# absorbed by the OUTER form -- turning "Save" into a delete.
#
# Nothing else in the suite catches that. ERB parsed fine. The route existed.
# The controller was correct. Only the markup was wrong.
module HtmlStructure
  module_function

  # Raw-string scan rather than a DOM parse: HTML parsers *also* silently drop
  # nested form tags, which would hide exactly what we are looking for.
  def nested_forms(html)
    depth = 0
    offenders = []

    html.to_s.scan(%r{<\s*(/?)form\b}i) do
      closing = Regexp.last_match(1) == "/"
      if closing
        depth -= 1 if depth.positive?
      else
        offenders << Regexp.last_match.begin(0) if depth.positive?
        depth += 1
      end
    end

    offenders
  end
end

RSpec::Matchers.define :have_no_nested_forms do
  match do |html|
    @offsets = HtmlStructure.nested_forms(html)
    @offsets.empty?
  end

  failure_message do |html|
    excerpt = @offsets.first(3).map { |i| html[[ i - 90, 0 ].max, 190].gsub(/\s+/, " ") }
    "expected no nested <form> elements, found #{@offsets.size}:\n  " + excerpt.join("\n  ")
  end
end
