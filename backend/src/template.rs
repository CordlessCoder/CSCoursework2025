use std::collections::HashMap;

use tokio::fs;

pub async fn render_data_page() -> String {
    let mut registry = handlebars::Handlebars::new();
    let mut dir = tokio::fs::read_dir("content/template_data/").await.unwrap();
    let mut data = HashMap::new();
    while let Ok(Some(entry)) = dir.next_entry().await {
        if !entry.metadata().await.unwrap().is_file() {
            continue;
        }
        let path = entry.path();
        let Some(name) = path.file_stem() else {
            panic!("content/template_data contained a file with no filename")
        };
        let content = fs::read_to_string(&path).await.unwrap();
        data.insert(name.to_string_lossy().to_string(), content);
    }
    registry
        .register_template_file("data_page", "templates/data.html")
        .unwrap();
    registry.render("data_page", &data).unwrap()
}
