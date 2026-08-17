class CreateEnums < ActiveRecord::Migration[8.0]
  ENUMS = {
    user_role:              %w[practitioner client admin],
    practitioner_specialty: %w[trainer nutritionist],
    relationship_type:      %w[trainer nutritionist],
    relationship_status:    %w[invited active paused ended],
    unit_system:            %w[metric imperial],
    equipment_kind:         %w[dumbbell barbell kettlebell band machine
                               bodyweight cardio accessory other],
    # Cristian labels these himself: "3 series por ejercicio" vs "en circuito"
    execution_mode:         %w[straight_sets circuit interval paired],
    # calories and distance are as real as reps in these plans
    measure_kind:           %w[reps time distance calories],
    load_kind:              %w[none bodyweight external band machine],
    load_unit:              %w[lb kg],
    distance_unit:          %w[m km mi],
    program_version_status: %w[draft published archived],
    assignment_status:      %w[active completed paused abandoned],
    session_status:         %w[pending in_progress completed skipped],
    import_source_type:     %w[paste pdf],
    import_status:          %w[pending parsed review committed failed]
  }.freeze

  def up
    ENUMS.each { |name, values| create_enum name, values }
  end

  def down
    ENUMS.each_key { |name| drop_enum name }
  end
end
