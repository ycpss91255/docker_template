# Easy Docker manual

## Install Docker & NVIDIA Docker

## Use Step

1. Download this repository

    ```shell
     git clone https://github.com/ycpss91255/docker_template
    ```

2. Switch to corresponding branch
    - Please replace `<download_file_path>` with the correct location

        ```shell
        cd <download_file_path>
        ```

    - Please replace `<branch_name>` with the correct branch name

        ```shell
        git checkout <branch_name>
        ```

3. Copy Docker folder to workspace
    - Please replace `<workspace_path>` with the correct location

        ```shell
        cp ./docker <workspace_path>
        ```

4. Build Docker image
    - Please replace `<workspace_path>` with the correct location

        ```shell
        ./<workspace_path>/docker/build.sh
        ```

5. run Docker container
    - Please replace `<workspace_path>` with the correct location

        ```shell
        ./<workspace_path>/docker/run.sh
        ```

6. Enjoy Docker
