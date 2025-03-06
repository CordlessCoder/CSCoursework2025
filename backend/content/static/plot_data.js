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
  let draw = () =>
    Plotly.react(
      id,
      data.data,
      { ...data.layout, ...plotting },
      { responsive: true },
    );
  draw();
  window.plotting.draw_callbacks[id] = draw;
};
await Promise.all([
  fetch("./monthly_temp_plot.json")
    .then((res) => res.json())
    .then((data) => data_callback("monthly_temp_plot", data)),
  fetch("./yearly_temp_plot.json")
    .then((res) => res.json())
    .then((data) => data_callback("yearly_temp_plot", data)),
  fetch("./glacier_mass_temp_change_combined.json")
    .then((res) => res.json())
    .then((data) =>
      data_callback("glacier_mass_temp_change_combined_plot", data),
    ),
]);
