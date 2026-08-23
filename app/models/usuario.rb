class Usuario < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :empresa, optional: true

  enum :papel, { colaborador: 0, admin: 1 }, default: :colaborador

  validates :nome, presence: true

  def admin_da_empresa?
    admin? && empresa.present?
  end
end
