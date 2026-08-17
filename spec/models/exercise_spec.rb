require "rails_helper"

RSpec.describe Exercise do
  describe "slug and search_name" do
    it "derives a slug and an accent-stripped search name" do
      ex = create(:exercise, name_es: "Liberación posterior sin soltar punta de pies")
      expect(ex.slug).to eq("liberacion-posterior-sin-soltar-punta-de-pies")
      expect(ex.search_name).to eq("liberacion posterior sin soltar punta de pies")
    end

    it "disambiguates a colliding slug starting at 2" do
      create(:exercise, name_es: "Sentadilla")
      second = create(:exercise, name_es: "Sentadilla")
      expect(second.slug).to eq("sentadilla-2")
    end
  end

  describe ".search" do
    before do
      create(:exercise, name_es: "Sentadilla con barra libre")
      create(:exercise, name_es: "Press de banca con mancuernas")
    end

    it "matches a short substring that trigram alone would miss" do
      expect(Exercise.search("sent").map(&:name_es)).to include("Sentadilla con barra libre")
    end

    it "ignores accents" do
      expect(Exercise.search("PRESS DE BANCA").map(&:name_es))
        .to include("Press de banca con mancuernas")
    end

    it "returns everything for a blank query" do
      expect(Exercise.search(nil).count).to eq(2)
    end
  end

  describe "#deletable?" do
    let(:exercise) { create(:exercise) }

    it "is true when nothing references it" do
      expect(exercise).to be_deletable
    end

    it "is false once a block prescribes it" do
      create(:block_exercise, exercise: exercise)
      expect(exercise.reload).not_to be_deletable
    end

    # Being merely an alternative counts: deleting would silently change a
    # prescribed substitution.
    it "is false when it is only a stated alternative" do
      create(:block_exercise_alternative_record, exercise: exercise)
      expect(exercise.reload).not_to be_deletable
    end
  end

  # Regression: Rails' `enum ... validate: true` rejects nil unless allow_nil is
  # passed, which broke db:seed on every nullable enum column.
  describe "nullable taxonomy axes" do
    it "accepts nil for quality and purpose" do
      ex = build(:exercise, training_quality: nil, training_purpose: nil)
      expect(ex).to be_valid
    end

    # Passing `validate:` to Rails' enum deliberately trades the raise for a
    # validation error -- which is the whole point: a bad value from a form
    # should surface as a field error, not a 500.
    it "rejects a value outside the enum as invalid rather than raising" do
      exercise = build(:exercise)
      exercise.muscle_region = "torso"

      expect(exercise).not_to be_valid
      expect(exercise.errors[:muscle_region]).to be_present
    end

    it "still refuses to persist the bad value" do
      exercise = build(:exercise)
      exercise.muscle_region = "torso"

      expect(exercise.save).to be(false)
    end
  end
end
