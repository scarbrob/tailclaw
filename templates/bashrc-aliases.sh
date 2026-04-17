# OpenClaw aliases — append to ~/.bashrc
alias oc-restart="systemctl --user restart openclaw-gateway.service && echo 'Gateway restarted'"
alias oc-stop="systemctl --user stop openclaw-gateway.service && echo 'Gateway stopped'"
alias oc-status="systemctl --user status openclaw-gateway.service"
alias oc-logs="journalctl --user -u openclaw-gateway.service -f"
alias oc-config="nano ~/.openclaw/openclaw.json"
