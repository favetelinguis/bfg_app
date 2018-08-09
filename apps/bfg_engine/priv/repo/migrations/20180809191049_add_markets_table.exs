defmodule BfgEngine.Repo.Migrations.AddMarketsTable do
  use Ecto.Migration

  def change do
    create table("markets") do
      add :market, :map, null: false
      add :inserted_at, :utc_datetime, null: false
    end
  end
end
