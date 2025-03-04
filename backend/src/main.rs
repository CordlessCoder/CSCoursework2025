use axum::{
    Form, Json, Router,
    extract::{Query, State},
    response::{Html, IntoResponse},
    routing::{any, get, post},
};
use handlebars::Handlebars;
use models::Reply;
use serde::{Deserialize, Serialize};
use state::{AgeHistogramOptions, AppState};
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
        .route("/ws", any(websocket::ws_handshake))
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

#[derive(Debug, Deserialize, Serialize)]
struct ReplyForm {
    age: u8,
    name: String,
    agree: Option<String>,
}

async fn add_reply(State(state): State<Arc<AppState>>, Form(reply): Form<ReplyForm>) {
    let ReplyForm { age, name, agree } = reply;
    let reply = Reply {
        age,
        name,
        agree: agree.is_some(),
    };
    state.add_reply(&reply).await;
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
    let histogram = state.get_age_histogram(hist_options).await;
    let histogram = match histogram {
        Ok(hist) => hist,
        Err(err) => return err.into_response(),
    };
    Json(histogram).into_response()
}
