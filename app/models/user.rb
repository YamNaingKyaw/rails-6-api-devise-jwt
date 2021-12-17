class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :validatable

  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Token send with json
  attr_accessor :current_token

  def jwt_payload
    super.merge('mistd-testing' => 'devise-jwt and rails')
  end

  def on_jwt_dispatch(token, _payload)
    # Token send with json
    self.current_token = token
    # do somthings
  end
end
