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
      add :subject_id, references(:accounts)
      add :follows_id, references(:accounts)

      timestamps()
    end

    create unique_index(:follows, [:subject_id, :follows_id], name: :follows_subject_follows)

    # sneak ###################################################################
    create table(:sneaks) do
      add :url, :string
      add :sender_id, references(:accounts)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:sneaks, [:url, :sender_id], name: :sneaks_url_sender)

    # sneak_recv ##############################################################
    create table(:sneak_recvs) do
      add :recv_id, references(:accounts)
      add :sneak_id, references(:sneaks)

      timestamps()
    end

    create unique_index(:sneak_recvs, [:recv_id, :sneak_id], name: :sneak_recvs_sneak_id)
  end
end
