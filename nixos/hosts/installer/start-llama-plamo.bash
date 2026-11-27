# Prefer a local PLaMo-3-Translate GGUF stored on the writable SHARED_DATA
# partition (/mnt/shared) or the read-only MultiOS-USB partition
# (/run/loopback-host) so translation works offline without bundling unfree
# weights into the ISO.

shopt -s nullglob
candidates=(
	/mnt/shared/models/*plamo-3-translate-0.8b*.gguf
	/mnt/shared/*plamo-3-translate-0.8b*.gguf
	/run/loopback-host/models/*plamo-3-translate-0.8b*.gguf
	/run/loopback-host/*plamo-3-translate-0.8b*.gguf
)
shopt -u nullglob

if [ "${#candidates[@]}" -gt 0 ]; then
	exec llama-server \
		--model "${candidates[0]}" \
		--host 127.0.0.1 \
		--port 18080 \
		--ctx-size 8192 \
		--parallel 4 \
		--kv-unified \
		--flash-attn on
fi

exec llama-server \
	-hf pfnet/plamo-3-translate-0.8b-GGUF:Q4_K_M \
	--host 127.0.0.1 \
	--port 18080 \
	--ctx-size 8192 \
	--parallel 4 \
	--kv-unified \
	--flash-attn on
