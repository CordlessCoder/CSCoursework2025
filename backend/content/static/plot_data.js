window.plotting = {
  paper_bgcolor: "rgba(255,255,255, 0)",
  paper_fgcolor: "rgba(255,255,255, 0)",
  plot_bgcolor: "rgba(255,255,255, 0)",
  draw_callbacks: {},
  xaxis: {
    linecolor: "rgba(68, 65, 61, 0.3)",
    gridcolor: "rgba(68, 65, 61, 0.3)",
  },
  yaxis: {
    linecolor: "rgba(68, 65, 61, 0.3)",
    gridcolor: "rgba(68, 65, 61, 0.3)",
  },
  xaxis2: {
    linecolor: "rgba(68, 65, 61, 0.3)",
    gridcolor: "rgba(68, 65, 61, 0.3)",
  },
  yaxis2: {
    linecolor: "rgba(68, 65, 61, 0.3)",
    gridcolor: "rgba(68, 65, 61, 0.3)",
  },
};
let data_callback = (id, data) => {
  console.log(id, data);
  let draw = () =>
    Plotly.newPlot(
      id,
      data.data,
      { ...data.layout, ...plotting },
      { responsive: true },
    );
  draw();
  window.plotting.draw_callbacks[id] = draw;
};

window.addEventListener("DOMContentLoaded", async function () {
  await fetch("graphs_combined.json")
    .then((res) => res.json())
    .then((data) => {
      let keys = Array.from(Object.keys(data));
      keys
        // Needed to get around a bug which breaks drawing graphs
        // when they're drawn in a pathological order
        .sort((a, b) => {
          return a > b ? -1 : a < b ? 1 : 0;
        });

      console.log(keys);
      keys.forEach((name) => {
        data_callback(name, data[name]);
      });
    });
});
