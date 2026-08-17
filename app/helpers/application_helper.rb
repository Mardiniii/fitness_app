module ApplicationHelper
  # Cristian's taxonomy values are Spanish domain terms stored verbatim
  # ("aceleracion", "tren_inferior"). This renders their display label, or an
  # em dash when the axis genuinely does not apply -- mobility work has no
  # aceleración/fuerza quality, and cardio has no movilidad/fortaleza purpose.
  def enum_label(scope, value)
    return "—" if value.blank?

    t("enums.#{scope}.#{value}", default: value.to_s.tr("_", " ").upcase)
  end

  def axis_chip(scope, value, tone: :ink)
    return tag.span("—", class: "text-ink-faint") if value.blank?

    classes = {
      ink:  "border-line text-ink-soft",
      now:  "border-now text-now",
      done: "border-done text-done"
    }.fetch(tone)

    tag.span enum_label(scope, value),
             class: "inline-block rounded-brand border px-1.5 py-0.5 " \
                    "text-[9.5px] font-extrabold uppercase tracking-[0.08em] #{classes}"
  end
end
