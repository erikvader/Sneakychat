// NOTE: for debugging the API

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"
import cat from "./cat.js"

window.api_test = {}
const at = window.api_test

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//

// Connect and listen for sneaks.
at.connect = function(jwt, username) {
  at.socket = new Socket("/api/ws", {params: {token: jwt}})
  // Finally, connect to the socket:
  at.socket.connect()

  // Now that you are connected, you can join channels with a topic:
  at.channel = at.socket.channel("user:" + username, {})

  at.channel.on("recv_sneak", payload => {
    console.log("du fick en ny sneak!", payload.msg);
  })

  at.channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
}

// send a sneak to someone
at.client_send_sneak = recvs => {
  at.channel.push("new_sneak", {
    to: recvs.map(r => ({recv_user: r, recv_host: "localhost"})),
    img: cat
  })
    .receive("ok", resp => {console.log("bild uppladades", resp)})
    .receive("error", resp => {console.log("fel med uppladning utav bild", resp)})
}

at.get_follows = () => {
  at.channel.push("follows")
    .receive("ok", resp => {console.log("dina vänner är:", resp.follows)})
}

at.register = (user, pass, elektronisk_brevpost) => {
  const resp = fetch(
    "/api/auth/identity/register",
    {
      method: 'POST',
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({username: user, password: pass, email: elektronisk_brevpost})
    }
  )

  resp
    .then(resp => resp.json())
    .then(resp => console.log(resp))
    .catch(err => console.error(err));
}

at.login = (user, pass) => {
  const resp = fetch(
    "/api/auth/identity/callback",
    {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({username: user, password: pass})
    }
  )

  const json_prom = resp.then(resp => resp.json())
  json_prom
    .then(resp => console.log(resp))
    .catch(err => console.error(err));
  return json_prom;
}

at.login_n_connect = (user, pass) => {
  at.login(user, pass)
    .then(resp => at.connect(resp.token, user))
}

at.server_send_sneak = (receiver, sender, url) => {
  const resp = fetch(
    `/users/${receiver}/inbox`,
    {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        "@context": "asdasd",
        "type": "Create",
        "actor": `http://localhost/users/${sender}`,
        "to": `http://localhost/users/${receiver}`,
        "object": {
          "type": "Link",
          "href": url,
          "mediaType": "image/png"
        }
      })
    }
  )

  resp
    .then(resp => resp.json())
    .then(resp => console.log(resp))
    .catch(err => console.error(err));
}

at.follow = (friend) => {
    at.channel.push("follow", {"friend": `http://localhost/users/${friend}`})
        .receive("ok", resp => console.log("ok", resp))
        .receive("error", resp => console.error("error", resp))
}
at.unfollow = (not_friend) => {
    at.channel.push("unfollow", {"not_friend": `http://localhost/users/${not_friend}`})
        .receive("ok", resp => console.log("ok", resp))
        .receive("error", resp => console.error("error", resp))
}

at.get_feed = before => {
  at.channel.push("feed", before ? {before: before} : {})
    .receive("ok", resp => console.log("ok", resp))
}

at.open = (sneak_recv_id) => {
    at.channel.push("open", {"sneak_recv": sneak_recv_id})
    .receive("ok", resp => console.log("ok", resp))
    .receive("error", resp => console.error("error", resp))
}

export default at.socket
