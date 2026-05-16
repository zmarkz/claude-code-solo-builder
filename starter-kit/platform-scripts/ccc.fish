function ccc --description "Launch Claude Code and re-index knowledge-graph on exit"
    caffeinate -s claude --dangerously-skip-permissions $argv
    bash /YOUR_HOME/builds/_platform/scripts/kg-reindex.sh
end
