defmodule Sneaky.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    # accounts ################################################################
    create table(:accounts) do
      add :username, :string
      add :url, :string

      timestamps()
    end

    create unique_index(:accounts, [:username, :url], name: :accounts_username_url)

    # users ###################################################################
    create table(:users) do
      add :email, :string
      add :password, :string
      add :role, :integer
      add :is_banned, :boolean
      add :account_id, references(:accounts)

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:account_id])

    # follows #################################################################
    create table(:follows) do
      add :subject, references(:accounts)
      add :follows, references(:accounts)
    end

    create unique_index(:follows, [:subject, :follows], name: :follows_subject_follows)

    # sneak ###################################################################
    create table(:sneaks) do
      add :url, :string
      add :sender, references(:accounts)
    end

    create unique_index(:sneaks, [:url, :sender], name: :sneaks_url_sender)

    create table(:sneak_recvs) do
      add :recv, references(:accounts)
      add :sneak_id, references(:sneaks)
    end

    create unique_index(:sneak_recvs, [:recv, :sneak_id], name: :sneak_recvs_sneak_id)
  end
end
