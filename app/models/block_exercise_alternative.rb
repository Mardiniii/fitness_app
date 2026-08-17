# "15 remo en trx o progresion de pull up en Smith o barra" -- one prescribed
# slot, several acceptable movements. The client picks based on what is free.
class BlockExerciseAlternative < ApplicationRecord
  belongs_to :block_exercise
  belongs_to :exercise

  validates :block_exercise_id, uniqueness: { scope: :exercise_id }
  validate  :not_the_prescribed_exercise

  private

  def not_the_prescribed_exercise
    return if block_exercise.blank?
    errors.add(:exercise_id, :already_prescribed) if exercise_id == block_exercise.exercise_id
  end
end
