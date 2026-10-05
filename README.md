step 1. docker buildx build \
    --platform linux/arm64 \
    -t shipwright-arm64 \
    --load .

step 2. docker run --rm \
    -v "$HOME/SOH-Leveled:/output" \
    shipwright-arm64
