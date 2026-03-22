# frozen_string_literal: true

Rails.autoloaders.main.ignore(Rails.root.join("lib/postal/message_db/migrations"))

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "api" => "Api"
  )
end
