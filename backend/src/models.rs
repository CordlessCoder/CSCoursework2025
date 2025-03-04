use std::sync::Arc;

use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Reply {
    pub age: u8,
    pub agree: bool,
    pub name: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Bucket {
    pub start: Option<f64>,
    pub end: Option<f64>,
    pub count: u64,
}
#[derive(Debug, Deserialize, Serialize)]
pub struct Histogram {
    pub range: (f64, f64),
    pub buckets: Vec<Bucket>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Statistics {
    pub age_histogram: Histogram,
}
