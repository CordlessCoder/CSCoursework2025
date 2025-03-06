window.plotting = {
  paper_bgcolor: "rgba(255,255,255, 0)",
  paper_fgcolor: "rgba(255,255,255, 0)",
  plot_bgcolor: "rgba(255,255,255, 0)",
  draw_callbacks: {},
  agree: 0,
  disagree: 0,
  age_histogram: {},
};
let data_callback = (id, data, redraw) => {
  let draw = (force) => {
    if (!force && redraw && !redraw()) {
      return;
    }
    Plotly.react(
      id,
      data.data(),
      { ...data.layout(), ...plotting },
      { responsive: true },
    );
  };
  draw();
  window.plotting.draw_callbacks[id] = draw;
};

let width = window.screen.width;
let wide = () => width >= 1100;

const AGE_MIN = 15;
const AGE_MAX = 80;
const AGE_BUCKETS = 15;
const BUCKET_WIDTH = (AGE_MAX - AGE_MIN) / (AGE_BUCKETS - 2);

async function getreplies() {
  let reply_fetch = fetch("./list_replies?latest=5").then((res) => res.json());
  let reply_stats = fetch(
    `./stats?age_min=${AGE_MIN}&age_max=${AGE_MAX}&age_buckets=${AGE_BUCKETS}`,
  ).then((res) => res.json());
  let reply_table = document.getElementById("replies");
  let row_count = reply_table.getElementsByTagName("tr").length;
  let replies = await reply_fetch;
  data_callback(
    "plots",
    {
      data: () => {
        let new_x = [];
        let new_y = [];
        let new_text = [];
        let new_width = [];
        const bucket_width = window.plotting.age_histogram.bucket_width || 0;
        for (const bucket of window.plotting.age_histogram.buckets || []) {
          let x = bucket.start + bucket_width / 2;
          if (bucket.start == null) {
            x = bucket.end - bucket_width / 2;
          }
          let y = bucket.count;
          let text = `${bucket.start ? bucket.start : ""}..${bucket.end ? bucket.end : ""}`;
          new_x.push(x);
          new_y.push(y);
          new_text.push(text);
          new_width.push(bucket_width);
          console.log(x, y, text);
        }
        return [
          {
            values: [window.plotting.agree, window.plotting.disagree],
            labels: ["Agree", "Disagree"],
            textinfo: "label+percent",
            textposition: "outside",
            automargin: true,
            type: "pie",
            name: "Agree Statistics",
          },
          {
            x: new_x,
            y: new_y,
            text: new_text,
            width: new_width,
            xaxis: "x2",
            yaxis: "y2",
            type: "bar",
            name: "Respondent Age Statistics",
          },
        ];
      },
      layout: () => {
        width = window.screen.width;
        return {
          // colorway: ["#f88a9e", "#92D7FF"],
          colorway: ["#ae66fd", "#7680ff"],
          newshape: { line: { color: "#ff0000" } },
          title: {
            text: "Reply Statistics(realtime)",
          },
          grid: {
            rows: wide() ? 1 : 2,
            columns: wide() ? 2 : 1,
            pattern: "independent",
          },
          showlegend: false,
          xaxis: {
            anchor: "y",
          },
          xaxis2: {
            anchor: "y2",
            side: "bottom",
            title: {
              text: "Age (years)",
            },
            linecolor: "rgba(68, 65, 61, 0.3)",
            gridcolor: "rgba(68, 65, 61, 0.3)",
          },
          yaxis: {
            anchor: "x",
            domain: [wide() ? 0 : 0.6, 1],
          },
          yaxis2: {
            anchor: "x2",
            overlaying: "y",
            side: "right",
            title: {
              text: "Number of replies",
            },
            domain: [0, wide() ? 1 : 0.5],
            linecolor: "rgba(68, 65, 61, 0.3)",
            gridcolor: "rgba(68, 65, 61, 0.3)",
          },
        };
      },
    },
    () => {
      let old_wide = wide();
      width = window.screen.width;
      return old_wide != wide();
    },
  );
  addEventListener("resize", () => {
    Object.values(window.plotting.draw_callbacks).forEach((cb) => cb());
  });
  console.log("Loaded replies", replies);
  while (row_count-- > 1) {
    reply_table.deleteRow(1);
  }
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
  await reply_stats.then((data) => {
    window.plotting.agree = data.agree.agree;
    window.plotting.disagree = data.agree.disagree;
    window.plotting.age_histogram = data.age_histogram;
    Object.values(window.plotting.draw_callbacks).forEach((cb) => cb(true));
  });
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
      if (agree) {
        window.plotting.agree++;
      } else {
        window.plotting.disagree++;
      }
      let found = false;
      for (let i = 0; i < window.plotting.age_histogram.buckets.length; i++) {
        const bucket = window.plotting.age_histogram.buckets[i];
        const above_start = !bucket.start || bucket.start <= age;
        const below_end = !bucket.end || bucket.end >= age;
        if (above_start && below_end) {
          window.plotting.age_histogram.buckets[i].count++;
          found = true;
          break;
        }
      }
      if (!found) {
        // We need to insert a new bucket
        let start, end;
        if (age < AGE_MIN) {
          start = null;
          end = AGE_MIN;
        } else if (age > AGE_MAX) {
          start = AGE_MAX;
          end = null;
        } else {
          start = Math.floor(age / BUCKET_WIDTH) * BUCKET_WIDTH;
          end = start + BUCKET_WIDTH;
        }
        window.plotting.age_histogram.buckets.push({
          start: start,
          end: end,
          count: 1,
        });
      }
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
      Object.values(window.plotting.draw_callbacks).forEach((cb) => cb(true));
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
    // refetch replies
    setTimeout(() => {
      startWebsocket();
      getreplies();
    }, 5000);
  };
}
startWebsocket();

window.addEventListener("DOMContentLoaded", async function () {
  let first_replies = getreplies();
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
    if (~form_age.value.indexOf("e")) {
      form_age.setCustomValidity("Age cannot contain e notation");
      return;
    }
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
  await first_replies;
});
