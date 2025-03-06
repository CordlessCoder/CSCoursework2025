use axum::{
    Json, Router,
    extract::{Query, State},
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::{any, get, post},
};
use handlebars::Handlebars;
use models::{Histogram, Reply};
use serde::{Deserialize, Serialize};
use state::{AgeHistogramOptions, AgreeStats, AppState, HistogramError};
use std::{net::SocketAddr, sync::Arc};
use tower_http::{
    services::ServeDir,
    trace::{DefaultMakeSpan, TraceLayer},
};
use tracing::level_filters::LevelFilter;
mod models;
mod state;
mod template;
mod websocket;

#[tokio::main]
async fn main() {
    let state = AppState::initialize().await;
    let state = Arc::new(state);

    tracing_subscriber::fmt()
        .with_ansi(true)
        // .with_span_events(FmtSpan::CLOSE)
        .with_max_level(LevelFilter::DEBUG)
        .with_line_number(true)
        .init();

    let mut handlebars = Handlebars::new();
    template::register_partials(&mut handlebars).await;
    let app = Router::new()
        .route(
            "/",
            get(Html(template::render_page(&mut handlebars, "index").await)),
        )
        .route(
            "/data",
            get(Html(template::render_page(&mut handlebars, "data").await)),
        )
        .route(
            "/survey",
            get(Html(template::render_page(&mut handlebars, "survey").await)),
        )
        .route("/reply", post(add_reply))
        .route("/list_replies", get(list_latest_replies))
        .route("/stats", get(stats))
        .route("/notification_ws", any(websocket::ws_handshake))
        .fallback_service(ServeDir::new("content/static/"))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::default().include_headers(true)),
        )
        .with_state(state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await
    .unwrap();
}

async fn add_reply(
    State(state): State<Arc<AppState>>,
    Query(reply): Query<Reply>,
) -> impl IntoResponse {
    if reply.name.len() > 80 {
        return (StatusCode::NOT_ACCEPTABLE, "Name cannot be this long").into_response();
    }
    state.add_reply(&reply).await;
    ().into_response()
}
#[derive(Debug, Serialize, Deserialize)]
struct ReplyLimit {
    #[serde(default = "default_latest")]
    latest: u8,
}
fn default_latest() -> u8 {
    5
}

async fn list_latest_replies(
    State(state): State<Arc<AppState>>,
    Query(ReplyLimit { latest }): Query<ReplyLimit>,
) -> impl IntoResponse {
    Json(state.get_replies(latest as u32).await)
}

async fn stats(
    Query(hist_options): Query<AgeHistogramOptions>,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    #[derive(Debug, Serialize)]
    struct Stats {
        age_histogram: Histogram,
        agree: AgreeStats,
    }
    let age_histogram = state.get_age_histogram(hist_options).await;
    let age_histogram = match age_histogram {
        Ok(hist) => hist,
        Err(err) => return err.into_response(),
    };
    let agree = state.get_agree_stats().await;
    let stats = Stats {
        age_histogram,
        agree,
    };
    Json(stats).into_response()
}
