# frozen_string_literal: true

class Server < ApplicationRecord
  # Idk how to store random bytes in redis (Dang you NULL!)
  KEY_CHARS = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "", "/", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "@", "[", "\\", "]", "^", "_", "`", "{", "|", "}", "~"
  ].shuffle.freeze

  before_validation(on: :create) { self.public_id ||= SecureRandom.uuid }

  before_create :generate_key
  after_create :create_server_setting
  after_create :create_default_reward

  attribute :public_id, :string
  attribute :server_id, :string
  attribute :community_id, :integer
  attribute :server_name, :text
  attribute :server_key, :text
  attribute :server_ip, :string
  attribute :server_port, :string
  attribute :server_start_time, :datetime
  attribute :server_version, :string
  enum server_visibility: {private: 0, public: 1}, _default: :public, _suffix: :visibility
  attribute :ui_version, :string
  attribute :disconnected_at, :datetime
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :community

  has_many :cooldowns, dependent: :destroy
  has_many :logs, dependent: :destroy
  has_many :server_mods, dependent: :destroy
  has_many :server_rewards, dependent: :destroy
  has_one :server_setting, dependent: :destroy
  has_many :territories, dependent: :destroy
  has_many :user_gamble_stats, dependent: :destroy
  has_many :user_notification_preferences, dependent: :destroy
  has_many :user_notification_routes, dependent: :destroy, foreign_key: :source_server_id

  validates :public_id, uniqueness: true, presence: true

  def self.find_by_server_id(id)
    order(:server_id).where("server_id ilike ?", id).first
  end

  def self.clientize
    all.map(&:clientize)
  end

  def token
    @token ||= {access: public_id, secret: server_key}
  end

  def recently_created?(time: 30.seconds.ago)
    created_at.between?(time, Time.current)
  end

  def clientize
    {
      id: server_id,
      name: "[#{server_id}] #{server_name.presence || "Server name not provided"}"
    }
  end

  def version
    Semantic::Version.new(server_version || "2.0.0")
  end

  def version?(expected_version)
    version >= Semantic::Version.new(expected_version)
  end

  def v2?
    version?("2.0.0")
  end

  def v2_ui?
    Semantic::Version.new(ui_version || "1.0.0") >= "2.0.0"
  end

  private

  def generate_key
    return if server_key.present?

    self.server_key = Array.new(64).map { KEY_CHARS.sample }.join
  end

  def create_default_reward
    server_rewards.create!(server_id: id)
  end
end
