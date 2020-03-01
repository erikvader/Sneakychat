defmodule SneakyWeb.SneakController do
  use SneakyWeb, :controller

  def get(conn, %{"imgpath" => path}) do
    minioport = Application.get_env(:ex_aws, :s3)[:port]
    my_host = Application.get_env(:sneaky, SneakyWeb.Endpoint)[:url][:host]
    scheme = Application.get_env(:ex_aws, :s3)[:scheme]
    redirect(conn, external: "#{scheme}#{my_host}:#{minioport}/sneakies/#{path}")
  end
end
