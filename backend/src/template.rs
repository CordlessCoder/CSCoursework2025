use handlebars::Handlebars;
use std::collections::HashMap;
use tokio::fs;

pub async fn register_partials(registry: &mut Handlebars<'_>) {
    let mut dir = tokio::fs::read_dir("content/partials/").await.unwrap();
    while let Ok(Some(entry)) = dir.next_entry().await {
        if !entry.metadata().await.unwrap().is_file() {
            continue;
        }
        let path = entry.path();
        let Some(name) = path.file_stem() else {
            panic!("content/template_data contained a file with no filename")
        };
        let content = fs::read_to_string(&path).await.unwrap();
        registry
            .register_partial(&name.to_string_lossy(), content)
            .unwrap();
    }
}
pub async fn render_page(registry: &mut Handlebars<'_>, name: &str) -> String {
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
        .register_template_file(name, format!("templates/{name}.html"))
        .unwrap();
    registry.render(name, &data).unwrap()
}
