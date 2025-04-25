use eyre::Result;
use fig_os_shim::Context;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

const MEMORY_FILE_NAME: &str = "memory_output/memories.json";
const MEMORY_PROMPT_FILE_NAME: &str = "prompts/generate_memories_prompt.txt";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Memory {
    pub content: String,
}

pub struct MemoryManager {
    ctx: Arc<Context>,
}

impl MemoryManager {
    pub async fn new(ctx: Arc<Context>) -> Result<Self> {
        Ok(Self { ctx: ctx.clone() })
    }

    pub async fn load_memory_prompt(&self) -> Result<String> {
        let prompt_file = self.ctx.fs().chroot_path_str(MEMORY_PROMPT_FILE_NAME);
        if self.ctx.fs().exists(&prompt_file) {
            let content = self.ctx.fs().read_to_string(&prompt_file).await?;
            Ok(content)
        } else {
            Ok(String::new())
        }
    }

    pub async fn load_memories(&self) -> Result<Vec<Memory>> {
        let memory_file = self.ctx.fs().chroot_path_str(MEMORY_FILE_NAME);
        if self.ctx.fs().exists(&memory_file) {
            let content = self.ctx.fs().read_to_string(&memory_file).await?;
            Ok(serde_json::from_str(&content)?)
        } else {
            Ok(Vec::new())
        }
    }

    pub async fn save_memories(&self, memories: &Vec<Memory>) -> Result<(), eyre::Error> {
        let memory_file = self.ctx.fs().chroot_path_str(MEMORY_FILE_NAME);
        let content = serde_json::to_string(memories)?;
        self.ctx.fs().write(&memory_file, content).await?;
        Ok(())
    }

    pub async fn parse_memory_response(&self, response: &str) -> Result<Vec<Memory>> {
        self.ctx
            .fs()
            .write("memory_output/raw_memory_output.txt", response)
            .await?;
        let re = Regex::new(r"<INFERENCE>([\s\S]*?)</INFERENCE>")?;
        if let Some(captures) = re.captures(response) {
            if let Some(json_str) = captures.get(1) {
                // Parse the JSON string
                let memories: Vec<Memory> = serde_json::from_str(json_str.as_str())?;
                Ok(memories)
            } else {
                Ok(Vec::new())
            }
        } else {
            Ok(Vec::new())
        }
    }
}
