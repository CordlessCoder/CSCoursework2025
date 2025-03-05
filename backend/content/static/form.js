async function getreplies() {
  let reply_fetch = fetch("./list_replies?latest=5").then((res) => res.json());
  let reply_table = document.getElementById("replies");
  let replies = await reply_fetch;
  console.log("Loaded replies", replies);
  for (let index = replies.length - 1; index >= 0; index--) {
    let data = replies[index];
    let row = reply_table.insertRow(1);
    let [cell0, cell1, cell2] = [
      row.insertCell(0),
      row.insertCell(1),
      row.insertCell(2),
    ];
    cell0.innerText = data.name;
    cell1.innerText = data.age;
    cell2.innerText = data.agree ? "Yes" : "No";
  }
}

function startWebsocket() {
  let socket = new WebSocket(
    `ws${window.location.href.startsWith("https") ? "s" : ""}://${window.location.host}/notification_ws`,
  );

  socket.onopen = function (e) {
    console.log(`Connection established ${e}`);
  };

  socket.onmessage = function (event) {
    console.log(`[message] Data received from server: ${event.data}`);
    let data = JSON.parse(event.data);
    console.log("[message] Parsed data", data);
    if (data["viewers"]) {
      let viewers = data.viewers;
      console.log(`Viewer count update: ${viewers}`);
      let count = document.getElementById("viewer_count");
      let to_be = document.getElementById("viewer_count_to_be");
      if (viewers == 1) {
        count.innerText = `1 visitor`;
        to_be.innerText = "is";
      } else {
        count.innerText = `${viewers} visitors`;
        to_be.innerText = "are";
      }
    } else if (data["name"]) {
      let name = data.name;
      let age = data.age;
      let agree = data.agree;
      console.log("New reply", name, age, agree);
      let reply_table = document.getElementById("replies");
      let row_count = reply_table.getElementsByTagName("tr").length;
      if (row_count >= 5) {
        reply_table.deleteRow(5);
      }
      let row = reply_table.insertRow(1);
      let [cell0, cell1, cell2] = [
        row.insertCell(0),
        row.insertCell(1),
        row.insertCell(2),
      ];
      cell0.innerText = name;
      cell1.innerText = age;
      cell2.innerText = agree ? "Yes" : "No";
    }
  };

  socket.onerror = function (error) {
    console.log("WebSocket error", error);
  };
  socket.onclose = function (event) {
    if (event.wasClean) {
      console.log(
        `[close] WebSocket connection closed cleanly, code=${event.code} reason=${event.reason}`,
      );
    } else {
      // e.g. server process killed or network down
      // event.code is usually 1006 in this case
      console.log("[close] WebSocket connection died");
    }
    // connection closed, discard old websocket and create a new one in 5s
    socket = null;
    setTimeout(startWebsocket, 5000);
    // refetch replies
    setTimeout(getreplies, 5000);
  };
}
startWebsocket();

let first_replies = getreplies();
window.addEventListener("DOMContentLoaded", async function () {
  let form_name = document.getElementById("name");
  let form_age = document.getElementById("age");
  let form_agree = document.getElementById("agree");
  let reply_form = document.getElementById("reply-form");
  let reply_submit = document.getElementById("reply-submit");
  form_name.oninput = function (_) {
    form_name.setCustomValidity("");
    if (form_name.value.length == 0) {
      form_name.setCustomValidity("Name cannot be empty");
      return;
    }
  };
  form_age.oninput = function (_) {
    form_age.setCustomValidity("");
    if (form_age.value.length == 0) {
      form_age.setCustomValidity("Age cannot be empty");
      return;
    }
  };
  reply_form.onsubmit = function (e) {
    form_name.setCustomValidity("");
    form_age.setCustomValidity("");
    e.preventDefault();
    let name = form_name.value;
    let age = form_age.value;
    let agree = form_agree.checked;
    console.log("Submit", name, age, agree);
    form_name.oninput(form_name);
    form_age.oninput(form_age);
    if (!reply_form.reportValidity()) {
      return false;
    }
    reply_submit.disabled = true;
    reply_submit.value = "Submitted";
    reply_submit.classList.add("disabled");
    fetch(
      `./reply?name=${encodeURIComponent(name)}&age=${encodeURIComponent(age)}&agree=${encodeURIComponent(agree)}`,
      { method: "POST" },
    );
    return false;
  };
  let reply_table = document.getElementById("replies");
  let replies = await reply_fetch;
  console.log("Loaded replies", replies);
  for (let index = replies.length - 1; index >= 0; index--) {
    let data = replies[index];
    let row = reply_table.insertRow(1);
    let [cell0, cell1, cell2] = [
      row.insertCell(0),
      row.insertCell(1),
      row.insertCell(2),
    ];
    cell0.innerText = data.name;
    cell1.innerText = data.age;
    cell2.innerText = data.agree ? "Yes" : "No";
  }
  await first_replies;
});
