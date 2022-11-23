# 簡單 Docker 使用手冊

## 安裝 Docker & NVIDIA Docker

## 使用步驟

1. 下載這個儲存庫

    ```shell
     git clone https://github.com/ycpss91255/docker_template
    ```

2. 切換到對應分支
    - 請使用正確的位置替換 `<download_file_path>`

        ```shell
        cd <download_file_path>
        ```

    - 請用正確的分支名稱替換 `<branch_name>`

        ```shell
        git checkout <branch_name>
        ```

3. 複製 Docker 資料夾到工作區中
    - 請用正確的位置替換 `<workspace_path>`

        ```shell
        cp ./docker <workspace_path>
        ```

4. 建構 Docker 映像檔
    - 請用正確的位置替換 `<workspace_path>`

        ```shell
        ./<workspace_path>/docker/build.sh
        ```

5. 執行 Docker 容器
    - 請用正確的位置替換 `<workspace_path>`

        ```shell
        ./<workspace_path>/docker/run.sh
        ```

6. 享受 Docker
