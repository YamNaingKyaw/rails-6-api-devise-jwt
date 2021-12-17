# Rails Api With Devise-JWT

[![Ruby](https://badgen.net/badge/ruby/v3.0.0/:color?icon=ruby&color=red)](https://www.ruby-lang.org/en/news/2021/11/24/ruby-3-0-3-released/)
[![Rails](https://badgen.net/badge/rails/v6.1.4.1/:color?color=red)](https://rubygems.org/gems/rails/versions/6.1.4.1)
[![Devise-JWT](https://badgen.net/badge/devise/v4.8.0/:color?color=yellow)](https://rubygems.org/gems/devise/versions/4.8.0)
[![Devise-JWT](https://badgen.net/badge/devise-jwt/v0.9.0/:color?color=yellow)](https://rubygems.org/gems/devise-jwt/versions/0.9.0)

## Configure Rack Middleware

```
# Gemfile
gem 'rack-cors'
```

```
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource(
     '*',
     headers: :any,
     expose: ["Authorization"],
     methods: [:get, :patch, :put, :delete, :post, :options, :show]
    )
  end
end
```

## Add the needed Gems

```
# Gemfile
gem 'devise'
gem 'devise-jwt'
```

Then, do

```
bundle install
```

## Configure devise

By running the following command to run a generator

```
$ rails generate devise:install
```

```
# config/initializers/devise.rb
config.navigational_formats = []
```

```
# config/environments/development.rb
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

## Create User model

```
$ rails generate devise User
```

```
$ rails db:create
$ rails db:migrate
```

## Create devise controllers and routes

To create two controllers (sessions, registrations) to handle sign ups and sign in.

```
$ rails g devise:controllers users -c sessions registrations
```

responding to JSON requests

```
class Users::SessionsController < Devise::SessionsController
  respond_to :json
end
```

```
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
end
```

```
# routes.rb
Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
end
```

## Configure devise-jwt

```
# config/initializers/devise.rb
config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.fetch(:secret_key_base)
    jwt.dispatch_requests = [
      ['POST', %r{^/login$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/logout$}]
    ]
    jwt.expiration_time = 30.minutes.to_i
end
```

## Set up a revocation strategy

More documentation [devise-jwt gem](https://github.com/waiting-for-dev/devise-jwt).Now only use JTIMatcher.
To run

```
$ rails g migration addJtiToUsers jti:string:index:unique
```

```
def change
  add_column :users, :jti, :string, null: false
  add_index :users, :jti, unique: true
  # If you already have user records, you will need to initialize its `jti` column before setting it to not nullable. Your migration will look this way:
  # add_column :users, :jti, :string
  # User.all.each { |user| user.update_column(:jti, SecureRandom.uuid) }
  # change_column_null :users, :jti, false
  # add_index :users, :jti, unique: true
end
```

```
# models/user.rb
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
end
```

```
def jwt_payload
  super.merge('mistd-testing' => 'devise-jwt and rails')
end
```

and then run:

```
$ rails db:migrate
```

## Add respond_with method

```
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: {code: 200, message: 'Signed up sucessfully.'},
        data: resource
      }
    else
      render json: {
        status: {message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"}
      }, status: :unprocessable_entity
    end
  end
end
```

```
class Users::SessionsController < Devise::SessionsController
  respond_to :json
  private

  def respond_with(resource, _opts = {})
    render json: {
      status: {code: 200, message: 'Logged in sucessfully.'},
      data: resource
    }, status: :ok
  end

  def respond_to_on_destroy
    if current_user

      render json: {
        status: 200,
        message: "logged out successfully"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
```

## Adding a '/current_user' endpoint

```
$ rails g controller current_user index
```

```
# routes.rb
get '/current_user', to: 'current_user#index'
```

```
class CurrentUserController < ApplicationController
  before_action :authenticate_user!
  def index
    render json: current_user, status: :ok
  end
end
```

## If JWT token pass

```
# models/user.rb
attr_accessor :current_token

def on_jwt_dispatch(token, _payload)
  # Token send with json
  self.current_token = token
  # do somthings
end
```

```
def respond_with(resource, _opts = {})
  render json: {
    status: { code: 200, message: 'Logged in sucessfully.' },
    data: resource,
    token: resource.current_token
  }, status: :ok
end
```
