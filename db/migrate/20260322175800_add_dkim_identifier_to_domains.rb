class AddDKIMIdentifierToDomains < ActiveRecord::Migration[7.0]
  def change
    add_column :domains, :dkim_identifier, :string
  end
end
