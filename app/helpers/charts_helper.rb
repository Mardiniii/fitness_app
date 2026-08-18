# Charts as inline SVG, drawn on the server.
#
# No charting library: the client screens have to work on gym wifi and inside
# the PWA, and a 90KB JS dependency to draw eight points is a bad trade. Inline
# SVG also means the chart is in the HTML the moment the page renders, with no
# layout shift and no empty box if a script fails.
#
# Axes are HTML, not SVG text. The SVG scales to the card it sits in, so any
# <text> inside it would scale too and the type would drift off the system.
# Keeping the ticks in HTML means they wear the same font, weight and tabular
# numerals as everything else, at a fixed size, at every width.
module ChartsHelper
  # A single trend line with a value axis.
  #
  # Values may contain nils (a session where this exercise carried no load),
  # which are skipped rather than drawn as zero -- plotting a gap as the floor
  # would invent a crash that never happened.
  # neutral: the chart has no opinion about which direction is good. Load going
  # up is progress, so that one is coloured by direction. Bodyweight going down
  # is usually the goal and sleep going up is, so colouring those by direction
  # would paint a win orange. In this system orange means NOW and green means
  # DONE -- neither means "bad" -- so a metric we cannot judge draws in ink.
  def sparkline(values, height: 56, label: nil, unit: nil, x_labels: nil, neutral: false)
    present = values.compact
    return tag.div(t("charts.no_data"), class: "cue") if present.size < 2

    min = present.min.to_f
    max = present.max.to_f
    span = (max - min).abs < Float::EPSILON ? 1.0 : (max - min)
    last_index = values.size - 1

    coords = values.each_with_index.filter_map do |value, i|
      next if value.blank?
      x = last_index.zero? ? 0 : (i.to_f / last_index) * 100
      y = height - ((value.to_f - min) / span) * height
      [ x.round(3), y.round(2) ]
    end

    stroke =
      if neutral
        "var(--color-ink)"
      else
        present.last >= present.first ? "var(--color-done)" : "var(--color-now)"
      end

    chart_frame(height: height, label: label,
                y_top: axis_value(max, unit), y_bottom: axis_value(min, unit),
                x_labels: x_labels) do
      safe_join([
        # viewBox x runs 0-100 so the line stretches to any card width, while
        # the y axis stays in real pixels. non-scaling-stroke keeps the line
        # 2px however far it is stretched.
        content_tag(:svg, viewBox: "0 0 100 #{height}", preserveAspectRatio: "none",
                          class: "block w-full overflow-visible",
                          style: "height:#{height}px", "aria-hidden": "true") do
          tag.polyline(points: coords.map { |x, y| "#{x},#{y}" }.join(" "),
                       fill: "none", stroke: stroke, "vector-effect": "non-scaling-stroke",
                       "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round")
        end,
        # The end marker is HTML, not an SVG circle: the plot is stretched
        # horizontally, and a circle in that space renders as an ellipse.
        tag.span(class: "chart-dot", style: "top:#{coords.last[1].fdiv(height) * 100}%;" \
                                            "background:#{stroke}")
      ])
    end
  end

  # Counts per period. Zero is a real value here -- a week with no sessions is
  # exactly the thing worth seeing -- so it renders as an empty slot rather
  # than being skipped.
  def bar_chart(values, height: 56, label: nil, x_labels: nil)
    return tag.div(t("charts.no_data"), class: "cue") if values.empty?

    counts = values.map(&:to_i)
    max = [ counts.max, 1 ].max

    chart_frame(height: height, label: label,
                y_top: max.to_s, y_bottom: "0", x_labels: x_labels) do
      content_tag(:div, class: "flex h-full items-end gap-[3px]") do
        safe_join(counts.map { |count|
          # A 2px floor so an empty week still shows a slot to read against.
          pct = count.zero? ? nil : (count * 100.0 / max)
          tag.span(class: "flex-1 rounded-[2px] #{count.zero? ? "bg-line" : "bg-done"}",
                   style: "height:#{pct ? pct.round(1) : 0}%; min-height:2px")
        })
      end
    end
  end

  # "+12%" / "-4%" / "—", coloured by direction. Green is DONE in this system,
  # and going up on load is what counts as done.
  def change_badge(pct)
    return tag.span("—", class: "change-badge text-ink-faint") if pct.nil?

    klass = pct.positive? ? "text-done" : (pct.negative? ? "text-now" : "text-ink-soft")
    tag.span("#{pct.positive? ? "+" : ""}#{pct}%", class: "change-badge #{klass}")
  end

  private

  # The axis furniture every chart shares: a value tick top and bottom, hairline
  # gridlines at exactly those two values, and the period at each end.
  def chart_frame(height:, label:, y_top:, y_bottom:, x_labels:)
    content_tag(:figure, class: "chart", role: "img", "aria-label": label) do
      safe_join([
        content_tag(:div, class: "flex gap-2") do
          safe_join([
            content_tag(:div, class: "flex w-[60px] shrink-0 flex-col justify-between text-right",
                              style: "height:#{height}px") do
              safe_join([ tag.span(y_top, class: "chart-tick"),
                          tag.span(y_bottom, class: "chart-tick") ])
            end,
            tag.div(yield, class: "chart-plot flex-1", style: "height:#{height}px")
          ])
        end,
        x_axis(x_labels)
      ].compact)
    end
  end

  def x_axis(x_labels)
    return nil if x_labels.blank?

    content_tag(:div, class: "mt-1.5 flex justify-between pl-[68px]") do
      safe_join(Array(x_labels).map { |text| tag.span(text, class: "chart-tick") })
    end
  end

  def axis_value(number, unit)
    formatted = number_with_precision(number, precision: 1, strip_insignificant_zeros: true)
    unit.present? ? "#{formatted} #{unit}" : formatted
  end
end
