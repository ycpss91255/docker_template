# Steps for usage

## English version

1. Download this github repository

    ```shell
    git clone https://github.com/ycpss91255/docker_template
    ```

2. Copy to your project directory
3. Adjust Dockerfile to suit your needs
4. Build Docker image (run build.sh)
    - `<docker_path>` replace with real to docker location

    ```shell
    ./<docker_path>/build.sh
    ```

5. Run Docker container (run run.sh)
    - `<docker_path>` replace with real to docker location

    ```shell
    ./<docker_path>/run.sh
    ```

6. Enjoy Docker support

### Pay attention to the following points when using

1. Docker image name wil be named based on the follwing order:
    - Dockerfile name (prefix), ex: Dockerfile_test, the image name will be test.
    - Workspace folder name (suffix), ex: test_ws, the image name will be test.
    - If neither exists, the image name will be unknown.

2. Docker container name will be named in the format of `<user>/<container>` and named based on the following order:
    - `<user>`:
        - Docker login username.
        - system username.
        - if neither exists, `<user>` will be named initial.
    - `<container>`:
        - Workspace folder name (suffix), ex: test_ws, the container name will be test.
        - Dockerfile name (prefix), ex: Dockerfile_test, the container name will be test.
        - If neither exists, the container name will be unknown.

3. Dockerfile and entrypoint.sh notes:
    - It is possible to add hardware architecture as a suffix to the file name.
       - ex: Dockerfile_x86_64 or Dockerfile_aarch64.
       - ex: entrypoint_x86_64.sh or entrypoint_aarch64.sh
    - If there are multiple Dockerfile or entrypoint.s file in the docker folder, the script will use the one that matches the current hardware architecture.

---

## 中文版本

1. 下載這個 Github 儲存庫。

    ```shell
    git clone https://github.com/ycpss91255/docker_template
    ```

2. 複製到你的專案目錄中。
3. 調整 Dockerfile 以符合你的需求。
4. 建構 Docker image (執行 build.sh)。
    - `<docker_path>`: 替換為真實的 docker 資料夾位置。

    ```shell
    ./<docker_path>/build.sh
    ```

5. 執行 Docker container (執行 run.sh)。
    - `<docker_path>`: 替換為真實的 docker 資料夾位置。

    ```shell
    ./<docker_path>/run.sh
    ```

6. 享受 Docker 支援。

### 使用時需要注意以下幾點

1. Docker image 名稱會使用以下的順序進行命名：
    - Docker 資料夾名稱 (前綴)，例如：Docker_test，image 名稱就是 test。
    - 工作區資料夾名稱 (後綴)，例如：test_ws，image 名稱就是 test。
    - 以上都沒有，image 名稱為 unknown。

2. Docker container 名稱會以 `<user>/<container>` 的格式並且搭配以下順序進行命名：
    - `<user>`：
        - Docker 登入的使用者名稱。
        - 系統的使用者名稱。
        - 以上都沒有，`<user>` 名稱就是 initial。
    - `<container>`：
        - 工作區資料夾名稱 (前綴)，例如：test_ws，container 名稱就是 test。
        - Docker 資料夾名稱 (後綴)，例如：Docker_test，container 名稱就是 test。
        - 以上都沒有，container 名稱為 unknown。

3. Dockerfile 與 entrypoint.sh 注意事項：
    - 可允許增加硬體系統架構作為檔案名稱的後綴。
        - 例如：Dockerfile_x86_64 或 Dockerfile_aarch64。
        - 例如：entrypoint_x86_64.sh 或 entrypoint_arrch64.sh。
    - 如果在 docker 資料夾底下有多個 Dockerfile 或 entrypoint.sh 會使用與當前電腦系統架構相同檔案。
