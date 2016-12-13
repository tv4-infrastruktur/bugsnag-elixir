defmodule Bugsnag.HttpTestClient do
  def post("https://notify.bugsnag.com", [body: body, headers: [{"Content-Type", "application/json"}]]) do
    body
    |> Poison.decode!(keys: :atoms)
    |> notify
  end

  defp notify(%{events: [%{exceptions: [%{message: "some_serious_error"}]}]}) do
    %HTTPotion.ErrorResponse{message: "something went wrong"}
  end
  defp notify(%{apiKey: _}) do
    %HTTPotion.Response{status_code: 200}
  end
end
