#![allow(unused)]
use axum::{
    Json, Router,
    extract::{ConnectInfo, Query, State, WebSocketUpgrade},
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::{any, get},
};
use axum_extra::TypedHeader;
use models::Reply;
use state::{AgeHistogramOptions, AppState};
use std::{fmt::Display, net::SocketAddr, sync::Arc};
use tower_http::trace::{DefaultMakeSpan, TraceLayer};
use tracing::level_filters::LevelFilter;
mod models;
mod state;
mod template;
mod websocket;

#[tokio::main]
async fn main() {
    let data_page = template::render_data_page().await;

    let state = AppState::initialize().await;
    let state = Arc::new(state);

    tracing_subscriber::fmt()
        .with_ansi(true)
        // .with_span_events(FmtSpan::CLOSE)
        .with_max_level(LevelFilter::DEBUG)
        .with_line_number(true)
        .init();

    let app = Router::new()
        .route("/", get(root))
        .route("/data", get(Html(data_page)))
        .route("/reply", get(add_reply))
        .route("/list_replies", get(list_replies))
        .route("/stats", get(stats))
        .route("/ws", any(websocket::ws_handshake))
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

async fn root() -> impl IntoResponse {
    "Hello, world!"
}

async fn add_reply(Query(reply): Query<Reply>, State(state): State<Arc<AppState>>) {
    state.add_reply(&reply).await;
}
async fn list_replies(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    Json(state.get_replies().await)
}

async fn stats(
    Query(hist_options): Query<AgeHistogramOptions>,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let histogram = state.get_age_histogram(hist_options).await;
    let histogram = match histogram {
        Ok(hist) => hist,
        Err(err) => return err.into_response(),
    };
    Json(histogram).into_response()
}
