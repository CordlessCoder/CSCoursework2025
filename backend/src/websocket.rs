use std::{net::SocketAddr, ops::ControlFlow, sync::Arc, time::Duration};

use axum::{
    body::Bytes,
    extract::{
        ConnectInfo, State, WebSocketUpgrade,
        ws::{CloseFrame, Message, Utf8Bytes, WebSocket},
    },
    response::IntoResponse,
};
use axum_extra::{TypedHeader, headers};
use futures::{SinkExt, StreamExt};
use tokio::{select, time};
use tracing::{debug, trace};

use crate::state::AppState;

pub async fn ws_handshake(
    ws: WebSocketUpgrade,
    user_agent: Option<TypedHeader<headers::UserAgent>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let user_agent = if let Some(TypedHeader(user_agent)) = &user_agent {
        user_agent.as_str()
    } else {
        "Unknown browser"
    };
    debug!(message = "connected to /ws", user_agent);
    // finalize the upgrade process by returning upgrade callback.
    // we can customize the callback by sending additional info such as address.
    ws.on_upgrade(move |socket| handle_socket(socket, addr, state))
}

/// Actual websocket statemachine (one will be spawned per connection)
async fn handle_socket(mut socket: WebSocket, who: SocketAddr, state: Arc<AppState>) {
    let mut reply_reciever = state.reply_notifications.1.resubscribe();
    loop {
        select! {
            reply = reply_reciever.recv() => {
                let Ok(reply) = reply else {
                    break;
                };
                if let Err(error) = socket.send(Message::Text(reply)).await {
                    debug!(message = "Failed to notify client of reply", address = %who, %error);
                    break;
                };
            },
            message = socket.recv() => {
                let Some(message) = message else {
                    break;
                };
                let message = match message {
                    Ok(msg) => msg,
                    Err(error) => {
                        trace!(message = "Websocket disconnected", address = %who, %error);
                        break;
                    },
                };
                match message {
                    Message::Ping(data) => {
                        debug!(message = "got ping", ?data, address = %who);
                        if let Err(error) = socket.send(Message::Pong(data.clone())).await {
                            debug!(message = "Failed to reply to ping", address = %who, %error);
                            break;
                        };
                    },
                    Message::Pong(_) => (),
                    Message::Text(data) => {
                        if data == "ping" {
                            debug!(message = "got text ping", address = %who);
                            if let Err(error) = socket.send(Message::Text(Utf8Bytes::from_static("pong"))).await {
                                debug!(message = "Failed to reply to ping", address = %who, %error);
                                break;
                            };
                        };
                        if data == "pong" {
                            debug!(message = "got text pong", address = %who);
                            if let Err(error) = socket.send(Message::Text(Utf8Bytes::from_static("pong"))).await {
                                debug!(message = "Failed to reply to ping", address = %who, %error);
                                break;
                            };
                        };
                    },
                    message => {
                        debug!(message = "Got unexpected message", content = ?message);
                    }
                }
            },
        }
    }
}
