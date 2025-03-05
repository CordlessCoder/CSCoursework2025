use std::fmt::Debug;

use axum::{Json, extract::ws::Utf8Bytes, http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, postgres::PgPoolOptions};
use tokio::sync::broadcast;

use crate::models::{Bucket, Histogram, Reply};
use thiserror::Error;

pub struct AppState {
    pub pool: PgPool,
    pub reply_notifications: (broadcast::Sender<Utf8Bytes>, broadcast::Receiver<Utf8Bytes>),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AgeHistogramOptions {
    age_min: u32,
    age_max: u32,
    age_buckets: u32,
}

impl AppState {
    pub async fn initialize() -> Self {
        dotenvy::dotenv().unwrap();

        let db_url = std::env::var("DATABASE_URL")
            .expect("Please provide the database URL in the DATABASE_URL env var.");
        let pool = PgPoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await
            .unwrap();
        let reply_notifications = broadcast::channel(32);
        AppState {
            pool,
            reply_notifications,
        }
    }
    pub async fn add_reply(&self, reply: &Reply) {
        let Reply { age, agree, name } = reply;
        sqlx::query!(
            "INSERT INTO replies (age, agree, name) VALUES ($1, $2, $3)",
            *age as i16,
            agree,
            name.as_str()
        )
        .execute(&self.pool)
        .await
        .unwrap();
        self.reply_notifications
            .0
            .send(Utf8Bytes::from(serde_json::to_string(reply).unwrap()))
            .unwrap();
    }
    pub async fn get_replies(&self, latest: u32) -> Vec<Reply> {
        sqlx::query!(
            "SELECT * FROM replies ORDER BY id DESC LIMIT $1",
            latest as i64
        )
        .map(|r| Reply {
            age: r.age.try_into().unwrap_or(0),
            name: r.name,
            agree: r.agree,
        })
        .fetch_all(&self.pool)
        .await
        .unwrap()
    }
    pub async fn get_age_histogram(
        &self,
        AgeHistogramOptions {
            age_min,
            age_max,
            age_buckets,
        }: AgeHistogramOptions,
    ) -> Result<Histogram, HistogramError> {
        if age_buckets <= 2 {
            return Err(HistogramError::TooFewBuckets(age_buckets));
        };
        let buckets = sqlx::query!(
            "SELECT width_bucket(age, $1, $2, $3), count(*) FROM replies group by 1 order by 1",
            age_min as i32,
            age_max as i32,
            (age_buckets - 1) as i32,
        )
        .map(|r| {
            let bucket = r.width_bucket.unwrap_or(0) as u32;
            let bucket_width = (age_max - age_min) as f64 / (age_buckets - 2) as f64;
            bucket_width;
            Bucket {
                count: r.count.unwrap_or(0) as u64,
                start: (bucket != 0).then(|| {
                    age_min as f64 + bucket_width * (bucket - 1).min(age_buckets - 2) as f64
                }),
                end: (bucket != age_buckets)
                    .then_some(age_min as f64 + bucket_width * bucket as f64),
            }
        })
        .fetch_all(&self.pool)
        .await
        .unwrap();
        Ok(Histogram {
            range: (age_min as f64, age_max as f64),
            buckets,
        })
    }
}

#[derive(Debug, Clone, Error, Serialize)]
pub enum HistogramError {
    #[error(
        "Cannot calculate {0} buckets. 2 buckets are always required for any values beyond the range of the histogram"
    )]
    TooFewBuckets(u32),
}

impl IntoResponse for HistogramError {
    fn into_response(self) -> axum::response::Response {
        use HistogramError::*;
        #[derive(Serialize)]
        struct ErrorResponse {
            message: String,
        }

        let message = self.to_string();
        let status = match self {
            TooFewBuckets(_) => StatusCode::EXPECTATION_FAILED,
        };
        (status, Json(ErrorResponse { message })).into_response()
    }
}
