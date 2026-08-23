class Empresa < ApplicationRecord
  has_many :usuarios, dependent: :restrict_with_error

  validates :nome, presence: true
end
