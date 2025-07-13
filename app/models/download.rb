# frozen_string_literal: true

class Download < ApplicationRecord
  before_create :generate_uuid

  mount_uploader :file, DownloadUploader

  attribute :uuid, :uuid
  attribute :version, :string
  attribute :current_release, :boolean
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
