use actix_multipart::Multipart;
use actix_web::{web, App, HttpRequest, HttpResponse, HttpServer, Responder};
use futures_util::StreamExt as _;
use percent_encoding::percent_decode_str;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::{env, fs};
use tokio::fs::File;
use tokio::io::AsyncWriteExt;

const HTTP_PORT_ARG_KEY: &str = "port";
const UPLOAD_DIR_ARG_KEY: &str = "dir";

// 请求成功的响应
const RESPONSE_SUCESS: &str = r#"{"code":"1","msg":"success"}"#;

// 上传失败的响应
const RESPONSE_UPLOAD_NO_FILENAME: &str = r#"{"code":"2","msg":"No filename provided"}"#;
const RESPONSE_UPLOAD_PATH_ERROR: &str = r#"{"code":"3","msg":"require http path is /upload/**"}"#;
const RESPONSE_UPLOAD_CREATE_FILE_FAILED: &str = r#"{"code":"4","msg":"Could not create file"}"#;
const RESPONSE_UPLOAD_CREATE_DIR_FAILED: &str = r#"{"code":"5","msg":"Could not dir"}"#;
const RESPONSE_UPLOAD_WRITE_FILE_FAILED: &str = r#"{"code":"6","msg":"Error writing to file"}"#;
const RESPONSE_UPLOAD_FAILED: &str = r#"{"code":"7","msg":"Error uploading file"}"#;

// 删除失败的响应
const RESPONSE_DELETE_FAILED: &str = r#"{"code":"8","msg":"Failed to delete file"}"#;
const RESPONSE_DELETE_FILE_NOT_FOUND: &str = r#"{"code":"9","msg":"File not found"}"#;

fn get_unique_filename(filepath: &Path) -> PathBuf {
    let mut unique_path = filepath.to_path_buf();
    let mut count = 1;

    while unique_path.exists() {
        let filename = filepath.file_stem().unwrap().to_str().unwrap();
        let extension = filepath.extension().unwrap_or_default().to_str().unwrap();
        unique_path = filepath.with_file_name(format!("{}-{}.{}", filename, count, extension));
        count += 1;
    }

    unique_path
}

async fn upload_file(
    mut payload: Multipart,
    req: HttpRequest,
    hostdir: Arc<String>,
) -> impl Responder {
    while let Some(Ok(mut field)) = payload.next().await {
        let content_disposition = field.content_disposition().unwrap();
        let filename = content_disposition
            .get_filename()
            .map_or("".to_string(), |f| f.to_string());

        if filename.is_empty() {
            return HttpResponse::BadRequest().body(RESPONSE_UPLOAD_NO_FILENAME);
        }
        let path = percent_decode_str(req.path()).decode_utf8().unwrap();
        let mut path = &path["/upload".len()..];
        if !path.is_empty() {
            if path.starts_with("/") {
                path = &path[1..];
            } else {
                return HttpResponse::BadRequest().body(RESPONSE_UPLOAD_PATH_ERROR);
            }
        }
        let mut filepath: PathBuf = PathBuf::from(&*hostdir);
        if !path.is_empty() {
            filepath = filepath.join(path);
        }

        // 创建上传目录
        if let Err(_) = fs::create_dir_all(&filepath) {
            return HttpResponse::InternalServerError().body(RESPONSE_UPLOAD_CREATE_DIR_FAILED);
        }

        filepath = filepath.join(filename);

        filepath = get_unique_filename(&filepath);
        // println!("upload_file-filePath={}", filepath.to_string_lossy());

        let mut f = match File::create(&filepath).await {
            Ok(file) => file,
            Err(_) => {
                return HttpResponse::InternalServerError().body(RESPONSE_UPLOAD_CREATE_FILE_FAILED)
            }
        };

        while let Some(chunk) = field.next().await {
            match chunk {
                Ok(data) => {
                    if let Err(_) = f.write_all(&data).await {
                        let _ = fs::remove_file(&filepath);
                        return HttpResponse::InternalServerError()
                            .body(RESPONSE_UPLOAD_WRITE_FILE_FAILED);
                    }
                }
                Err(_) => {
                    let _ = fs::remove_file(&filepath);
                    return HttpResponse::InternalServerError().body(RESPONSE_UPLOAD_FAILED);
                }
            }
        }
    }
    HttpResponse::Ok().body(RESPONSE_SUCESS)
}

async fn delete_file(path: web::Path<String>, hostdir: Arc<String>) -> impl Responder {
    let path = path.into_inner();
    let filepath = Path::new(&*hostdir).join(&path);
    // println!("delete_file-filePath={}", filepath.to_string_lossy());

    if filepath.exists() {
        if filepath.is_file() {
            if let Err(_) = fs::remove_file(&filepath) {
                return HttpResponse::InternalServerError().body(RESPONSE_DELETE_FAILED);
            }
        } else if filepath.is_dir() {
            if let Err(_) = fs::remove_dir_all(&filepath) {
                return HttpResponse::InternalServerError().body(RESPONSE_DELETE_FAILED);
            }
        }
        HttpResponse::Ok().body(RESPONSE_SUCESS)
    } else {
        HttpResponse::NotFound().body(RESPONSE_DELETE_FILE_NOT_FOUND)
    }
}

/// 启动命令：cargo run port=8080 dir=./uploads
/// 假设 HTTP_PORT 为 8080
/// 上传文件: curl -F "file=@path_to_your_file" http://127.0.0.1:8080/upload
/// 删除文件: curl -X DELETE http://127.0.0.1:8080/delete/your_filename
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let mut argmap = HashMap::new();
    for arg in &args[1..] {
        let mut split = arg.splitn(2, '=');
        if let (Some(key), Some(value)) = (split.next(), split.next()) {
            argmap.insert(key.to_string(), value.to_string());
        } else {
            eprintln!("error arg: {}", arg);
            std::process::exit(1);
        }
    }

    let port = argmap
        .get(HTTP_PORT_ARG_KEY)
        .unwrap_or(&"8080".to_string())
        .clone();
    println!("port:{}", port);

    let dir = Arc::new(
        argmap
            .get(UPLOAD_DIR_ARG_KEY)
            .unwrap_or(&"./files".to_string())
            .clone(),
    );
    println!("dir:{}", dir);

    let _ = HttpServer::new(move || {
        let dir = Arc::clone(&dir);
        let dir2 = Arc::clone(&dir);
        App::new()
            .route(
                "/upload{tail:.*}",
                web::post().to(move |payload: Multipart, req: HttpRequest| {
                    upload_file(payload, req, Arc::clone(&dir))
                }),
            )
            .route(
                "/delete/{tail:.*}",
                web::delete()
                    .to(move |path: web::Path<String>| delete_file(path, Arc::clone(&dir2))),
            )
    })
    .bind(format!("0.0.0.0:{}", port))?
    .run()
    .await;

    println!("stop");

    Ok(())
}
