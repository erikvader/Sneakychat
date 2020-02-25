defmodule SneakyWeb.Lib.Auth do
    import Ecto.Query, only: [from: 2]
    
    def authenticate(username, password) do
        query = from a in Sneaky.Auth.Account,
          join: u in Sneaky.Auth.User, on: u.account_id == a.id,
          where: a.username == ^username,
          select: {a, u.password}
  
        case Sneaky.Repo.one(query) do
          nil -> {:error, :not_found}
          {acc, pass} ->
            if pass == password do
              {:ok, token, _claims} = Sneaky.Guardian.encode_and_sign(acc)
              {:ok, token}
            else
              {:error, :password}
            end
        end
      end
end