ARG IMAGE="osrf/ros:foxy-ros1-bridge"

FROM "${IMAGE}"

ARG ENTRYPOINT_FILE="entrypoint.sh"
ARG BRIDGE_FILE="bridge.yaml"

COPY --chmod=0755 "./${ENTRYPOINT_FILE}" "/entrypoint.sh"
COPY --chmod=0755 "./${BRIDGE_FILE}" "/bridge.yaml"

ENTRYPOINT ["/entrypoint.sh"]
# TODO: change to entrypoint.sh
CMD ["ros2", "run", "ros1_bridge", "dynamic_bridge"]
# CMD ["ros2", "run", "ros1_bridge", "parameter_bridge"]
