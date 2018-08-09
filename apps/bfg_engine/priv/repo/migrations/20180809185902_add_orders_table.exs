defmodule BfgEngine.Repo.Migrations.AddOrdersTable do
  use Ecto.Migration

  def change do
    create table("orders") do
      add :order, :map, null: false
      add :inserted_at, :utc_datetime, null: false
    end
  end
end
